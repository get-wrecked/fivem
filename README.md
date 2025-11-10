# Medal for FiveM

A FiveM/GTA V server resource that integrates with the Medal.tv desktop client to capture gameplay clips and screenshots. It supports manual capture and optional automatic capture based on ingame events, configurable via an ingame menu.

## Features

- **Auto-Clipping UI**: Toggle auto-clipping, configure clip length, and enable/disable specific events.
- **Custom Event Signals**: Dynamically register your own clipping events at runtime via the `registerSignal` export.
- **SuperSoaker Screenshots**: Drop-in replacement for `screenshot-basic` with both local capture and HTTP upload.
- **GameVein Data Pipeline**: Allows the Medal client to get game context and server info when clipping.
- **Framework-Aware**: The server detects framework (ESX → QBX → QB → ND → OX → TMC → unknown) and provides safe export helpers to avoid errors, without loading any framework resource files directly.

## Requirements

- FiveM server (FX Server from after 2020-05)
- Medal.tv client installed, and running on the player’s PC (to use the full features)
- Node.js LTS with pnpm installed (just to build the UI, one time, or avoid this with a Github release).

## Installation

1. Place this resource folder into your server's `resources/` directory.
2. In your server's `server.cfg` (or whatever config file your server uses to load resources), add the line below (replace with your actual folder name for this resource):

    ```cfg
    ensure medal--fivem-resource
    ```

3. Start (or restart) your server.

## Usage

- Ensure the Medal.tv desktop client is running before joining the server.
- Open the Medal UI in-game:
  - Chat command: `/medal` (from `Config.Command`)
  - Default keybind: `Page Up` (from `Config.Keybind`)
- In the UI, you can:
  - Toggle auto-clipping on/off
  - Set clip length
  - Enable/disable individual events

Settings persist via resource KVPs; toggles and clip length are remembered per player.

## Auto-Capture Configuration

You can configure automatic capture triggers through the ingame menu. Common examples include:

- Player deaths/downs
- Kills or headshots

Your server can enable/disable specific events to fit its gameplay style.

## Building

This resource uses a pnpm workspace to manage builds for both the UI and the SuperSoaker HTTP server.

### Prerequisites

- Node.js LTS (v18+)
- pnpm installed globally:

  ```bash
  npm i -g pnpm
  ```

### Build Steps

From the **root** of the resource:

1. Install dependencies:

   ```bash
   pnpm install
   ```

2. Build everything:

   ```bash
   pnpm build
   ```

This builds:

- **UI**: `ui/src` → `ui/dist` (Vite build for the NUI)
- **SuperSoaker Server**: `superSoaker/src/server/server.ts` → `superSoaker/dist/server.js` (TypeScript → CommonJS)

### Individual Builds

- `pnpm build:server` - Build only the SuperSoaker HTTP server
- `pnpm build:ui` - Build only the React UI
- `pnpm dev:ui` - Start Vite dev server for UI development

**Note**: The compiled `superSoaker/dist/server.js` must exist before starting the resource.

## Release

To create a production-ready release package for deployment to FiveM servers:

```bash
pnpm release
```

This command:

1. **Automatically builds** the entire project (UI and TypeScript)
2. **Creates** a `release/medal/` directory
3. **Packages** only production files (~60 files, ~2.3 MB):
   - Core resource files (`fxmanifest.lua`, `config.lua`)
   - All Lua scripts (client/server/shared)
   - Built JavaScript (`superSoaker/dist/server.js`)
   - Built UI (`ui/dist/*`)
   - Documentation (all README files, LICENSE)

The release script:

- **Dynamically excludes** files from `.gitignore` and `.git/info/exclude`
- **Preserves** built `dist` folders (overriding gitignore) as they contain production code
- **Works** on Windows, Linux, and macOS

The resulting `release/medal/` folder can be directly copied to your FiveM server's resources directory.

## Configuration Highlights

- `config.lua`
  - `Config.Command` and `Config.Keybind` control how players open the UI.
  - `Config.ClippingEvents` pre-registers events visible in the Auto-Clipping UI.
  - `Config.Screenshots`
    - `MedalPreferred`: Prefer Medal.tv for screenshots when available.
    - `ScreenshotBasicOverride`: Provides compatibility for `screenshot-basic` exports.

