# SuperSoaker: Screenshot capture and upload

SuperSoaker is a themed, drop-in style system to capture client screenshots and optionally upload them. It mirrors the ergonomics of `screenshot-basic` while integrating tightly with this resource's UI and event flow.

## How it works

SuperSoaker has 3 pieces:

1. **Client** (`superSoaker/client-main.lua`)
   - Exposes exports to capture locally or upload.
   - Listens for server requests to capture.
   - Uses a simple correlation map so async NUI replies route to the right callback.

2. **Server** (`superSoaker/server-main.lua`)
   - Provides an export to ask a specific player to capture, then invokes your callback when ready.
   - Correlates requests using a generated id.

3. **NUI** (`ui/src/superSoaker/capture.ts` -> built to `ui/dist/` and served via `fxmanifest.lua`)
   - Uses the CitizenFX Three binding to read the game frame into a WebGL render target.
   - Responds to `window.postMessage({ request })` from Lua (`SendNUIMessage`) and either:
     - Returns a Data URI (fill), or
     - Uploads to a URL (shoot) and then returns the server response text.

The `fxmanifest.lua` wires the built UI (`ui_page 'ui/dist/index.html'`). The client constructs a `resultURL` like `http://<resource>/soaker_waterCreated` that the UI calls to deliver results back to Lua.

## Client API

File: `superSoaker/client-main.lua`

- __fillSoaker(options?: SoakerOptions, cb: fun(data: string))__
  - Captures a screenshot and returns a `data:image/...;base64,...` URI to your callback.
  - Options:
    - `encoding`: 'jpg' | 'png' | 'webp' (default: 'jpg')
    - `quality`: number 0..1 (for jpg/webp, default 0.92)
    - `headers`: table<string,string> (only used for upload paths)

- __shootWater(url: string, field: string, options?: SoakerOptions, cb: fun(result: string))__
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

File: `superSoaker/server-main.lua`

- __requestPlayerWater(player: number, options: SoakerOptions, cb: fun(err:any|false, data:string, src:number))__
  - Asks `player` to capture a screenshot.
  - Calls back with `err=false` and `data` containing the Data URI returned by the client.
  - If you want the image uploaded, have the client use `shootWater` directly instead.

Example:

```lua
exports['medal--fivem-resource']:requestPlayerWater(source, { encoding = 'png' }, function(err, data, src)
    if err then print('screenshot error', err) return end
    print(('player %s returned %d bytes'):format(src, #data))
end)
```

## NUI Flow

File: `ui/src/supersoaker/capture.ts`

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
  - screenshot-basic: `requestClientScreenshot(player, options, cb)`; supports `fileName` on the server to store the image then return a path.
  - SuperSoaker: `requestPlayerWater(player, options, cb)`; returns a Data URI from the client. There is no built-in server-side file storage option; if you need remote storage, prefer client `shootWater` to your own endpoint.

- **Rendering backend**
  - Both use a Three.js wrapper around the Cfx game view texture; SuperSoaker’s implementation is in `ui/src/supersoaker/capture.ts`.

- **Fallback behavior**
  - Both aim to be robust; SuperSoaker returns a 1×1 transparent PNG when the Three binding is unavailable.

## Notes & tips

- Ensure the import path casing matches the folder name in the UI (the folder here is `supersoaker/`). On case-sensitive environments, `@/superSoaker/capture` will not resolve unless the folder is renamed.
- Use `headers` for authenticated uploads.
- Default encoding is `jpg` with quality `0.92` unless overridden.
