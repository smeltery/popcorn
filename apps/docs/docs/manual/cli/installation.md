# Installation

popcorn CLI can be installed in the following ways:

- using a package manager on Linux, macOS, and FreeBSD - search for a package
  named `popcorn`,
- downloading a pre-built, static binary of the latest version from the
  [releases](https://github.com/dotbrains/popcorn/releases) page,
- using a [container image](#container-image),
- [building from source](#from-source).

Older versions of popcorn (2.x) can also be obtained as the [PyPI](#pypi)
package.

## Linux

### Arch Linux

```sh
sudo pacman -S popcorn
```

### Debian

```sh
sudo apt install popcorn
```

### Fedora

```sh
sudo dnf install popcorn
```

### Gentoo

```sh
sudo emerge -av popcorn
```

### NixOS / Nix

=== "nix-env"

    ```sh
    nix-env -i popcorn
    ```

=== "nix-shell"

    ```sh
    nix-shell -p popcorn
    ```

=== "NixOS configuration"

    ```nix title="/etc/nixos/configuration.nix"
    environment.systemPackages = [
      pkgs.popcorn
    ]
    ```

=== "home-manager"

    ```nix title="~/.config/home-manager/home.nix"
    home.packages = [
      pkgs.popcorn
    ]
    ```

### openSUSE

    sudo zypper install popcorn

### Ubuntu

=== "22.04 or newer"

    ```sh
    sudo apt install popcorn
    ```

=== "PPA"

    [David Adam (zanchey)](https://launchpad.net/~zanchey) maintains popcorn PPA.

    ```sh
    sudo apt-add-repository ppa:zanchey/popcorn
    sudo apt update
    sudo apt install popcorn
    ```

## macOS

=== "Homebrew"

    ```sh
    brew install popcorn
    ```

=== "MacPorts"

    ```sh
    sudo port selfupdate && sudo port install popcorn
    ```

=== "Nix"

    ```sh
    nix-env -i popcorn
    ```

## FreeBSD

=== "Ports"

    ```sh
    cd /usr/ports/textproc/py-popcorn && make install
    ```

=== "Packages"

    ```sh
    pkg install py39-popcorn
    ```

## OpenBSD

```sh
pkg_add popcorn
```

## PyPI

popcorn CLI 2.x is available on
[PyPI](https://pypi.python.org/pypi/popcorn) and can be installed with
`pipx`.

=== "pipx"

    If you have [pipx](https://pypa.github.io/pipx/) installed:

    ```sh
    pipx install popcorn
    ```

=== "pip"

      Alternatively use `pip` (Python 3 with `setuptools` required):

      ```sh
      python3 -m pip install popcorn
      ```

## Container image

popcorn OCI container image is based on [Ubuntu
22.04](https://releases.ubuntu.com/22.04/) and has the latest version of
popcorn recorder pre-installed.

Pull the container:

=== "podman"

    ```sh
    podman pull ghcr.io/popcorn/popcorn
    ```

=== "docker"

    ```sh
    docker pull ghcr.io/popcorn/popcorn
    ```

Container's entrypoint is set to `popcorn` binary therefore you can run the
container with arguments you would normally pass to `popcorn` command (run `popcorn --help` for commands and options).

When running the container it's essential to allocate a pseudo-TTY (`-t`) and
keep STDIN open (`-i`).

=== "podman"

    ```sh
    podman run --rm -it ghcr.io/popcorn/popcorn
    ```

=== "docker"

    ```sh
    docker run --rm -it ghcr.io/popcorn/popcorn
    ```

You can optionally bind-mount config directory (`-v`):

=== "podman"

    ```sh
    podman run --rm -it -v "$HOME/.config/popcorn:/root/.config/popcorn" ghcr.io/popcorn/popcorn
    ```

=== "docker"

    ```sh
    docker run --rm -it -v "$HOME/.config/popcorn:/root/.config/popcorn" ghcr.io/popcorn/popcorn
    ```

!!! note

    If you plan to upload your recordings to
    [popcorn.local](https://popcorn.local) then it's recommended to preserve
    popcorn config directory between runs, e.g. by bind-mounting it as shown
    above. This directory stores install ID, which links all recordings uploaded
    from a given system to your popcorn.local user account.

To be able to save the recordings locally bind-mount your working directory like this:

=== "podman"

    ```sh
    podman run --rm -it -v "$PWD:/root" --workdir=/data ghcr.io/popcorn/popcorn rec demo.pop
    ```

=== "docker"

    ```sh
    docker run --rm -it -v "$PWD:/root" --workdir=/data ghcr.io/popcorn/popcorn rec demo.pop
    ```

There's not much software installed in this image. In most cases you may want to
install extra programs before recording. One option is to derive a new image
from this one (start your custom Dockerfile with `FROM
ghcr.io/popcorn/popcorn`). Another option is to start the container with
`/bin/bash` as the entrypoint, install extra packages and then start recording
with `popcorn rec`:

=== "podman"

    ```console
    podman run --rm -it --entrypoint=/bin/bash ghcr.io/popcorn/popcorn
    root@6689517d99a1:~# apt install foobar
    root@6689517d99a1:~# popcorn rec demo.pop
    ```

=== "docker"

    ```console
    docker run --rm -it --entrypoint=/bin/bash ghcr.io/popcorn/popcorn
    root@6689517d99a1:~# apt install foobar
    root@6689517d99a1:~# popcorn rec demo.pop
    ```

With Docker, it's also possible to run the container as a non-root user, which
has security benefits. You can specify user and group id at runtime to give the
application permission similar to the calling user on your host.

```sh
docker run --rm -it \
    --env=POPCORN_CONFIG_HOME="/run/user/$(id -u)/.config/popcorn" \
    --user="$(id -u):$(id -g)" \
    --volume="${HOME}/.config/popcorn:/run/user/$(id -u)/.config/popcorn:rw" \
    --volume="${PWD}:/data:rw" \
    --workdir=/data \
    ghcr.io/popcorn/popcorn rec
```

!!! note

    Podman has [first class support for rootless
    operation](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md).

## From source

You can build latest development version of popcorn CLI by using Rust's
[cargo](https://github.com/rust-lang/cargo) package manager:

```bash
cargo install --locked --git https://github.com/dotbrains/popcorn
```

If you'd like to modify the code, then clone the [git
repository](https://github.com/dotbrains/popcorn.git) and run popcorn CLI
straight from the checkout:

```sh
git clone https://github.com/dotbrains/popcorn.git
cd popcorn
cargo run --release -- --help
```
