class_name PlayerCommand
extends RefCounted
## One simulation tick of intent. World X/Z map to Vector2 X/Y.
## Local input creates this now; a validated remote adapter can create it later.

var move: Vector2 = Vector2.ZERO
var face_aim: bool = false
var aim: Vector2 = Vector2.DOWN
var aim_point: Vector3 = Vector3.ZERO
var dash_direction: Vector2 = Vector2.DOWN
var jump_pressed: bool = false
var dash_pressed: bool = false

var jump_held: bool = false
var attack_held: bool = false

var guard_held: bool = false
var punch_held: bool = false
var drop_pressed: bool = false
var pickup_pressed: bool = false
var pickup_id: int = -1
var weapon_slot: int = 0

var camp_pressed: bool = false
var time_pressed: bool = false
var use_healing_1: bool = false
var use_healing_2: bool = false
var use_healing_3: bool = false
var use_healing_4: bool = false
var cancel_actions: bool = false
