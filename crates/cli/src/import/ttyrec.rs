use std::io::{self, BufRead};
use std::time::Duration;

use anyhow::{anyhow, bail, Result};

use crate::popcast::{Event, Header, Popcast, Version};
use crate::util::Utf8Decoder;

const HEADER_LEN: usize = 12;
const USECS_PER_SEC: i64 = 1_000_000;

pub fn open<'a, R: BufRead + Send + 'a>(reader: R) -> Result<Popcast<'a>> {
    Ok(Popcast {
        version: Version::Three,
        header: Header::default(),
        events: Box::new(TtyrecEvents::new(reader)),
    })
}

struct TtyrecEvents<R> {
    reader: R,
    decoder: Utf8Decoder,
    base_time: Option<i64>,
}

impl<R: BufRead> TtyrecEvents<R> {
    fn new(reader: R) -> Self {
        Self {
            reader,
            decoder: Utf8Decoder::new(),
            base_time: None,
        }
    }

    fn read_event(&mut self) -> Result<Option<Event>> {
        let Some(header) = read_header(&mut self.reader)? else {
            return Ok(None);
        };

        let frame_size = header.frame_size.try_into()?;
        let mut data = vec![0; frame_size];
        self.reader
            .read_exact(&mut data)
            .map_err(|e| anyhow!("truncated ttyrec frame: {e}"))?;

        let absolute_time = header.timestamp_micros()?;
        let base_time = *self.base_time.get_or_insert(absolute_time);
        let relative_time = absolute_time
            .checked_sub(base_time)
            .ok_or_else(|| anyhow!("ttyrec frame timestamp precedes first frame"))?;
        let time = Duration::from_micros(relative_time.try_into()?);

        Ok(Some(Event::output(time, self.decoder.feed(&data))))
    }
}

impl<R: BufRead> Iterator for TtyrecEvents<R> {
    type Item = Result<Event>;

    fn next(&mut self) -> Option<Self::Item> {
        self.read_event().transpose()
    }
}

#[derive(Debug, PartialEq)]
struct TtyrecHeader {
    sec: u32,
    usec: u32,
    frame_size: u32,
}

impl TtyrecHeader {
    fn parse(bytes: [u8; HEADER_LEN]) -> Self {
        Self {
            sec: u32::from_le_bytes(bytes[0..4].try_into().expect("sec header field")),
            usec: u32::from_le_bytes(bytes[4..8].try_into().expect("usec header field")),
            frame_size: u32::from_le_bytes(bytes[8..12].try_into().expect("size header field")),
        }
    }

    fn timestamp_micros(&self) -> Result<i64> {
        if self.usec >= 1_000_000 {
            bail!("invalid ttyrec timestamp: usec field must be less than 1000000");
        }

        let sec = i64::from(self.sec)
            .checked_mul(USECS_PER_SEC)
            .ok_or_else(|| anyhow!("ttyrec timestamp overflow"))?;

        sec.checked_add(i64::from(self.usec))
            .ok_or_else(|| anyhow!("ttyrec timestamp overflow"))
    }
}

fn read_header<R: BufRead>(reader: &mut R) -> Result<Option<TtyrecHeader>> {
    let mut header = [0; HEADER_LEN];
    let mut bytes_read = 0;

    while bytes_read < HEADER_LEN {
        match reader.read(&mut header[bytes_read..]) {
            Ok(0) if bytes_read == 0 => return Ok(None),
            Ok(0) => bail!("truncated ttyrec header"),
            Ok(n) => {
                bytes_read += n;
            }
            Err(e) if e.kind() == io::ErrorKind::Interrupted => {}
            Err(e) => return Err(e.into()),
        }
    }

    Ok(Some(TtyrecHeader::parse(header)))
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use anyhow::Result;

    use super::*;
    use crate::popcast::EventData;

    #[test]
    fn parses_header_as_little_endian() {
        let header = TtyrecHeader::parse([
            0x04, 0x03, 0x02, 0x01, 0x08, 0x07, 0x06, 0x05, 0x0c, 0x0b, 0x0a, 0x09,
        ]);

        assert_eq!(
            header,
            TtyrecHeader {
                sec: 0x01020304,
                usec: 0x05060708,
                frame_size: 0x090a0b0c,
            }
        );
    }

    #[test]
    fn converts_frames_to_relative_output_events() -> Result<()> {
        let input = ttyrec(&[(10, 500_000, b"hello ".as_slice()), (12, 250_000, b"world")]);
        let cast = open(Cursor::new(input))?;
        let events = cast.events.collect::<Result<Vec<_>>>()?;

        assert_eq!(events.len(), 2);
        assert_eq!(events[0].time, Duration::from_micros(0));
        assert!(matches!(&events[0].data, EventData::Output(data) if data == "hello "));
        assert_eq!(events[1].time, Duration::from_micros(1_750_000));
        assert!(matches!(&events[1].data, EventData::Output(data) if data == "world"));

        Ok(())
    }

    #[test]
    fn preserves_utf8_across_frame_boundaries() -> Result<()> {
        let input = ttyrec(&[(1, 0, &[0xc5]), (1, 1, &[0xbc])]);
        let cast = open(Cursor::new(input))?;
        let events = cast.events.collect::<Result<Vec<_>>>()?;

        assert!(matches!(&events[0].data, EventData::Output(data) if data.is_empty()));
        assert!(matches!(&events[1].data, EventData::Output(data) if data == "ż"));

        Ok(())
    }

    fn ttyrec(frames: &[(u32, u32, &[u8])]) -> Vec<u8> {
        let mut data = Vec::new();

        for (sec, usec, frame) in frames {
            data.extend(sec.to_le_bytes());
            data.extend(usec.to_le_bytes());
            data.extend((frame.len() as u32).to_le_bytes());
            data.extend(*frame);
        }

        data
    }
}
