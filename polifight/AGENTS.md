# Repository Guidelines

## Project Structure & Module Organization

PoliFight is a Godot 4.7 local two-player fighting game. `project.godot` defines the main scene and InputMap. Keep reusable gameplay code in `scripts/`: combat flow belongs in `scripts/juego/`, interface logic in `scripts/ui/`, menu behavior in `scripts/menu/`, and shared fighter logic and states in `scripts/personajes/personaje_base/`. Scene files mirror those areas under `escenas/`. Store sprites and UI art in `assets/`; the opening sequence and its shaders live in `cinematica_polifight/`.

`escenas/personajes/barbieri.tscn` and `personaje_base.tscn` currently overlap. Confirm which scene owns a change before editing both. Do not manually edit `.godot/`, imported resources, or generated `.uid` files.

## Build, Test, and Development Commands

Use Godot 4.7 (the executable may be named `godot` or `godot4`):

```bash
godot --editor --path .
godot --path .
godot --headless --editor --path . --quit
```

The first command opens the project, the second runs the configured main scene, and the third imports resources and catches scene or GDScript load errors. No scripted build or export preset is committed; create exports through the Godot editor only after agreeing on a target platform.

## Coding Style & Naming Conventions

Follow existing typed GDScript and use tabs for indentation. Use `snake_case` for files, functions, signals, and variables; use `PascalCase` for globally named classes. Add return and parameter types where practical. Put shared fighter behavior in `Personaje` or a reusable component, and character-specific values or animation wiring in the character scene/script. Read controls through InputMap actions such as `j1_ataque`, never physical keys inside states. Keep movement in `_physics_process()` and clean up hitboxes, signals, and temporary values when leaving a state.

## Testing Guidelines

There is currently no automated test framework or coverage threshold. Every change must pass the headless load check and a focused editor playtest. For combat changes, test both players, left/right orientation, blocking, exactly one hit per attack, attack recovery, KO, victory display, and pause/restart/menu transitions. Name future tests after behavior, for example `test_punio_aplica_un_solo_golpe.gd`.

## Commit & Pull Request Guidelines

History uses short Spanish summaries describing one outcome, for example `Se agregaron los limites...` or `Pausa de juego, KO agregado...`. Keep commits focused and use a concise present- or past-tense summary. Pull requests should explain the playable result, list changed scenes/scripts, document manual checks, link the relevant issue, and include screenshots or a short clip for visual, animation, or HUD changes. Never commit `.godot/` cache data.
