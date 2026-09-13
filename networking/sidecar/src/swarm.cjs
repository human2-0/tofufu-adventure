'use strict'
const Hyperswarm = require('hyperswarm')
const { Writable } = require('streamx')
const { createHash } = require('node:crypto')
const { attach } = require('./framing.cjs')
const BUILD = 'tofufu-coop-v2'
const TOPIC = createHash('sha256').update('tofufu-adventure/public-playtest/v2').digest()
class PlaytestSwarm {
  constructor(name, emit, options = {}) {
    this.name = name
    this.emit = emit
    this.peers = new Map()
    this.topic = options.topic || TOPIC
    this.swarm = new Hyperswarm({ ...options, maxPeers: 32, relayThrough: () => null })
    this.swarm.on('connection', socket => this.connection(socket))
    this.swarm.on('error', () => emit({ type: 'error', message: 'Discovery is unavailable. Check your connection and retry.' }))
  }
  async start() {
    await this.swarm.listen()
    this.emit({ type: 'ready', key: this.swarm.keyPair.publicKey.toString('hex'), name: this.name })
    this.discovery = this.swarm.join(this.topic, { client: true, server: true })
    await this.discovery.flushed()
    this.emit({ type: 'searching' })
    this.firstRefresh = setTimeout(() => this.refresh(), 1500)
    this.refreshTimer = setInterval(() => this.refresh(), 20000)
  }
  refresh() {
    if (this.discovery && !this.swarm.destroyed) this.discovery.refresh().catch(() => {})
  }
  connection(socket) {
    const key = socket.remotePublicKey.toString('hex')
    if (this.peers.has(key)) { socket.destroy(); return }
    let welcomed = false
    let lastSeen = Date.now()
    const send = attach(socket, message => {
      lastSeen = Date.now()
      if (!welcomed) {
        if (message.type !== 'hello' || message.version !== 2 || message.build !== BUILD ||
            typeof message.name !== 'string' || message.name.length < 1 || message.name.length > 24 || /[\x00-\x1f]/.test(message.name)) {
          socket.destroy(); return
        }
        welcomed = true
        this.peers.set(key, { send, socket })
        this.emit({ type: 'peer', key, name: message.name })
        return
      }
      if (message.type === 'ping') { send({ type: 'pong' }); return }
      if (message.type === 'pong') return
      if (message.type !== 'packet' || !message.data || typeof message.data !== 'object' || Array.isArray(message.data)) {
        socket.destroy(); return
      }
      this.emit({ type: 'packet', key, data: message.data })
    }, undefined, Writable.drained)
    send({ type: 'hello', version: 2, build: BUILD, name: this.name })
    const timer = setInterval(() => {
      if ((!welcomed && Date.now() - lastSeen > 8000) || Date.now() - lastSeen > 15000) socket.destroy()
      else if (welcomed) send({ type: 'ping' })
    }, 2000)
    socket.on('close', () => {
      clearInterval(timer)
      if (this.peers.get(key)?.socket === socket) {
        this.peers.delete(key)
        this.emit({ type: 'left', key })
      }
    })
  }
  send(key, data) { return this.peers.get(key)?.send({ type: 'packet', data }) || false }
  async close() {
    clearTimeout(this.firstRefresh)
    clearInterval(this.refreshTimer)
    await this.swarm.destroy()
  }
}
module.exports = { PlaytestSwarm, BUILD, TOPIC }
