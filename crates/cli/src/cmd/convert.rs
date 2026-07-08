use std::fs;
use std::path::Path;
use std::time::Duration;

use anyhow::{bail, Result};

use crate::cli::{self, Format};
use crate::encoder::{
    self, EncoderExt, PopcastV2Encoder, PopcastV3Encoder, RawEncoder, TextEncoder,
};
use crate::output_writer::{self, OutputWriter};
use crate::popcast;
use crate::util;

impl cli::Convert {
    pub fn run(self) -> Result<()> {
        let input_path = self.get_input_path()?;
        let output_path = self.get_output_path();
        let cast = popcast::open_from_path(input_path.as_ref().as_ref())?;
        let mut encoder = self.get_encoder();
        let mut writer = self.open_output_writer(output_path)?;

        encoder.encode_to_writer(cast, writer.as_mut())?;
        writer.finish()?;

        Ok(())
    }

    fn get_encoder(&self) -> Box<dyn encoder::Encoder> {
        let format = self.output_format.unwrap_or_else(|| {
            let output = self.output.to_lowercase();
            let output = output.strip_suffix(".zst").unwrap_or(&output);

            if output.ends_with(".txt") {
                Format::Txt
            } else {
                Format::PopcastV3
            }
        });

        match format {
            Format::PopcastV3 => Box::new(PopcastV3Encoder::new(false)),
            Format::PopcastV2 => Box::new(PopcastV2Encoder::new(false, Duration::from_micros(0))),
            Format::Raw => Box::new(RawEncoder::new()),
            Format::Txt => Box::new(TextEncoder::new()),
        }
    }

    fn get_input_path(&self) -> Result<Box<dyn AsRef<Path>>> {
        if self.input == "-" {
            Ok(Box::new(Path::new("/dev/stdin")))
        } else {
            util::get_local_path(&self.input)
        }
    }

    fn get_output_path(&self) -> String {
        if self.output == "-" {
            "/dev/stdout".to_owned()
        } else {
            self.output.clone()
        }
    }

    fn open_output_writer(&self, path: String) -> Result<Box<dyn OutputWriter>> {
        let overwrite = self.get_mode(&path)?;

        let file = fs::OpenOptions::new()
            .write(true)
            .create(overwrite)
            .create_new(!overwrite)
            .truncate(overwrite)
            .open(&path)?;

        output_writer::new(file, self.output.to_lowercase().ends_with(".zst")).map_err(Into::into)
    }

    fn get_mode(&self, path: &str) -> Result<bool> {
        let mut overwrite = self.overwrite;
        let path = Path::new(path);

        if path.exists() {
            let metadata = fs::metadata(path)?;

            if metadata.len() == 0 {
                overwrite = true;
            }

            if !overwrite {
                bail!("file exists, use --overwrite option to overwrite the file");
            }
        }

        Ok(overwrite)
    }
}

#[cfg(test)]
mod tests {
    use std::fs::{self, File};
    use std::io::Read;

    use tempfile::tempdir;

    use super::*;

    #[test]
    fn zstd_round_trip() {
        let dir = tempdir().unwrap();
        let compressed_path = dir.path().join("recording.pop.zst");
        let decompressed_path = dir.path().join("recording.pop");

        convert("tests/casts/minimal-v3.pop", &compressed_path);

        let compressed = fs::read(&compressed_path).unwrap();
        assert!(compressed.starts_with(&[0x28, 0xb5, 0x2f, 0xfd]));

        let suffixless_path = dir.path().join("recording.bin");
        fs::rename(compressed_path, &suffixless_path).unwrap();
        convert(&suffixless_path, &decompressed_path);

        let cast = popcast::open_from_path(decompressed_path).unwrap();
        assert_eq!(cast.version, popcast::Version::Three);
        assert_eq!(cast.events.count(), 1);
    }

    #[test]
    fn infers_txt_format_before_zstd_suffix() {
        use zstd::stream::read::Decoder;

        let dir = tempdir().unwrap();
        let output_path = dir.path().join("recording.txt.zst");

        convert("tests/casts/minimal-v3.pop", &output_path);

        let mut decoder = Decoder::new(File::open(output_path).unwrap()).unwrap();
        let mut output = String::new();

        decoder.read_to_string(&mut output).unwrap();

        assert_eq!(output, "hello\n");
    }

    fn convert(input: impl AsRef<Path>, output: impl AsRef<Path>) {
        cli::Convert {
            input: input.as_ref().to_string_lossy().into_owned(),
            output: output.as_ref().to_string_lossy().into_owned(),
            output_format: None,
            overwrite: false,
        }
        .run()
        .unwrap();
    }
}
