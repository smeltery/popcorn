use std::collections::HashMap;
use std::time::Duration;

use anyhow::{bail, Result};
use serde::Deserialize;

use super::{Event, Header, Popcast, Version};
use crate::popcast::util::deserialize_time;

#[derive(Debug, Deserialize)]
struct V1 {
    version: u8,
    width: u16,
    height: u16,
    command: Option<String>,
    title: Option<String>,
    env: Option<HashMap<String, Option<String>>>,
    stdout: Vec<V1OutputEvent>,
}

#[derive(Debug, Deserialize)]
struct V1OutputEvent {
    #[serde(deserialize_with = "deserialize_time")]
    time: Duration,
    data: String,
}

pub fn load(json: String) -> Result<Popcast<'static>> {
    let popcast: V1 = serde_json::from_str(&json)?;

    if popcast.version != 1 {
        bail!("unsupported popcast version")
    }

    let term_type = popcast
        .env
        .as_ref()
        .map(|env| env.get("TERM"))
        .unwrap_or_default()
        .cloned()
        .unwrap_or_default();

    let env = popcast.env.map(|env| {
        env.into_iter()
            .filter_map(|(k, v)| v.map(|v| (k, v)))
            .collect()
    });

    let header = Header {
        term_cols: popcast.width,
        term_rows: popcast.height,
        term_type,
        term_version: None,
        term_theme: None,
        timestamp: None,
        idle_time_limit: None,
        command: popcast.command.clone(),
        title: popcast.title.clone(),
        env,
    };

    let events = Box::new(popcast.stdout.into_iter().scan(
        Duration::from_micros(0),
        |prev_time, event| {
            let time = *prev_time + event.time;
            *prev_time = time;

            Some(Ok(Event::output(time, event.data)))
        },
    ));

    Ok(Popcast {
        version: Version::One,
        header,
        events,
    })
}
