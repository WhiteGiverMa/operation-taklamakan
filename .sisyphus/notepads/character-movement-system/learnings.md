# Character Movement System - Learnings

## Task Completed
Created player character movement system for the landship game.

## Files Created/Modified
- `scenes/ship/player_character.tscn` - Player scene (CharacterBody2D)
- `scripts/player.gd` - Movement script
- `scenes/ship/landship.tscn` - Modified to include PlayerCharacter child

## Key Decisions
1. **Player as child of Landship**: PlayerCharacter is a child of Landship in landship.tscn
   - When main.tscn instances landship.tscn, the player comes along
   - Player moves in local coordinates relative to ship
   
2. **Inline sub_resource for shape**: Used `[sub_resource type="CircleShape2D"]` instead of external .tres file
   - Cleaner for simple shapes
   - No UID issues

3. **Bounds constraint**: Used position clamping after move_and_slide()
   - ±380 x, ±180 y (slightly inside ship bounds of ±400/±200)

## Gotchas Encountered
1. Godot MCP tools: property format matters - use proper Godot format like `Color(0.2, 0.8, 0.3, 1.0)` not tuple strings
2. CollisionShape2D needs explicit shape reference in the tscn file
3. For instanced scenes (like landship), children must be added to the source scene file, not the instance in parent

## Movement Notes
- CharacterBody2D with move_and_slide() treats velocity as world-space movement
- For non-rotating parent (ship), local position == world position for practical purposes
- If ship rotates later, velocity transformation will be needed
