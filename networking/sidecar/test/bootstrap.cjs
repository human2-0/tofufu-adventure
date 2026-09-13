'use strict'
const DHT = require('hyperdht')
;(async () => {
  const probe = require('node:dgram').createSocket('udp4')
  await new Promise(resolve => probe.bind(0, '127.0.0.1', resolve))
  const port = probe.address().port
  await new Promise(resolve => probe.close(resolve))
  const dht = DHT.bootstrapper(port, '127.0.0.1')
  await dht.ready()
  console.log(JSON.stringify({ address: `127.0.0.1:${port}` }))
  const close = async () => { await dht.destroy(); process.exit(0) }
  process.on('SIGTERM', close)
  process.on('SIGINT', close)
})().catch(error => { console.error(error.message); process.exit(1) })
