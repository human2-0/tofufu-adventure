'use strict'
const { deflateRawSync, inflateRawSync } = require('node:zlib')
const MAX_FRAME = 65536
const MAX_QUEUE = 262144
function encode(value, compressed = false) {
  let payload = Buffer.from(JSON.stringify(value))
  if (!payload.length || payload.length > MAX_FRAME) throw new Error('Invalid frame size')
  if (compressed && payload.length >= 256) {
    const packed = deflateRawSync(payload, { level: 6 })
    const envelope = Buffer.from(JSON.stringify({ type: '__deflate', payload: packed.toString('base64') }))
    if (envelope.length < payload.length) payload = envelope
  }
  const header = Buffer.alloc(4)
  header.writeUInt32BE(payload.length)
  return Buffer.concat([header, payload])
}
function decode(payload) {
  let value = JSON.parse(payload.toString('utf8'))
  if (value?.type === '__deflate') {
    if (Object.keys(value).length !== 2 || typeof value.payload !== 'string' ||
        !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value.payload)) {
      throw new Error('Invalid compressed frame')
    }
    const unpacked = inflateRawSync(Buffer.from(value.payload, 'base64'), { maxOutputLength: MAX_FRAME })
    value = JSON.parse(unpacked.toString('utf8'))
  }
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid message')
  return value
}
function attach(stream, onMessage, onFailure = () => {}, drained = null, maxFrames = 180, compressed = false) {
  let pending = Buffer.alloc(0)
  let frames = 0
  let epoch = Date.now()
  let closed = false
  let queuedBytes = 0
  let stalledTimer = null
  const fail = () => {
    if (closed) return
    closed = true
    clearTimeout(stalledTimer)
    onFailure()
    stream.destroy()
  }
  stream.on('error', fail)
  stream.on('close', () => { closed = true; clearTimeout(stalledTimer) })
  stream.on('data', chunk => {
    if (closed) return
    if (pending.length + chunk.length > MAX_QUEUE) return fail()
    pending = Buffer.concat([pending, chunk])
    try {
      while (pending.length >= 4) {
        const size = pending.readUInt32BE(0)
        if (!size || size > MAX_FRAME) return fail()
        if (pending.length < size + 4) break
        if (Date.now() - epoch >= 1000) { epoch = Date.now(); frames = 0 }
        if (++frames > maxFrames) return fail()
        const value = decode(pending.subarray(4, size + 4))
        pending = pending.subarray(size + 4)
        onMessage(value)
      }
    } catch { fail() }
  })
  return value => {
    if (closed || stream.destroyed) return false
    try {
      const frame = encode(value, compressed)
      if (queuedBytes + frame.length > MAX_QUEUE) { fail(); return false }
      if (queuedBytes === 0) stalledTimer = setTimeout(fail, 3000)
      queuedBytes += frame.length
      const complete = () => {
        queuedBytes -= frame.length
        if (queuedBytes === 0) clearTimeout(stalledTimer)
      }
      if (drained) {
        // streamx write(data) ignores Node's optional write callback.
        stream.write(frame)
        drained(stream).then(ok => { if (ok) complete(); else fail() }, fail)
      } else {
        stream.write(frame, error => { if (error) fail(); else complete() })
      }
      return true
    } catch { fail(); return false }
  }
}
module.exports = { encode, attach, MAX_FRAME }
