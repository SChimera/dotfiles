// Runs in Electron's main process before Slack creates any windows.
const { app } = require('electron');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const cssPath = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'matugen', 'slack.css');
const clients = new Set();
let css = '';
// Slack replaces console methods after startup; keep theme diagnostics visible
// in the launcher/systemd journal as well.
const log = message => fs.writeSync(2, '[matugen] ' + message + '\n');

function readCSS() {
  try {
    return fs.readFileSync(cssPath, 'utf8');
  } catch (error) {
    if (error.code !== 'ENOENT') log('Cannot read Slack CSS: ' + error.message);
    return '';
  }
}

app.on('web-contents-created', (_event, contents) => {
  let key;
  let pending = Promise.resolve();
  const apply = () => {
    pending = pending.then(async () => {
      if (contents.isDestroyed()) return;
      const url = contents.getURL();
      // Only style Slack documents, including its local desktop shell.
      let allowed = false;
      try {
        const parsed = new URL(url);
        allowed = ['app:', 'slack-webapp-dev:'].includes(parsed.protocol) ||
          (parsed.protocol === 'https:' && (parsed.hostname === 'slack.com' || parsed.hostname.endsWith('.slack.com')));
      } catch {}
      if (!allowed) {
        if (key) await contents.removeInsertedCSS(key);
        key = undefined;
        return;
      }
      const previous = key;
      // Author origin plus !important allows reliable removeInsertedCSS;
      // Electron 43 retained user-origin sheets even after removing their keys.
      const next = css ? await contents.insertCSS(css, { cssOrigin: 'author' }) : undefined;
      if (contents.isDestroyed()) return;
      key = next;
      if (previous) await contents.removeInsertedCSS(previous);
      if (next) log('Applied Slack CSS (' + css.length + ' bytes)');
    }).catch(error => {
      if (!contents.isDestroyed()) log('Slack CSS update failed: ' + error.message);
    });
  };
  // Replace our previous sheet on reload as well as on palette changes.
  contents.on('dom-ready', apply);
  clients.add(apply);
  contents.once('destroyed', () => clients.delete(apply));
});

css = readCSS();
const reload = () => {
  css = readCSS();
  log('Palette changed; updating ' + clients.size + ' Slack views');
  for (const apply of clients) apply();
};
process.on('SIGUSR2', reload);
// Matugen notifies this exact process after writing the palette. Register the
// start time too, so a stale PID file cannot signal an unrelated process.
app.whenReady().then(() => {
  const runtime = process.env.XDG_RUNTIME_DIR || '/run/user/' + process.getuid();
  const stat = fs.readFileSync('/proc/self/stat', 'utf8').split(') ').at(-1).split(' ');
  fs.writeFileSync(path.join(runtime, 'slack-matugen.json'), JSON.stringify({
    pid: process.pid,
    startTime: stat[19],
    exe: fs.readlinkSync('/proc/self/exe'),
  }), { mode: 0o600 });
});
