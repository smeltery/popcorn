use std::time::Duration;

use crate::popcast::{Event, Header, V2Encoder, V3Encoder};

pub struct PopcastV2Encoder {
    inner: V2Encoder,
    append: bool,
}

impl PopcastV2Encoder {
    pub fn new(append: bool, time_offset: Duration) -> Self {
        let inner = V2Encoder::new(time_offset);

        Self { inner, append }
    }
}

impl super::Encoder for PopcastV2Encoder {
    fn header(&mut self, header: &Header) -> Vec<u8> {
        if self.append {
            let size = (header.term_cols, header.term_rows);
            self.inner
                .event(&Event::resize(Duration::from_micros(0), size))
        } else {
            self.inner.header(header)
        }
    }

    fn event(&mut self, event: Event) -> Vec<u8> {
        self.inner.event(&event)
    }

    fn finish(&mut self) -> Vec<u8> {
        Vec::new()
    }
}

pub struct PopcastV3Encoder {
    inner: V3Encoder,
    append: bool,
}

impl PopcastV3Encoder {
    pub fn new(append: bool) -> Self {
        let inner = V3Encoder::new();

        Self { inner, append }
    }
}

impl super::Encoder for PopcastV3Encoder {
    fn header(&mut self, header: &Header) -> Vec<u8> {
        if self.append {
            let size = (header.term_cols, header.term_rows);
            self.inner
                .event(&Event::resize(Duration::from_micros(0), size))
        } else {
            self.inner.header(header)
        }
    }

    fn event(&mut self, event: Event) -> Vec<u8> {
        self.inner.event(&event)
    }

    fn finish(&mut self) -> Vec<u8> {
        Vec::new()
    }
}
