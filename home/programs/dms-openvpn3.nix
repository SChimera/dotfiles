{ inputs, pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.dbus-python ]);
  plugin = pkgs.stdenvNoCC.mkDerivation {
    pname = "dms-openvpn3";
    version = (builtins.fromJSON (builtins.readFile "${inputs.dms-openvpn3}/plugin.json")).version;
    src = inputs.dms-openvpn3;

    # The plugin invokes Python from QML, so patch both the service and its
    # startup check to use an interpreter that includes the D-Bus bindings.
    # This leaves the shared development Python environment unchanged.
    postPatch = ''
      substituteInPlace OpenVpn3Service.qml StartupCheck.qml \
        --replace-fail '"python3"' '"${python}/bin/python3"'
    '';

    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r *.qml qmldir plugin.json helper "$out/"
      runHook postInstall
    '';
  };
in
{
  # Install the plugin; DMS Settings owns its toggle and DankBar placement.
  programs.dank-material-shell.plugins.openvpn3 = {
    enable = true;
    src = plugin;
  };
}
