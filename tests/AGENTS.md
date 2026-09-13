# Tests

- Use dependency-free headless SceneTree scripts until test needs justify a framework.
- Rule tests feed commands and grounded state; scene tests exercise real CharacterBody3D collisions and explicit wiring.
- Exit nonzero on failure, including GDScript runtime/parse errors. The Python verifier checks logs because engine errors can otherwise exit zero.
- Network tests must use fakes/local peers by default. Real-network checks are a separate explicit test target.
