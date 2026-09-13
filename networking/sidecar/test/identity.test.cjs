const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { identity } = require('../src/runtime.cjs')
test('identity persists across launches and rejects corruption', () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'tofufu-identity-'))
  const filename = path.join(directory, 'identity.key')
  try {
    const seed = identity(filename)
    assert.equal(seed.length, 32)
    assert.deepEqual(identity(filename), seed)
    if (process.platform !== 'win32') assert.equal(fs.statSync(filename).mode & 0o777, 0o600)
    fs.writeFileSync(filename, 'invalid')
    assert.throws(() => identity(filename), /Invalid saved identity/)
  } finally { fs.rmSync(directory, { recursive: true }) }
})
