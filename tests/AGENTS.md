# Tests

- Use dependency-free headless SceneTree scripts until test needs justify a framework.
- Rule tests feed commands and grounded state; scene tests exercise real CharacterBody3D collisions and explicit wiring.
- Exit nonzero on failure, including GDScript runtime/parse errors. The Python verifier checks logs because engine errors can otherwise exit zero.
- Network tests must use fakes/local peers by default. Real-network checks are a separate explicit test target.
- Test entry paths stay stable under `tests/`; find scenarios by feature name in `docs/AGENT_MAP.md`. Long end-to-end scripts are exempt from the runtime line budget. Update resource references when runtime files move, then run the full verifier.
