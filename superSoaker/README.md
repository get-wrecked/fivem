# SuperSoaker

Screenshot capture and upload system that provides drop-in replacement for `screenshot-basic` while integrating with Medal.tv functionality and the resource's UI/event flow.

- **Client** (`superSoaker/client-main.lua`)
  - Exposes exports to capture locally or upload.
  - Listens for server requests to capture.
  - Uses correlation mapping for async NUI callback routing.
- **Server** (`superSoaker/server-main.lua`)
  - Provides export to request player screenshots with callback support.
  - Handles request correlation using generated IDs.
- **NUI** (`ui/src/superSoaker/capture.ts`)
  - Uses CitizenFX Three binding to read game frames into WebGL render targets.
  - Handles capture requests via `window.postMessage` and returns Data URIs or upload responses.

## How it works

1. **Client** (`superSoaker/client-main.lua`)
   - Exposes exports to capture locally or upload.
   - Listens for server requests to capture.
   - Uses a simple correlation map so async NUI replies route to the right callback.

2. **Server** (`superSoaker/server-main.lua` + `superSoaker/src/server/server.ts`)
   - Lua server provides an export to ask a specific player to capture, then invokes your callback when ready.
   - **NEW: HTTP Upload System** - The server now uses an HTTP-based upload system (similar to screenshot-basic) to handle large screenshot data that can't be sent via events.
   - TypeScript HTTP server generates unique tokens and provides upload endpoints.
   - When requesting a screenshot, the server generates a token, registers a callback, and sends the upload URL to the client.
   - Client captures and uploads directly to the HTTP endpoint with the token.
   - Server receives the upload, validates the token, and triggers the original callback.

3. **NUI** (`ui/src/superSoaker/capture.ts` -> built to `ui/dist/` and served via `fxmanifest.lua`)
   - Uses the CitizenFX Three binding to read the game frame into a WebGL render target.
   - Responds to `window.postMessage({ request })` from Lua (`SendNUIMessage`) and either:
     - Returns a Data URI (fill), or
     - Uploads to a URL (shoot) and then returns the server response text.

The `fxmanifest.lua` wires the built UI (`ui_page 'ui/dist/index.html'`). The client constructs a `resultURL` like `http://<resource>/soaker_waterCreated` that the UI calls to deliver results back to Lua.

## Build Instructions

The superSoaker HTTP server must be built before use. From the **root** of the resource:

```bash
pnpm install
pnpm build
```

This compiles `src/server/server.ts` to `dist/server.js` which is loaded by fxmanifest.

### Build Commands

- **`pnpm build`** - Builds both server and UI
- **`pnpm build:server`** - Builds only the superSoaker HTTP server
- **`pnpm build:ui`** - Builds only the React UI

The compiled `dist/server.js` should be committed to your repo or built during deployment.

## Client API

File: `superSoaker/client-main.lua`

- **fillSoaker(options?: SoakerOptions, cb: fun(data: string))**
  - Captures a screenshot and returns a `data:image/...;base64,...` URI to your callback.
  - Options:
    - `encoding`: 'jpg' | 'png' | 'webp' (default: 'jpg')
    - `quality`: number 0..1 (for jpg/webp, default 0.92)
    - `headers`: table<string,string> (only used for upload paths)

- **shootWater(url: string, field: string, options?: SoakerOptions, cb: fun(result: string))**
  - Captures a screenshot and uploads it as `multipart/form-data` to `url` with file field name `field`.
  - Returns the HTTP response text from the upload endpoint.
  - `headers` (optional) will be sent on the upload request.

Examples:

```lua
-- Fill (local data URI)
exports['medal--fivem-resource']:fillSoaker({ encoding = 'jpg', quality = 0.92 }, function(data)
    TriggerEvent('chat:addMessage', { template = '<img src="{0}" style="max-width: 300px;" />', args = { data } })
end)

-- Shoot (upload)
exports['medal--fivem-resource']:shootWater('https://your-upload/endpoint', 'file', {
    encoding = 'jpg', quality = 0.9, headers = { Authorization = 'Bearer XYZ' }
}, function(resp)
    print('upload result', resp)
end)
```

## Server API

File: `superSoaker/server-main.lua` + `superSoaker/src/server/server.ts`

- **requestPlayerWater(player: number, options: SoakerOptions, cb: fun(err:any|false, data:string, src:number))**
  - Asks `player` to capture a screenshot via HTTP upload.
  - Generates a unique token and registers a callback with the HTTP server.
  - Sends the client an upload URL with the token.
  - Client captures and uploads the screenshot via HTTP (not via events, as data URIs are too large for events).
  - When the upload completes, calls back with `err=false` and `data` containing the Data URI.
  - **Important**: Screenshot data is now transmitted via HTTP instead of server events to handle large base64 strings.

Example:

```lua
exports['medal--fivem-resource']:requestPlayerWater(source, { encoding = 'png' }, function(err, data, src)
    if err then print('screenshot error', err) return end
    print(('player %s returned %d bytes'):format(src, #data))
end)
```

## NUI Flow

File: `ui/src/superSoaker/capture.ts`

- Listens for `window.postMessage({ request })` where `request` has:
  - `encoding`, `quality`, `headers`, `correlation`
  - `resultURL?` — NUI will POST `{ id, data }` here (either image data URI or upload response text)
  - `targetURL?` and `targetField?` — if present, NUI uploads a file via `multipart/form-data`
- Uses `@citizenfx/three` to read pixels and generate the image.
- If Three is unavailable, returns a 1x1 transparent PNG as a safe fallback.

Build UI with:

```sh
pnpm install
pnpm build
```

`fxmanifest.lua` serves `ui/dist/index.html` as the resource UI page.

## Comparison with screenshot-basic

Feature parity and differences compared to `screenshot-basic`:

- **Client capture (local)**
  - screenshot-basic: `requestScreenshot(options?, cb)` → Data URI
  - SuperSoaker: `fillSoaker(options?, cb)` → Data URI

- **Client upload**
  - screenshot-basic: `requestScreenshotUpload(url, field, options?, cb)` → HTTP response text
  - SuperSoaker: `shootWater(url, field, options?, cb)` → HTTP response text
  - SuperSoaker supports optional `headers` on upload (e.g., auth) which is not documented in screenshot-basic README.

- **Server-initiated capture**
  - screenshot-basic: `requestClientScreenshot(player, options, cb)`; supports `fileName` on the server to store the image then return a path. Uses HTTP upload with token-based authentication.
  - SuperSoaker: `requestPlayerWater(player, options, cb)`; returns a Data URI from the client via HTTP upload (similar to screenshot-basic). Uses the same token-based HTTP upload system to handle large data URIs. There is no built-in server-side file storage option; if you need remote storage, prefer client `shootWater` to your own endpoint.

- **Rendering backend**
  - Both use a Three.js wrapper around the Cfx game view texture; SuperSoaker’s implementation is in `ui/src/superSoaker/capture.ts`.

- **Fallback behavior**
  - Both aim to be robust; SuperSoaker returns a 1×1 transparent PNG when the Three binding is unavailable.

## Notes & tips

- Ensure the import path casing matches the folder name in the UI (the folder here is `superSoaker/`). On case-sensitive environments, always import using `@/superSoaker/capture` to match the folder name.
- Use `headers` for authenticated uploads.
- Default encoding is `jpg` with quality `0.92` unless overridden.
