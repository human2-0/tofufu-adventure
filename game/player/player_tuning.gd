class_name PlayerTuning
extends Resource
## Shared configuration only. Per-player runtime state belongs in PlayerMotor.

@export_group("Movement")
@export_range(0.0, 50.0) var walk_speed: float = 6.5
@export_range(0.0, 200.0) var acceleration: float = 45.0
@export_range(0.0, 200.0) var friction: float = 35.0
@export_group("Jump")
@export_range(0.0, 50.0) var jump_velocity: float = 12.0
@export_range(0.0, 100.0) var gravity: float = 40.0
@export_range(1.0, 5.0) var fall_gravity_multiplier: float = 1.65
@export_range(0.0, 1.0) var coyote_time: float = 0.12
@export_range(0.0, 1.0) var jump_buffer_time: float = 0.12
@export_group("Dash")
@export_range(0.0, 100.0) var dash_speed: float = 18.0
@export_range(0.01, 2.0) var dash_duration: float = 0.18
@export_range(0.0, 5.0) var dash_cooldown: float = 0.7
@export_range(0.1, 2.0) var super_dash_charge_seconds: float = 0.66
@export_range(1.0, 4.0) var super_dash_duration_multiplier: float = 2.0

@export_group("Super jump")
@export_range(0.1, 2.0) var jump_charge_seconds: float = 0.65
@export_range(1.0, 4.0) var super_jump_height_multiplier: float = 2.0
