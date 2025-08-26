{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  app2unit,
  cava,
  networkmanager,
  lm_sensors,
  grim,
  swappy,
  wl-clipboard,
  libqalculate,
  inotify-tools,
  bluez,
  bash,
  hyprland,
  coreutils,
  findutils,
  file,
  material-symbols,
  rubik,
  nerd-fonts,
  gcc,
  qt6,
  quickshell,
  aubio,
  pipewire,
  wayland,
  wayland-protocols,
  wayland-scanner,
  xkeyboard-config,
  cmake,
  ninja,
  caelestia-cli,
  withCli ? false,
  extraRuntimeDeps ? [],
}: let
  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      cava
      networkmanager
      lm_sensors
      grim
      swappy
      wl-clipboard
      libqalculate
      inotify-tools
      bluez
      bash
      hyprland
      coreutils
      findutils
      file
    ]
    ++ extraRuntimeDeps
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.caskaydia-cove];
  };

  beatDetector = stdenv.mkDerivation {
    pname = "beat-detector";
    version = "1.0";

    src = ./../assets/cpp;

    nativeBuildInputs = [gcc];
    buildInputs = [aubio pipewire];

    buildPhase = ''
      g++ -std=c++17 -Wall -Wextra \
      	-I${pipewire.dev}/include/pipewire-0.3 \
      	-I${pipewire.dev}/include/spa-0.2 \
      	-I${aubio}/include/aubio \
      	beat-detector.cpp \
      	-o beat_detector \
      	-lpipewire-0.3 -laubio
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -Dm755 beat_detector $out/bin/beat_detector
    '';
  };

  idleInhibitor = stdenv.mkDerivation {
    pname = "wayland-idle-inhibitor";
    version = "1.0";

    src = ./../assets/cpp;

    nativeBuildInputs = [gcc wayland-scanner wayland-protocols];
    buildInputs = [wayland];

    buildPhase = ''
      wayland-scanner client-header < ${wayland-protocols}/share/wayland-protocols/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml > idle-inhibitor.h
      wayland-scanner private-code < ${wayland-protocols}/share/wayland-protocols/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml > idle-inhibitor.c

      gcc -o idle-inhibitor.o -c idle-inhibitor.c
      g++ -o inhibit_idle idle-inhibitor.cpp idle-inhibitor.o -lwayland-client
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -Dm755 inhibit_idle $out/bin/inhibit_idle
    '';
  };

  plugin = stdenv.mkDerivation {
    pname = "caelestia-qt-plugin";
    version = "0.0.1";

    src = ./../plugin;

    dontWrapQtApps = true;
    nativeBuildInputs = [cmake ninja];
    buildInputs = [qt6.qtbase qt6.qtdeclarative];

    cmakeBuildType = "Release";
    cmakeFlags = [
      (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      (lib.cmakeFeature "GIT_REVISION" rev)
    ];
  };
in
  stdenv.mkDerivation {
    pname = "caelestia-shell";
    version = "${rev}";
    src = ./..;

    nativeBuildInputs = [gcc makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell plugin beatDetector idleInhibitor xkeyboard-config qt6.qtbase];
    propagatedBuildInputs = runtimeDeps;

    patchPhase = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
    '';

    installPhase = ''
      mkdir -p $out/share/caelestia-shell
      cp -r ./* $out/share/caelestia-shell

      makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set CAELESTIA_BD_PATH ${beatDetector}/bin/beat_detector \
      	--set CAELESTIA_II_PATH ${idleInhibitor}/bin/inhibit_idle \
        --set CAELESTIA_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
      	--add-flags "-p $out/share/caelestia-shell"

      	ln -sf ${beatDetector}/bin/beat_detector $out/bin
      	ln -sf ${idleInhibitor}/bin/inhibit_idle $out/bin
    '';

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }
