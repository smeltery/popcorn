{
  lib,
  stdenv,
  rust,
  makeRustPlatform,
  version,
  libiconv,
  python3,
}:
(makeRustPlatform {
  cargo = rust;
  rustc = rust;
}).buildRustPackage
  {
    pname = "popcorn";
    inherit version;

    src = builtins.path {
      path = ./.;
      name = "popcorn";
    };

    dontUseCargoParallelTests = true;
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = [ rust ];

    buildInputs = lib.optionals stdenv.isDarwin [
      libiconv
    ];

    nativeCheckInputs = [ python3 ];
  }
