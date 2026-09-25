{ slack, asar, nodejs }:
slack.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ asar nodejs ];
  postInstall = (old.postInstall or "") + ''
    resources="$out/lib/slack/resources"
    asar extract "$resources/app.asar" slack-app
    cp ${./inject.cjs} slack-app/matugen.cjs
    # Prepend to the existing entry point, preserving Slack's package metadata.
    node - slack-app <<'JS'
    const fs = require('node:fs');
    const path = require('node:path');
    const root = process.argv[2];
    const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
    const entry = path.join(root, pkg.main);
    const relative = './' + path.relative(path.dirname(entry), path.join(root, 'matugen.cjs'));
    fs.writeFileSync(entry, 'require(' + JSON.stringify(relative) + ');\n' + fs.readFileSync(entry, 'utf8'));
    JS
    # Native modules must remain outside the archive for dlopen.
    asar pack slack-app "$resources/app.asar" --unpack-dir node_modules
  '';
})
