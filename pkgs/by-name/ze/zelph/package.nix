{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  mimalloc,
  janet,
  ninja,
  meson,
  unordered_dense,
  bzip2,
  capnproto,
  doctest,
  runCommand,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "zelph";
  version = "1.0.1";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "acrion";
    repo = "zelph";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1bRgcYp9D9roNcerKpAc0yHCW9CmwFtI+rRxQxN+l7k=";
  };

  buildInputs = [
    mimalloc
    unordered_dense
    #bzip2
    capnproto
    doctest
  ];

  nativeBuildInputs = [
    cmake
    ninja
    meson
    pkg-config
  ];

  postUnpack = ''
    # Copy the read-only dependency source into a writable build directory
    cp -r --no-preserve=mode,ownership "${janet.src}" ./dep-source
    chmod -R u+w ./dep-source
  '';

  preConfigure = ''
    cmakeFlagsArray+=(
      "-DFETCHCONTENT_SOURCE_DIR_JANET=$NIX_BUILD_TOP/dep-source"
    )
  '';

  cmakeFlags =
    let
      bzip2Unpacked = runCommand "bzip2-${bzip2.version}-source" { } ''
        mkdir -p $out
        tar -xzf ${bzip2.src} -C $out --strip-components=1;
      '';
    in
    [
      "-DFETCHCONTENT_SOURCE_DIR_MIMALLOC=${mimalloc.src}"
      "-DFETCHCONTENT_SOURCE_DIR_UNORDERED_DENSE=${unordered_dense.src}"
      "-DFETCHCONTENT_SOURCE_DIR_BZIP2=${bzip2Unpacked}"
      "-DFETCHCONTENT_SOURCE_DIR_CAPNPROTO=${capnproto.src}"
      "-DFETCHCONTENT_SOURCE_DIR_DOCTEST=${doctest.src}"
      "-DCMAKE_VERBOSE_MAKEFILE=ON"
    ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A semantic network and reasoning engine in which rules, facts and numbers are nodes of one graph, so a statement is itself a node. Importing the statements of the 1.7 TB Wikidata dump builds 983 million nodes on a single machine, and reasoning over them has surfaced thousands of consistency violations in the Wikidata ontology";
    homepage = "https://github.com/acrion/zelph";
    changelog = "https://github.com/acrion/zelph/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "zelph";
    platforms = lib.platforms.all;
  };
})
