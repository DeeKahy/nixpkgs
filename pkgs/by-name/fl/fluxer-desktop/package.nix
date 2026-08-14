{
  lib,
  stdenv,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  electron_41,
  python3,
  autoPatchelfHook,
  libx11,
  libxrandr,
  libxtst,
  libxt,
}:

let
  pnpm = pnpm_10;
  electron = electron_41;
  appId = "app.fluxer.Fluxer";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "fluxer-desktop";
  version = "0-unstable-2026-08-14";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "fluxerapp";
    repo = "fluxer";
    rev = "3dab64d040d37c0629ca584cbbdf1cf3ee8350c6";
    hash = "sha256-l7NYNRUZsXMmpxpV42ONEym5LLuDfNKINOZzpfUrWLg=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    pnpmWorkspaces = [ "fluxer_desktop" ];
    hash = "sha256-PPlwVWt9nPNQ3ar+TpuN4MGCpDAir3JJxvNcxWFt/wo=";
  };

  pnpmWorkspaces = [ "fluxer_desktop" ];

  nativeBuildInputs = [
    makeBinaryWrapper
    nodejs
    pnpmConfigHook
    pnpm
    python3
    autoPatchelfHook
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    libx11
    libxrandr
    libxtst
    libxt
  ];

  env.NODE_ENV = "production";

  buildPhase = ''
    runHook preBuild

    cd fluxer_desktop

    # ensureBuildChannelFile() shells out to `cargo run` against tools/ci,
    # which would require vendoring the workspace's 581 crates.
    substituteInPlace scripts/build.mjs \
      --replace-fail 'ensureBuildChannelFile();' '// ensureBuildChannelFile();'

    export FLUXER_SKIP_NATIVE=true
    export RELEASE_CHANNEL=stable
    pnpm build

    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    export npm_config_nodedir=${electron.headers}
    pnpm exec electron-builder \
      --config electron-builder.config.cjs \
      --dir \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version} \
      -c.extraMetadata.name=${appId} \
      -c.extraMetadata.version=${finalAttrs.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/{applications,metainfo,${appId}} $out/bin
    cp -r ./dist-electron/linux-unpacked/resources/* $out/share/${appId}

    makeWrapper ${lib.getExe electron} $out/bin/fluxer-desktop \
      --add-flags "$out/share/${appId}/app.asar"

    substitute {packaging/linux,$out/share/applications}/${appId}.desktop \
      --replace-fail "Exec=${appId}" "Exec=$out/bin/fluxer-desktop"

    install -Dm444 packaging/linux/${appId}.metainfo.xml $out/share/metainfo/
    install -Dm444 packaging/linux/${appId}.svg \
      $out/share/icons/hicolor/scalable/apps/${appId}.svg

    runHook postInstall
  '';

  meta = {
    description = "Fluxer desktop client, built from source";
    homepage = "https://fluxer.app/";
    mainProgram = "fluxer-desktop";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