## Exports

### Client Exports

- `fillSoaker(options?: SoakerOptions, cb: fun(data:string))`
  - Capture a screenshot and return a Data URI to the callback.
  - Example:

    ```lua
    --//=-- Local screenshot as Data URI
    exports['medal--fivem-resource']:fillSoaker({ encoding = 'jpg', quality = 0.92 }, function(data)
      TriggerEvent('chat:addMessage', { template = '<img src="{0}" style="max-width: 300px;" />', args = { data } })
    end)
    ```

- `shootWater(url: string, field: string, options?: SoakerOptions, cb: fun(result:string))`
  - Capture a screenshot and upload as `multipart/form-data` to `url`, invoking the callback with the HTTP response text.
  - Example:

    ```lua
    --//=-- Upload screenshot
    exports['medal--fivem-resource']:shootWater('https://your-upload/endpoint', 'file', {
      encoding = 'jpg', quality = 0.9, headers = { Authorization = 'Bearer XYZ' }
    }, function(resp)
      print('upload result', resp)
    end)
    ```

- `registerSignal(event: string, options: EventConfig)`
  - Dynamically register a custom auto-clipping event with the UI and handler.
  - Example:

    ```lua
    --//=-- Register a custom event; when `my:custom:event` is triggered, a clip request is sent
    exports['medal--fivem-resource']:registerSignal('my:custom:event', {
      id = 'my_custom_event',
      title = 'My Custom Event',
      desc = 'Triggers on my custom event',
      enabled = true,
      tags = { 'custom' }
    })
    ```

#### EventConfig shape

Event configs define how an auto-clipping event appears and behaves in the UI. See `clipping/__types.lua`.

```lua
EventConfig = {
  id: string,           -- unique id used internally and for persistence
  title: string,        -- display name in the UI
  desc?: string,        -- optional description shown in the UI
  enabled?: boolean,    -- whether the event is enabled by default
  tags?: string[],      -- optional tags passed along with clip requests
}
```

### Server Exports

- `requestPlayerWater(player: number, options: SoakerOptions, cb: fun(err:any|false, data:string, src:number))`
  - Ask a specific player to capture a screenshot; the callback receives a Data URI.
  - Example:

    ```lua
    --//=-- Request a screenshot from a player
    exports['medal--fivem-resource']:requestPlayerWater(source, { encoding = 'png' }, function(err, data, src)
      if err then print('screenshot error', err) return end
      print(('player %s returned %d bytes'):format(src, #data))
    end)
    ```

### Notes on Compatibility

- When `Config.Screenshots.ScreenshotBasicOverride = true`, the resource provides handlers compatible with
  `screenshot-basic` client/server exports (fill/upload and request client screenshot).
  Prefer the `fillSoaker`/`shootWater`/`requestPlayerWater` exports shown above for consistent behavior.

## Additional READMEs for Features

- **Core**
  - [gameVein/](gameVein/README.md)
    - [ore/](gameVein/ore/README.md)
    - [assayer/](gameVein/assayer/README.md)
    - [shaft/](gameVein/shaft/README.md)
  - [clipping/](clipping/README.md)
  - [superSoaker/](superSoaker/README.md)
  
- **UI**
  - [ui/](ui/README.md)
    - [ui/src/](ui/src/README.md)
      - [handlers/](ui/src/handlers/README.md)
      - [ws/](ui/src/ws/README.md)
      - [lib/](ui/src/lib/README.md)
      - [components/](ui/src/components/README.md)
      - [components/ui/](ui/src/components/ui/README.md)
      - [assets/](ui/src/assets/README.md)
- **Utilities**
  - [lib/](lib/README.md)
  - [services/](services/README.md)
  - [scripts/](scripts/README.md)

## Primary Contributors

- [![lynexer's Avatar](https://avatars.githubusercontent.com/u/5565402?s=18&v=4)  lynexer](https://github.com/lynexer)
- [![Imthatguyhere's Avatar](https://avatars.githubusercontent.com/u/5384585?s=18&v=4)  Imthatguyhere](https://github.com/imthatguyhere)

---

If you encounter issues, or want to suggest new auto-clipping events, please open an issue or PR.
