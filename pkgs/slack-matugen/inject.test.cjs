const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const fs = require('node:fs');
const vm = require('node:vm');
const test = require('node:test');

const flush = () => new Promise(resolve => setImmediate(resolve));
function setup() {
  const app = new EventEmitter();
  app.whenReady = () => Promise.resolve();
  let css = 'body { color: red; }';
  let watcher;
  let registered = false;
  vm.runInNewContext(fs.readFileSync(__dirname + '/inject.cjs', 'utf8'), {
    require(name) {
      if (name === 'electron') return { app };
      if (name === 'node:fs') return {
        readFileSync: name => { if (name === '/proc/self/stat') return '1 (slack) ' + Array(20).fill('123').join(' '); if (css === null) throw Object.assign(new Error(), { code: 'ENOENT' }); return css; },
        writeSync: () => {},
        writeFileSync: () => { registered = true; },
        readlinkSync: () => '/nix/store/test-slack/lib/slack/slack',
      };
      return require(name);
    },
    process: { env: {}, pid: 1, getuid: () => 1000, on: (_signal, callback) => { watcher = callback; } }, console, URL,
  });
  const contents = new EventEmitter();
  let url = 'https://app.slack.com/client/test';
  let destroyed = false;
  const inserted = [], removed = [];
  Object.assign(contents, {
    getURL: () => url,
    isDestroyed: () => destroyed,
    insertCSS: async (value, opts) => { assert.equal(opts.cssOrigin, 'author'); inserted.push(value); return String(inserted.length); },
    removeInsertedCSS: async key => { removed.push(key); },
  });
  app.emit('web-contents-created', {}, contents);
  return { app, contents, inserted, removed,
    setURL(value) { url = value; },
    update(value) { css = value; watcher(); },
    destroy() { destroyed = true; contents.emit('destroyed'); },
    registered: () => registered,
  };
}

test('loads, replaces, removes, and reapplies CSS after navigation', async () => {
  const s = setup();
  s.contents.emit('dom-ready'); await flush();
  assert.equal(s.inserted.length, 1);
  s.update('body { color: blue; }'); await flush();
  assert.deepEqual(s.removed, ['1']);
  assert.equal(s.inserted.at(-1), 'body { color: blue; }');
  s.update('body { color: blue; }'); await flush();
  assert.equal(s.inserted.length, 3);
  s.contents.emit('did-navigate');
  s.contents.emit('dom-ready'); await flush();
  assert.equal(s.inserted.length, 4);
  assert.deepEqual(s.removed, ['1', '2', '3']);
  s.update(null); await flush();
  assert.deepEqual(s.removed, ['1', '2', '3', '4']);
  s.update('body { color: green; }'); await flush();
  assert.equal(s.inserted.length, 5);
  s.destroy(); s.update('body {}'); await flush();
  assert.equal(s.inserted.length, 5);
  assert.equal(s.registered(), true);
});

test('does not inject into external authentication pages', async () => {
  const s = setup();
  for (const url of ['https://example.com', 'https://slack.com.example.com', 'devtools://devtools/']) {
    s.setURL(url); s.contents.emit('dom-ready'); await flush();
  }
  assert.equal(s.inserted.length, 0);
  s.setURL('app://index.html'); s.contents.emit('dom-ready'); await flush();
  assert.equal(s.inserted.length, 1);
  s.setURL('https://example.com'); s.contents.emit('dom-ready'); await flush();
  assert.deepEqual(s.removed, ['1']);
});
