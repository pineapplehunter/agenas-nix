{
  lib,
  rustPlatform,
  fetchFromGitea,
  pkg-config,
  protobuf,
  openssl,
  cacert,
}:

rustPlatform.buildRustPackage rec {
  pname = "garage";
  version = "1.2.0";

  src = fetchFromGitea {
    domain = "git.deuxfleurs.fr";
    owner = "Deuxfleurs";
    repo = "garage";
    rev = "v${version}";
    hash = "sha256-JoOwCbChSL7mjegnLHOH2Abfmsnw9BwNsjFj7nqBN6o=";
  };

  patches = [ ./current_thread.patch ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-vcvD0Fn/etnAuXrM3+rj16cqpEmW2nzRmrjXsftKTFE=";

  nativeBuildInputs = [
    pkg-config
    protobuf
  ];

  buildInputs = [ openssl ];

  checkInputs = [ cacert ];

  postPatch = ''
    # Starting in 0.9.x series, Garage is using mold in local development
    # and this leaks in this packaging, we remove it to use the default linker.
    rm .cargo/config.toml || true
  '';

  env.OPENSSL_NO_VENDOR = "true";

  disabledTests = [
    # Upstream told us this test is flakey.
    "k2v::poll::test_poll_item"
  ];

  meta = {
    description = "";
    homepage = "https://git.deuxfleurs.fr/Deuxfleurs/garage";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ pineapplehunter ];
    mainProgram = "garage";
  };
}
