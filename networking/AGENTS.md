# P2P infrastructure

- Read `docs/architecture/COOP.md` before implementing here. This directory contains the experimental Node/Hyperswarm bridge and its tests.
- Holepunch dependencies stay in the sidecar/adapter. No networking SDK in player rules, visuals, or UI.
- Use direct peer gameplay connections; never silently enable payload relays or a central game backend. Discovery/bootstrap participation is separate from gameplay forwarding.
- A player-host validates commands and owns simulation. Authenticated identity is bound to the transport connection, never trusted from a message field.
- Bound frame size, queues, rates and handshake duration. Handle stream fragmentation/coalescing and backpressure; encrypted streams are not datagram channels.
- Keep bridge framing, authentication, session lifecycle and replication in separate objects. No giant networking manager.
- Never deserialize remote Godot Objects/Resources or execute peer-supplied code. Protocol data is versioned and validated before gameplay sees it.
- Offline startup must not launch the sidecar. Test unavailable peers, direct-connection failure, malformed traffic and clean shutdown before gameplay integration.
