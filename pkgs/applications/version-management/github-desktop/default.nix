{ stdenvNoCC
, lib
, fetchurl
, autoPatchelfHook
, wrapGAppsHook
, makeWrapper
, gnome
, libsecret
, git
, curl
, nss
, nspr
, xorg
, libdrm
, alsa-lib
, cups
, mesa
, systemd
, openssl
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "github-desktop";
  version = "3.3.10";
  rcversion = "1";
  arch = "amd64";

  src = fetchurl {
    url = "https://github.com/shiftkey/desktop/releases/download/release-${finalAttrs.version}-linux${finalAttrs.rcversion}/GitHubDesktop-linux-${finalAttrs.arch}-${finalAttrs.version}-linux${finalAttrs.rcversion}.deb";
    hash = "sha256-zzq6p/DAQmgSw4KAUYqtrQKkIPksLzkUQjGzwO26WgQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    (wrapGAppsHook.override { inherit makeWrapper; })
  ];

  buildInputs = [
    gnome.gnome-keyring
    xorg.libXdamage
    xorg.libX11
    libsecret
    git
    curl
    nss
    nspr
    libdrm
    alsa-lib
    cups
    mesa
    openssl
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir -p $TMP/${finalAttrs.pname} $out/{opt,bin}
    cp $src $TMP/${finalAttrs.pname}.deb
    ar vx ${finalAttrs.pname}.deb
    tar --no-overwrite-dir -xvf data.tar.xz -C $TMP/${finalAttrs.pname}/
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    cp -R $TMP/${finalAttrs.pname}/usr/share $out/
    cp -R $TMP/${finalAttrs.pname}/usr/lib/${finalAttrs.pname}/* $out/opt/
    ln -sf $out/opt/${finalAttrs.pname} $out/bin/${finalAttrs.pname}
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland}}"
    )
  '';

  runtimeDependencies = [
    (lib.getLib systemd)
  ];

  meta = {
    description = "GUI for managing Git and GitHub.";
    homepage = "https://desktop.github.com/";
    license = lib.licenses.mit;
    mainProgram = "github-desktop";
    maintainers = with lib.maintainers; [ dan4ik605743 ];
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
