# RayTMFKit

[RU](README-RU.md)

A code package designed to simplify development in Odin using raylib. It was formatted and extracted from the *Way Out Of Here* project codebase, then subsequently refined and improved.

## Examples

- [Simple Window](examples/simple_window)
- [2D Render Movement](examples/2d_render_movement)
- [Transition Demo](examples/transition_demo)
- [UI Demo](examples/ui_demo)
- [Locale Demo](examples/locale_demo)
- [Menu Demo](examples/menu_demo)
- [Text Input Demo](examples/text_input_demo)

## What is not included

RayTMFKit contains no game logic. It has no concept of a "player," monster types, or inventory structure; all of that is the game's responsibility. The Kit provides the mechanisms—such as loading textures, rendering text, switching screens, and saving state—while the developer decides how to utilize them.

There are no global asset registries or mandatory `AssetSounds` and `AssetModels` enums. The game decides how to store its resources—whether in an array, a map, or a screen structure. The Kit simply provides functions to convert raw bytes into raylib resources.

There are no mandatory states like `PRE_PLAY` or `PLAY`. The game constructs its own state machine however it sees fit, while the Kit facilitates transitions between any two states via callbacks.

## Philosophy

**Explicit is better than implicit.** If changing the volume requires calling `recompute_sounds`, the game calls it. If not, it doesn't. A `set_on_volume_changed` hook exists, but it is optional.

**Mechanism, not policy.** The Kit supports three ways to scale the render output—the choice is up to the game. It supports both standard and SDF fonts—the choice is up to the game. It works with or without localization.

**One package, one responsibility.** `postfx` knows nothing about audio. `audio` knows nothing about the UI. `ui` knows nothing about game states. The only thing shared between packages is `core`—containing the common frame context and minor utilities.

**Platform-specific code is isolated.** WinAPI calls, `/proc` reads, and fullscreen mode variations are kept in separate files using `#+build` tags. The main codebase remains platform-independent.
