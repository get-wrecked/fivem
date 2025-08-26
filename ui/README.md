# UI

React + Vite frontend for the Medal FiveM resource. 
It communicates with the LUA side, via NUI callbacks, and a WebSocket bridge.

## Scripts

- `pnpm dev` - start Vite dev server
- `pnpm build` - builds to `dist/`
- `pnpm lint` - format/lint with Biome

## Stack

- Vite
- TypeScript
- React 19
- Tailwind CSS v4
- Radix UI
- shadcn/ui

## NUI Integration

- POST helper: `ui/src/lib/nui.ts` exports `nuiPost` and `nuiLog`.
- WebSocket client: `ui/src/ws/websocket.ts` exports `wsClient`.
- Handlers: `ui/src/handlers/nui-handlers.tsx` reacts to NUI messages (e.g., `ws:connect`, `ws:send`, `ws:close`).

## Build & Use

1) Install the dependencies for `ui/`:

```bash
pnpm install
```

2) Build the UI:

```bash
pnpm build
```

3) FiveM loads the built UI, from `ui/dist/`, via `ui/index.html`, in the resource.
