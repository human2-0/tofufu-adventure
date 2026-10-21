const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { createHash, randomBytes } = require('node:crypto')
const { options } = require('../src/runtime.cjs')
const { dispatch } = require('../src/dispatch.cjs')
const { PlaytestSwarm } = require('../src/swarm.cjs')
const DHT = require('hyperdht')
const { setTimeout: wait } = require('node:timers/promises')

test('battle discovery channels isolate public, private and adventure topics', async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'tofufu-battle-'))
  const identity = path.join(directory, 'identity.key')
  try {
    const publicOptions = await options({ identity, channel: 'tofufu-battle-v1/public' })
    const privateOptions = await options({ identity, channel: 'tofufu-battle-v1/' + 'a'.repeat(24) })
    const adventureOptions = await options({ identity })
    assert.deepEqual(publicOptions.topic, createHash('sha256').update('tofufu-battle-v1/public').digest())
    assert.notDeepEqual(publicOptions.topic, privateOptions.topic)
    assert.equal(adventureOptions.topic, undefined)
    await assert.rejects(options({ identity, channel: 'remote-supplied-code' }), /Invalid discovery/)
  } finally { fs.rmSync(directory, { recursive: true }) }
})

test('twenty direct encrypted battle peers exchange compact match traffic', { timeout: 60000 }, async () => {
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
  const topic = randomBytes(32)
  const peers = [], events = []
  try {
    for (let i = 0; i < 20; i++) {
      events[i] = []
      peers.push(new PlaytestSwarm('Bean ' + i, event => events[i].push(event), { dht: await localDht(addresses), topic }))
    }
    await Promise.all(peers.map(peer => peer.start()))
    const hostKey = peers[0].swarm.keyPair.publicKey.toString('hex')
    for (const peer of peers.slice(1)) peer.swarm.joinPeer(peers[0].swarm.keyPair.publicKey)
    const deadline = Date.now() + 35000
    while (peers[0].peers.size < 19 && Date.now() < deadline) await wait(50)
    assert.equal(peers[0].peers.size, 19, 'authority reaches all nineteen remote players')
    for (let seq = 1; seq <= 20; seq++) {
      for (let i = 1; i < 20; i++) {
        assert.equal(peers[i].send(hostKey, { kind: 'br_input', seq, inputs: [[i, [0.5, 0, 1, 0, 0]]] }), true)
      }
      const keys = peers.slice(1).map(peer => peer.swarm.keyPair.publicKey.toString('hex'))
      const data = { kind: 'br_state', seq, actors: Array.from({ length: 20 }, (_, slot) => [slot, 0, 0, 0, 0, 0, 0, 1, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]) }
      assert.equal(dispatch({ type: 'send_many', keys, data }, peers[0], event => events[0].push(event)), true)
      await wait(50)
    }
    const deliveryDeadline = Date.now() + 5000
    while (events[0].filter(event => event.type === 'packet' && event.data.kind === 'br_input').length < 380 && Date.now() < deliveryDeadline) await wait(20)
    assert.equal(events[0].filter(event => event.type === 'packet' && event.data.kind === 'br_input').length, 380)
    for (let i = 1; i < 20; i++) assert.equal(events[i].filter(event => event.type === 'packet' && event.data.kind === 'br_state').length, 20)
    assert.equal(events[0].filter(event => event.type === 'left').length, 0)
    // Migration needs survivor-to-survivor streams, independent of the old authority.
    for (let i = 1; i < 20; i++) {
      for (let j = i + 1; j < 20; j++) peers[i].swarm.joinPeer(peers[j].swarm.keyPair.publicKey)
    }
    const meshDeadline = Date.now() + 15000
    while (peers.slice(1).some(peer => peer.peers.size < 19) && Date.now() < meshDeadline) await wait(50)
    for (const peer of peers.slice(1)) assert.equal(peer.peers.size, 19, 'survivors have direct mesh links')
    await peers[0].close()
    const leftDeadline = Date.now() + 5000
    while (events.slice(1).some(rows => !rows.some(event => event.type === 'left' && event.key === hostKey)) && Date.now() < leftDeadline) await wait(20)
    for (let i = 1; i < 20; i++) assert.ok(events[i].some(event => event.type === 'left' && event.key === hostKey))
    const backupKey = peers[1].swarm.keyPair.publicKey.toString('hex')
    const checkpoint = JSON.stringify({ actors: Array.from({ length: 20 }, () => Array(23).fill(0.123456)), loot: Array.from({ length: 160 }, () => [1, 12.3456, 0, 23.4567, 1, 1]) })
    for (let i = 2; i < 20; i++) {
      const key = peers[i].swarm.keyPair.publicKey.toString('hex')
      assert.equal(peers[1].send(key, { kind: 'br_mproposal', term: 0, attempt: 0, blob: checkpoint }), true)
      assert.equal(peers[i].send(backupKey, { kind: 'br_mready', term: 0, attempt: 0, digest: 'shared-checkpoint' }), true)
    }
    const recoveryDeadline = Date.now() + 5000
    while (events[1].filter(event => event.type === 'packet' && event.data.kind === 'br_mready').length < 18 && Date.now() < recoveryDeadline) await wait(20)
    for (let i = 2; i < 20; i++) assert.ok(events[i].some(event => event.type === 'packet' && event.key === backupKey && event.data.blob === checkpoint))
    assert.equal(events[1].filter(event => event.type === 'packet' && event.data.kind === 'br_mready').length, 18, 'recovery traffic survives destruction of the first host')
  } finally {
    await Promise.allSettled(peers.map(peer => peer.close()))
    await bootstrap.destroy()
  }
})
