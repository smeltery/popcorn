use anyhow::{bail, Result};
use serde::Deserialize;

use super::{Event, Header, Popcast};

#[derive(Deserialize)]
struct V1 {
    version: u8,
    width: u16,
    height: u16,
    stdout: Vec<V1OutputEvent>,
}

#[derive(Debug, Deserialize)]
struct V1OutputEvent {
    time: f64,
    data: String,
}

pub fn load(json: String) -> Result<Popcast<'static>> {
    let popcast: V1 = serde_json::from_str(&json)?;

    if popcast.version != 1 {
        bail!("unsupported popcast version")
    }

    let header = Header {
        term_cols: popcast.width,
        term_rows: popcast.height,
        ..Default::default()
    };

    let events = Box::new(popcast.stdout.into_iter().scan(0.0, |prev_time, event| {
        let time = *prev_time + event.time;
        *prev_time = time;

        Some(Ok(Event::Output {
            time,
            data: event.data,
        }))
    }));

    Ok(Popcast { header, events })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_relative_times_to_absolute() {
        let json = r#"{
            "version": 1,
            "width": 80,
            "height": 24,
            "stdout": [
                [0.5, "a"],
                [1.0, "b"],
                [1.5, "c"]
            ]
        }"#;

        let popcast = load(json.to_string()).unwrap();
        let events = popcast.events.collect::<Result<Vec<_>>>().unwrap();

        assert_eq!(
            events,
            vec![
                Event::Output {
                    time: 0.5,
                    data: "a".to_string()
                },
                Event::Output {
                    time: 1.5,
                    data: "b".to_string()
                },
                Event::Output {
                    time: 3.0,
                    data: "c".to_string()
                },
            ]
        );
    }

    #[test]
    fn zero_delays_preserve_previous_time() {
        let json = r#"{
            "version": 1,
            "width": 80,
            "height": 24,
            "stdout": [
                [0.0, "a"],
                [0.5, "b"],
                [0.0, "c"],
                [0.5, "d"]
            ]
        }"#;

        let popcast = load(json.to_string()).unwrap();
        let events = popcast.events.collect::<Result<Vec<_>>>().unwrap();

        assert_eq!(
            events,
            vec![
                Event::Output {
                    time: 0.0,
                    data: "a".to_string()
                },
                Event::Output {
                    time: 0.5,
                    data: "b".to_string()
                },
                Event::Output {
                    time: 0.5,
                    data: "c".to_string()
                },
                Event::Output {
                    time: 1.0,
                    data: "d".to_string()
                },
            ]
        );
    }
}
