extends "res://src/profile.gd"

func _init() -> void:
 super(false)

# Benchmark data and loot live only in memory; never touch normal saves.
func save_game() -> bool:
 return true
