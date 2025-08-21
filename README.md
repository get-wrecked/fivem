# Medal for FiveM

A FiveM/GTA V server resource that integrates with the Medal.tv desktop client to capture gameplay clips and screenshots. It supports manual capture and optional automatic capture based on ingame events, configurable via an ingame menu.

## Features

- Manual video and screenshot capture via the Medal.tv client
- Optional auto-clipping on configurable ingame events
- Ingame menu for toggling and configuring the auto-clipping behavior

## Requirements

- FiveM server (FX Server from after 2020-05)
- Medal.tv client installed, and running on the player’s PC (to use the features)
- Node.js LTS with pnpm installed (just to build the UI, one time)

## Installation

1. Place this resource folder into your server's `resources/` directory.
2. In your server's `server.cfg` (or whatever config file your server uses to load resources), add the line below (replace with your actual folder name for this resource):
    ```cfg
    ensure medal--fivem-resource
    ```
3. Start (or restart) your server.

## Usage

- Ensure the Medal.tv client is running before joining the server.
- Use the ingame menu to:
  - Toggle auto-clipping on/off.
  - Choose which events trigger clips.
  - Adjust capture modes (video or screenshot) as available.

## Auto-Capture Configuration

You can configure automatic capture triggers through the ingame menu. Common examples include:

- Player deaths/downs
- Kills or headshots

Your server can enable/disable specific events to fit its gameplay style.

## UI Building (/ui)

The UI has its own Node.js project under `ui`. Use pnpm to install and build the UI.

### Prerequisites

- Node.js LTS
- pnpm installed globally:

  ```bash
  npm i -g pnpm
  ```

### Build steps

1. From the `ui` directory, install dependencies:

   ```bash
   pnpm install
   ```

2. Build the UI assets:

   ```bash
   pnpm build
   ```

3. This builds `ui/src` into `ui/dist`, which is the NUI loaded by the resource/FXServer.

## Contributors

- [lynexer](https://github.com/lynexer)
- [Imthatguyhere](https://github.com/imthatguyhere)

---

If you encounter issues, or want to suggest new auto-clipping events, please open an issue or PR.
