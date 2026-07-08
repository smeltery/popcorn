# Support

Popcorn is maintained by dotbrains in the
[dotbrains/popcorn](https://github.com/dotbrains/popcorn) repository.

Use the repository for:

- bug reports with reproduction steps,
- feature requests and design discussion,
- documentation fixes,
- release and packaging issues,
- security coordination for the source packages.

## Security And Private Data

`.pop` recordings may contain command output, prompts, paths, hostnames,
captured input when input capture is enabled, environment metadata, and any
secret accidentally printed by the session.

Before sharing a recording:

- replay it locally and inspect the terminal output,
- avoid recording sessions that show passwords, tokens, private keys, or
  customer data,
- prefer a self-hosted Popcorn server for internal recordings,
- delete or rotate any secret that was captured.

## Licensing

First-party Popcorn packages are licensed under the PolyForm Shield License
1.0.0. See the repository
[LICENSE](https://github.com/dotbrains/popcorn/blob/main/LICENSE) for details.

Third-party dependencies and bundled fonts keep their own licenses and notices.
