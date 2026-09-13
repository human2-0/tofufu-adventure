'use strict'
const MAX_FRAME = 65536
const MAX_QUEUE = 262144
function encode(value) {
  const payload = Buffer.from(JSON.stringify(value))
  if (!payload.length || payload.length > MAX_FRAME) throw new Error('Invalid frame size')
  const header = Buffer.alloc(4)
  header.writeUInt32BE(payload.length)
  return Buffer.concat([header, payload])
}
function attach(stream, onMessage, onFailure = () => {}, drained = null) {
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
        if (++frames > 180) return fail()
        const value = JSON.parse(pending.subarray(4, size + 4).toString('utf8'))
        pending = pending.subarray(size + 4)
        if (!value || typeof value !== 'object' || Array.isArray(value)) return fail()
        onMessage(value)
      }
    } catch { fail() }
  })
  return value => {
    if (closed || stream.destroyed) return false
    try {
      const frame = encode(value)
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
