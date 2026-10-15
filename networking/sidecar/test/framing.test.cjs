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
test('compressed gameplay frames preserve exact values with less wire traffic', () => {
  const stream = new PassThrough()
  const received = []
  attach(stream, value => received.push(value))
  const value = { type: 'packet', data: { actors: Array.from({ length: 4 }, () => ({ position: [21.123456789, 0.001, -2], health: 100, inventory: Array(80).fill({ id: 'edamame', count: 10 }) })) } }
  const raw = encode(value)
  const compressed = encode(value, true)
  assert.ok(compressed.length < raw.length / 4)
  for (let offset = 0; offset < compressed.length; offset += 7) stream.write(compressed.subarray(offset, offset + 7))
  assert.deepEqual(received, [value])
  stream.destroy()
})
test('small steady actor deltas also avoid repeated control-envelope overhead', () => {
  const stream = new PassThrough()
  const received = []
  attach(stream, value => received.push(value))
  const value = { type: 'packet', data: { type: 'snapshot_delta', epoch: 'e'.repeat(32), base: 120, sequence: 121, world_tick: false, patch: [1, { actors: [1, { ['b'.repeat(64)]: [1, { input_ack: [0, 120] }, []] }, []], sequence: [0, 121] }, []] } }
  const raw = encode(value)
  const packed = encode(value, true)
  assert.ok(raw.length >= 256 && raw.length < 512)
  assert.ok(packed.length < raw.length)
  stream.write(packed)
  assert.deepEqual(received, [value])
  stream.destroy()
})
test('compression cannot bypass decoded frame size or JSON validation', () => {
  const { deflateRawSync } = require('node:zlib')
  for (const payload of [Buffer.from('x'.repeat(70000)), Buffer.from('{bad'), Buffer.from('[]')]) {
    const stream = new PassThrough()
    let failed = false
    attach(stream, () => assert.fail('must not deliver'), () => { failed = true })
    stream.write(encode({ type: '__deflate', payload: deflateRawSync(payload).toString('base64') }))
    assert.equal(failed, true)
    stream.destroy()
  }
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
test('loopback admits four-player traffic while retaining its aggregate limit', () => {
  const stream = new PassThrough()
  let received = 0
  let failed = false
  attach(stream, () => { received++ }, () => { failed = true }, null, 600)
  for (let i = 0; i < 240; i++) stream.write(encode({ type: 'send' }))
  assert.equal(failed, false, 'three 60Hz guests plus chat/control traffic stay connected')
  assert.equal(received, 240)
  for (let i = 240; i < 601; i++) stream.write(encode({ type: 'send' }))
  assert.equal(failed, true, 'aggregate IPC flood is still bounded')
  stream.destroy()
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
