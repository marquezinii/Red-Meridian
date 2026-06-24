# Technical Direction

## Engine

Red Meridian uses Godot 4 because it is free, local, lightweight, strong for 2D projects, and practical for long-term development without engine licensing costs.

## Language

The prototype uses GDScript. At this stage, GDScript keeps iteration fast and reduces the amount of infrastructure required outside the engine.

## Current Structure

```text
assets/              Small visual assets and placeholders
data/                Structured gameplay data
docs/                Planning and documentation
scenes/              Godot scenes
scripts/             GDScript and utility scripts
scripts/launch/      Windows launcher
scripts/tests/       Godot smoke tests
```

## Data

Gameplay content should live outside scripts whenever practical. `data/countries.json`, `data/events.json`, and `data/localization.json` are the first examples of this direction.

Guidelines:

- scripts control behavior;
- JSON/resources control content;
- real-world data needs a source before it becomes public content.

## Windows Compatibility

The main launcher is `launch_red_meridian.cmd`, which calls PowerShell with `ExecutionPolicy Bypass` only for the local project launcher script. This avoids common Windows script policy issues while keeping the launcher simple.

The launcher searches for Godot in:

- `GODOT_EXE`;
- `PATH`;
- WinGet package folders;
- common Program Files locations;
- Steam and Epic Games folders;
- Downloads.

## Git

Commits should be small and descriptive. Generated Godot files, local Codex state, builds, and logs should stay out of version control through `.gitignore`.

## Upcoming Technical Decisions

- Real map pipeline.
- Save file format.
- Automated JSON validation.
- Event, focus, and diplomatic relation schemas.
- Safe asset licensing strategy.
