# Godot code

- Keep scenes, scripts, and feature-specific Resources together. Use `class_name` for shared types and explicit argument/return types.
- Use Node classes for engine lifecycle, RefCounted for rules/value objects, Resource for authored configuration. Shared Resources must not hold mutable gameplay state.
- Scene composition owns dependencies; exported references and local child paths are fine. No `get_first_node_in_group`, `/root` lookup, or broad tree search for gameplay dependencies.
- Physics changes occur on the 60 Hz physics tick. Pass elapsed time into rules; do not mix render delta into movement. Presentation can interpolate separately.
- Layers: 1 World, 2 Actors. World movement uses X/Z; Y is physical elevation. Camera/sprite transform is presentation only.
- Preserve `.uid` files on moves; update `res://` references and `project.godot` entry paths. Run the verifier after scene/resource changes.
- First-level feature directories are dependency boundaries; their child directories organize responsibilities. Only `app/` composes unrelated features and infrastructure. Load the feature scope before editing a child directory.
- Runtime scripts have a 200-line budget. Use a focused typed helper for layout, snapshot presentation, geometry or message handling; preserve the owner's state and lifecycle. Avoid generic helper buckets and forwarding APIs without real callers.
