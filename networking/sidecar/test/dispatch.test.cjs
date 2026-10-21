const { test } = require('node:test')
const assert = require('node:assert/strict')
const { dispatch } = require('../src/dispatch.cjs')
const keys = Array.from({ length: 20 }, (_, i) => (i + 1).toString(16).padStart(64, '0'))

test('bounded local fanout preserves destinations, payload and endpoint failures', () => {
  const delivered = [], events = []
  const data = { seq: 7, actors: [[1, 2, 3]], label: 'Tofufu · żółć' }
  const transport = { send: (key, packet) => { delivered.push([key, packet]); return key !== keys[3] } }
  assert.equal(dispatch({ type: 'send_many', keys, data }, transport, event => events.push(event)), true)
  assert.deepEqual(delivered.map(row => row[0]), keys)
  assert.ok(delivered.every(row => row[1] === data))
  assert.deepEqual(events, [{ type: 'left', key: keys[3] }])
  delivered.length = 0
  assert.equal(dispatch({ type: 'send', key: keys[0], data }, transport, () => {}), true)
  assert.deepEqual(delivered, [[keys[0], data]])
})

test('malformed fanout rejects the entire batch before sending anything', () => {
  const transport = { send: () => { throw new Error('invalid request delivered') } }
  for (const value of [[], [...keys, 'f'.repeat(64)], [keys[0], keys[0]], [keys[0], 'invalid'], [keys[0], 123], null]) {
    assert.equal(dispatch({ type: 'send_many', keys: value, data: {} }, transport, () => {}), false)
  }
  for (const data of [[], null, 'text', 17]) assert.equal(dispatch({ type: 'send_many', keys, data }, transport, () => {}), false)
  assert.equal(dispatch({ type: 'unknown', key: keys[0], data: {} }, transport, () => {}), false)
})
