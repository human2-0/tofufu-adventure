const { test } = require('node:test')
const assert = require('node:assert/strict')
const { PassThrough } = require('node:stream')
const { attach, encode } = require('../src/framing.cjs')

test('frames survive fragmentation and coalescing', () => {
  const stream = new PassThrough()
  const messages = []
  attach(stream, m => messages.push(m))
  const bytes = Buffer.concat([encode({ type: 'one' }), encode({ type: 'two' })])
  for (const byte of bytes) stream.write(Buffer.from([byte]))
  assert.deepEqual(messages, [{ type: 'one' }, { type: 'two' }])
  stream.end()
})
for (const [name, data] of [
  ['zero length', Buffer.alloc(4)],
  ['oversized', Buffer.from([0, 1, 0, 1])],
  ['invalid JSON', Buffer.from([0, 0, 0, 1, 123])],
  ['array payload', encode([])]
]) test(`reject ${name}`, () => {
  const stream = new PassThrough()
  let failed = false
  attach(stream, () => assert.fail('should not deliver'), () => { failed = true })
  stream.write(data)
  assert.equal(failed, true)
})
test('rate bounded', () => {
  const stream = new PassThrough()
  let failed = false
  attach(stream, () => {}, () => { failed = true })
  for (let i = 0; i < 181; i++) stream.write(encode({ type: 'ping' }))
  assert.equal(failed, true)
})
test('slow writable cannot grow an unbounded queue', () => {
  const { Duplex } = require('node:stream')
  const stream = new Duplex({ read() {}, write(_chunk, _encoding, _callback) {} })
  let failed = false
  const send = attach(stream, () => {}, () => { failed = true })
  for (let i = 0; i < 6; i++) send({ payload: 'x'.repeat(50000) })
  assert.equal(failed, true)
  stream.destroy()
})

test('streamx completed writes release byte accounting and the stall deadline', { timeout: 6000 }, async () => {
  const { Writable } = require('streamx')
  const { setTimeout: wait } = require('node:timers/promises')
  let written = 0
  const stream = new Writable({ write(data, callback) { written += data.length; callback(null) } })
  let failed = false
  const send = attach(stream, () => {}, () => { failed = true }, Writable.drained)
  try {
    for (let i = 0; i < 8; i++) {
      assert.equal(send({ payload: 'x'.repeat(50000) }), true)
      await Writable.drained(stream)
    }
    assert.ok(written > 262144, 'successful writes can exceed the queue cap over time')
    await wait(3200)
    assert.equal(failed, false)
    assert.equal(stream.destroyed, false)
  } finally { stream.destroy() }
})

test('streamx truly stalled writes still expire', { timeout: 6000 }, async () => {
  const { Writable } = require('streamx')
  const { setTimeout: wait } = require('node:timers/promises')
  let release
  const stream = new Writable({ write(_data, callback) { release = callback } })
  let failed = false
  const send = attach(stream, () => {}, () => { failed = true }, Writable.drained)
  try {
    send({ type: 'stalled' })
    await wait(3200)
    assert.equal(failed, true)
  } finally { release?.(null); stream.destroy() }
})
