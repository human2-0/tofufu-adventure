const { test } = require('node:test')
const assert = require('node:assert/strict')
const DHT = require('hyperdht')
const { PlaytestSwarm } = require('../src/swarm.cjs')
const { setTimeout: wait } = require('node:timers/promises')

test('two isolated local Holepunch peers discover, authenticate, exchange and shut down', { timeout: 35000 }, async () => {
  async function localDht(bootstrap = []) {
    const probe = require('node:dgram').createSocket('udp4')
    await new Promise(resolve => probe.bind(0, '127.0.0.1', resolve))
    const port = probe.address().port
    await new Promise(resolve => probe.close(resolve))
    const dht = DHT.bootstrapper(port, '127.0.0.1', { bootstrap })
    await dht.ready()
    return dht
  }
  const bootstrap = await localDht()
  const addresses = [`127.0.0.1:${bootstrap.address().port}`]
  const aEvents = [], bEvents = []
  const a = new PlaytestSwarm('Alpha', e => aEvents.push(e), { dht: await localDht(addresses) })
  const b = new PlaytestSwarm('Beta', e => bEvents.push(e), { dht: await localDht(addresses) })
  try {
    await Promise.all([a.start(), b.start()])
    const deadline = Date.now() + 18000
    while ((!a.peers.size || !b.peers.size) && Date.now() < deadline) await wait(50)
    assert.equal(a.peers.size, 1)
    assert.equal(b.peers.size, 1)
    const bKey = b.swarm.keyPair.publicKey.toString('hex')
    const aKey = a.swarm.keyPair.publicKey.toString('hex')
    assert.equal(aEvents.find(e => e.type === 'peer').key, bKey)
    assert.equal(a.swarm._maybeRelayConnection(true), null)
    assert.equal(a.send(bKey, { type: 'join', version: 1 }), true)
    while (!bEvents.some(e => e.type === 'packet') && Date.now() < deadline) await wait(20)
    assert.deepEqual(bEvents.find(e => e.type === 'packet'), { type: 'packet', key: aKey, data: { type: 'join', version: 1 } })
    // The old framer killed healthy streamx sockets after its 3-second write deadline.
    await wait(4500)
    assert.equal(aEvents.filter(e => e.type === 'left').length, 0, 'healthy host stream stays connected')
    assert.equal(bEvents.filter(e => e.type === 'left').length, 0, 'healthy guest stream stays connected')
    assert.equal(a.send(bKey, { type: 'still-connected' }), true)
    await wait(100)
    assert.ok(bEvents.some(e => e.type === 'packet' && e.data.type === 'still-connected'))
    await a.close()
    while (!bEvents.some(e => e.type === 'left') && Date.now() < deadline) await wait(20)
    assert.ok(bEvents.some(e => e.type === 'left'))
  } finally {
    await Promise.allSettled([a.close(), b.close()])
    await bootstrap.destroy()
  }
})
