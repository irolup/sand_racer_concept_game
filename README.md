# Sand Racer

A terrain-editing racing game built with Godot 4.4. Create custom tracks by sculpting terrain!

## Current Status

**⚠️ Work in Progress / Early Access**

**Note**: This is a game concept/prototype. The project may be abandoned in the future.

This game is functional but incomplete:
- [x] Level editor with terrain sculpting (marching cubes)
- [x]Track saving and loading
- [x] Vehicle physics and racing mechanics
- [x] Checkpoint and finish line system
- [ ] Missing some textures and models
- [ ] Campaign mode may not be fully functional

The core gameplay loop works: you can create tracks, save them, load them, and race on them.

## Features

- **Terrain Editor**: Sculpt terrain using marching cubes algorithm
- **Track Creation**: Place checkpoints, start/finish lines, and objects
- **Save/Load System**: Save your custom tracks and load them later
- **Vehicle Physics**: Realistic vehicle physics using the kv-vehicle addon
- **Multiple Game Modes**: Switch between editor and driving modes

## Controls

### Editor Mode
- **WASD**: Move camera
- **Mouse**: Look around
- **Left Click**: Dig terrain
- **Right Click**: Place terrain
- **Middle Click**: Equalize terrain
- **1**: Normal mode
- **2**: Editor mode
- **3**: Object placer mode
- **5**: Selector mode
- **B**: Cycle brush type
- **E/Q**: Cycle brush/object selection
- **M/N**: Increase/decrease brush radius
- **R**: Rotate object
- **P**: Place object
- **Delete**: Delete selected object
- **F7**: Save map
- **F8**: Load map

### Driving Mode
- **W/S**: Throttle/Brake
- **A/D**: Steer
- **Space**: Handbrake
- **C**: Cycle camera
- **F1**: Respawn

## Requirements

- Godot 4.4 or later

## Known Issues

- Some textures and models are missing (placeholder visuals)
- Campaign mode may not be fully functional
- UI may need polish


## Credits

- Built with [Godot Engine](https://godotengine.org/)
- Vehicle physics: [kv-vehicle addon](https://github.com/kurtzmusch/kv-vehicle) by Kurtzmusch
- Icons from [game-icons.net](https://game-icons.net/)


