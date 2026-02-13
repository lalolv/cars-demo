# CarsDemo

A Godot 4.x mobile-renderer demo project for an interactive car showroom.

## Overview

CarsDemo showcases multiple classic car models in a 3D showroom scene, with touch camera controls, rotating stage display, slideshow walls, music playback, and lighting presets.

## Features

- Multi-car switching in one showroom scene
- Orbit camera with touch drag rotate and pinch zoom
- Rotating display stage with adaptive car fit
- Background music selection and play/pause control
- Slideshow and promo wall material switching
- Multiple lighting groups and lighting mode presets
- Mobile rendering pipeline (`Mobile`)

## Tech Stack

- Engine: Godot 4.x
- Language: GDScript
- Main scene: `scenes/main.tscn`

## Getting Started

### Prerequisites

- Godot 4.x installed and available in PATH as `godot`

### Run in Editor

```bash
godot --path . --editor
```

### Run the Project

```bash
godot --path .
```

## Controls

- Camera rotate: one-finger drag
- Camera zoom: two-finger pinch
- Keyboard mapping:
  - `W` / `S`: `forward` / `backward`
  - `A` / `D`: `left` / `right`

## Project Structure

```text
cars-demo/
├── assets/      # Models, textures, music, slides
├── scenes/      # Main scene and car scenes
├── scripts/     # GDScript gameplay and UI logic
├── shaders/     # Custom shaders
├── project.godot
└── export_presets.cfg
```

## Build & Export

Export presets are already configured in `export_presets.cfg`. Use Godot Editor's export workflow to package target builds.

## Contributing

Issues and pull requests are welcome.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

