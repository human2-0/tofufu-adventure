'use strict'
const fs = require('node:fs')
const path = require('node:path')
const { randomBytes } = require('node:crypto')

function identity(filename) {
  if (typeof filename !== 'string' || !path.isAbsolute(filename)) throw new Error('Identity path required')
  fs.mkdirSync(path.dirname(filename), { recursive: true, mode: 0o700 })
  try { fs.writeFileSync(filename, randomBytes(32), { flag: 'wx', mode: 0o600 }) }
  catch (error) { if (error.code !== 'EEXIST') throw error }
  const seed = fs.readFileSync(filename)
  if (seed.length !== 32) throw new Error('Invalid saved identity')
  return seed
}
async function options(config) {
  const result = { seed: identity(config.identity) }
  if (process.env.TOFUFU_TEST_TOPIC) {
    result.topic = require('node:crypto').createHash('sha256').update('tofufu/verification/' + process.env.TOFUFU_TEST_TOPIC).digest()
  }
  // Explicit isolated integration-test target. Never supplied by a remote peer.
  const bootstrap = process.env.TOFUFU_TEST_DHT
  if (bootstrap) {
    if (!/^127\.0\.0\.1:\d{1,5}$/.test(bootstrap)) throw new Error('Test bootstrap must be loopback')
    const DHT = require('hyperdht')
    const probe = require('node:dgram').createSocket('udp4')
    await new Promise(resolve => probe.bind(0, '127.0.0.1', resolve))
    const port = probe.address().port
    await new Promise(resolve => probe.close(resolve))
    result.dht = DHT.bootstrapper(port, '127.0.0.1', { bootstrap: [bootstrap] })
    await result.dht.ready()
  }
  return result
}
module.exports = { identity, options }
