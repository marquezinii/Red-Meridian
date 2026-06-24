# Red Meridian

Red Meridian is a 2D geopolitical and military strategy game prototype built with Godot 4.

The long-term goal is to combine political simulation, economy, diplomacy, intelligence, military readiness, doctrine, logistics, and strategic operations into a readable grand strategy experience. The project takes inspiration from the genre, but it does not copy proprietary systems, interfaces, assets, or content from other games.

The game is currently in an early local prototype stage. The priority is to build a stable foundation that can grow over time without restarting the project.

## Current Status

- Engine: Godot 4.
- Initial platform: Windows.
- Current scope: local 2D prototype.
- Multiplayer: out of scope for now.
- Real-world data: placeholders until sources, licensing, and editorial rules are defined.

## Running the Project

Use the `Red Meridian` desktop shortcut or run:

```powershell
.\launch_red_meridian.cmd
```

The launcher searches for a local Godot 4 installation and opens this folder as a project. If Godot is not available through `PATH`, the launcher also checks common Windows locations, including WinGet package folders. You can also set the `GODOT_EXE` environment variable to the exact Godot executable path.

## Implemented Prototype Features

- Main 2D strategy screen.
- Main menu with Single Player, Multiplayer placeholder, Settings, About, and Quit.
- Abstract clickable strategic map.
- Real countries represented as simulated entities.
- Basic date, pause, and speed controls.
- Global tension, stability, GDP, military power, readiness, and diplomacy indicators.
- Government actions.
- National focus entries with duration and effects.
- Player country selection.
- Early strategic event model.
- Runtime settings screen with General, Display, Graphics, and Audio tabs.
- Display settings for monitor, native resolution, window mode, VSync, FPS cap, UI scale, and cursor confinement.
- Graphics presets with a Custom state when individual options are changed.
- Audio settings where Master Volume caps Music, Effects, and Interface volume sliders.
- Initial English and Brazilian Portuguese localization support.
- External JSON data files for countries and events.

## Validation

The current project includes a small Godot smoke test for the menu flow:

```powershell
godot --headless --path . --script res://scripts/tests/MenuSmokeTest.gd
```

## Project Direction

Planning documents live in `docs/`:

- `docs/VISION.md`: product vision and design pillars.
- `docs/ROADMAP.md`: technical and gameplay roadmap.
- `docs/TECHNICAL_DIRECTION.md`: initial technical direction.

## Real-World Data Policy

Country names are factual data. However, portraits, photos, biographies, logos, detailed political datasets, and any third-party material require clear sourcing, licensing, and editorial review before public use.

For now, the project uses placeholders and keeps the data structure ready for audited content later.

## Third-Party Assets

- `assets/fonts/Orbitron-Variable.ttf`: Orbitron, licensed under the SIL Open Font License.
- `assets/fonts/Inter-Variable.ttf`: Inter, licensed under the SIL Open Font License.

Font license files are stored next to the font files.

## License

No public license has been selected yet. Until a license is explicitly added, all rights are reserved.
