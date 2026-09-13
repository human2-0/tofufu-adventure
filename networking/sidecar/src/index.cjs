'use strict'
// Capability is delivered only over the inherited stdin pipe, never argv/files/logs.
const net = require('node:net')
const { attach } = require('./framing.cjs')
let input = ''
let transport
let bridge
let closing = false
const startup = setTimeout(() => process.exit(1), 10000)
async function close() {
  if (closing) return
  closing = true
  clearTimeout(startup)
  const deadline = setTimeout(() => process.exit(0), 1500)
  try { if (transport) await transport.close() } finally {
    bridge?.destroy()
    clearTimeout(deadline)
    process.exit(0)
  }
}
process.stdin.setEncoding('utf8')
process.stdin.on('data', chunk => {
  input += chunk
  if (input.length > 2048) return close()
  if (!input.includes('\n')) return
  process.stdin.removeAllListeners('data')
  try {
    const config = JSON.parse(input.trim())
    input = ''
    if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535 ||
        !/^[0-9a-f]{64}$/.test(config.token) || typeof config.name !== 'string' ||
        config.name.length < 1 || config.name.length > 24) return close()
    bridge = net.connect(config.port, '127.0.0.1')
    const emit = attach(bridge, message => {
      if (message.type === 'close') return close()
      if (message.type === 'send' && /^[0-9a-f]{64}$/.test(message.key) && message.data && typeof message.data === 'object') {
        if (!transport?.send(message.key, message.data)) emit({ type: 'left', key: message.key })
      } else close()
    }, close)
    bridge.on('close', close)
    bridge.on('connect', async () => {
      clearTimeout(startup)
      emit({ type: 'auth', token: config.token })
      config.token = ''
      try {
        const { PlaytestSwarm } = require('./swarm.cjs')
        const options = await require('./runtime.cjs').options(config)
        if (closing) { if (options.dht) await options.dht.destroy(); return }
        transport = new PlaytestSwarm(config.name, emit, options)
        transport.start().catch(() => emit({ type: 'error', message: 'Could not start Holepunch discovery. Retry when online.' }))
      } catch {
        emit({ type: 'error', message: 'Could not initialize Holepunch. Check the installed runtime and writable user profile.' })
      }
    })
  } catch { close() }
})
process.on('SIGTERM', close)
process.on('SIGINT', close)
process.stdin.on('end', close)
