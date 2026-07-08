# Configuration

You can configure popcorn CLI with a config file.

The most common use-case is setting the URL of a [self-hosted popcorn
server](../../server/self-hosting/index.md):

=== "CLI 3.0+"

    ```toml title="~/.config/popcorn/config.toml"
    [server]
    url = "https://popcorn.example.com"
    ```

=== "CLI 2.0+"

    ```ini title="~/.config/popcorn/config"
    [api]
    url = https://popcorn.example.com
    ```

Alternatively you can set it with environment variable in your shell config
file:

=== "CLI 3.0+"

    ```sh title="~/.bashrc"
    export POPCORN_SERVER_URL=https://popcorn.example.com
    ```

=== "CLI 2.0+"

    ```sh title="~/.bashrc"
    export POPCORN_API_URL=https://popcorn.example.com
    ```

There's more things you can configure. For the full list of options check out
the documentation for popcorn CLI version you use:

- [CLI 3.0+ configuration](v3.md)
- [CLI 2.0+ configuration](v2.md)

!!! tip

    During recording sessions, popcorn sets the `POPCORN_SESSION` environment
    variable to a unique session ID. This can be used to detect active recording
    sessions in your shell config file (`.bashrc`, `.zshrc`) in order to e.g. alter
    the prompt, play a sound, or change the background color of a terminal emulator
    window.

    For example:

    ```sh title=".bashrc"
    if [ -n "$POPCORN_SESSION" ]; then
      play "ding.wav"
    fi
    ```
