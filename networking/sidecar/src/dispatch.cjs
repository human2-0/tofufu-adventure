'use strict'
// Local authenticated IPC fanout; recipients retain independent direct streams.
function dispatch(message, transport, emit) {
  if (!message.data || typeof message.data !== 'object' || Array.isArray(message.data)) return false
  let keys
  if (message.type === 'send') keys = [message.key]
  else if (message.type === 'send_many') keys = message.keys
  else return false
  if (!Array.isArray(keys) || keys.length < 1 || keys.length > 20 ||
      new Set(keys).size !== keys.length ||
      keys.some(key => typeof key !== 'string' || !/^[0-9a-f]{64}$/.test(key))) return false
  // Validate the entire batch before any delivery; failure of one stream is local.
  for (const key of keys) {
    if (!transport?.send(key, message.data)) emit({ type: 'left', key })
  }
  return true
}
module.exports = { dispatch }
