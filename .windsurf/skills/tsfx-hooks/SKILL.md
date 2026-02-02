---
name: tsfx-hooks
description: Skill for using the public API of @tsfx/hooks in external React + TypeScript projects (FiveM NUI front-ends)
scope:
  npm_package: "@tsfx/hooks"
---

# TSFX Hooks Skill (consumer API)

## When to use this skill
Use this skill when you need an agent to:
- Add `@tsfx/hooks` to a React + TypeScript NUI project
- Implement UI-side event handling for client -> UI messages
- Implement UI -> client request/response calls
- Implement visibility gating for NUI panels
- Make the UI work in a normal browser during development

## Install

Add the dependency in your NUI React project:

```bash
pnpm add @tsfx/hooks
```

## Public API (what you can import)

Import from the package root:

```ts
import {
  NuiProvider,
  NuiVisibilityProvider,
  useNuiEvent,
  useNuiVisibility,
  fetchNui,
  isDevBrowser,
  sendDevNuiEvent,
  sendDevNuiEvents,
  NuiVisibilityExempt,
  NuiContext,
  NuiVisibilityContext
} from '@tsfx/hooks';
```

If your bundler complains about `window`/DOM usage, ensure you are using these APIs only in browser/client components.

## Mental model (how it works)

- **Incoming messages (client -> UI)** are received via `window.postMessage` and routed by `action`.
- **Outgoing calls (UI -> client)** are sent via `fetch()` to `https://{resourceName}/{event}` (FiveM NUI convention).
- **Dev mode** is detected by `isDevBrowser()` (true in a normal browser).

## Setup: wrap your app

Wrap your UI once at the root so hooks work:

```tsx
import React from 'react';
import { NuiProvider, NuiVisibilityProvider } from '@tsfx/hooks';

export function Root() {
  return (
    <NuiProvider>
      <NuiVisibilityProvider>
        <App />
      </NuiVisibilityProvider>
    </NuiProvider>
  );
}
```

### Security hardening (recommended)

In a browser, *any* script can `postMessage` to your window. If you embed your NUI in a broader environment or you use iframes, consider restricting what the provider accepts:

```tsx
<NuiProvider
  validateEvent={(event) => {
    const data = event.data as { action?: unknown };
    return typeof data?.action === 'string';
  }}
>
  <App />
</NuiProvider>
```

## Hooks

### `useNuiEvent<T>(action, options)`

Use this for *push* messages from your client script.

```tsx
import React from 'react';
import { useNuiEvent } from '@tsfx/hooks';

type User = { id: number; name: string };

export function UsersPanel() {
  const { data: users } = useNuiEvent<User[]>('users:list', {
    defaultValue: [],
  });

  return (
    <ul>
      {users.map((u) => (
        <li key={u.id}>{u.name}</li>
      ))}
    </ul>
  );
}
```

Side-effects on event arrival:

```tsx
useNuiEvent<number>('cash:update', {
  handler: (cash) => {
    console.log('New cash:', cash);
  }
});
```

### `useNuiVisibility()`

Use this to show/hide expensive UI when the NUI is hidden:

```tsx
import { useNuiVisibility } from '@tsfx/hooks';

export function HUD() {
  const visible = useNuiVisibility();
  if (!visible) return null;
  return <div className="hud">HUD</div>;
}
```

## Services

### `fetchNui<T>(event, { payload, debugReturn })`

Use this for *request/response* calls from UI -> client.

```ts
import { fetchNui } from '@tsfx/hooks';

type Balance = { amount: number; currency: string };

export async function loadBalance() {
  const balance = await fetchNui<Balance>('bank:getBalance');
  if (!balance) return;
  console.log(balance.amount);
}
```

In a normal browser (dev), you can stub a return:

```ts
const result = await fetchNui<{ ok: true }>('ping', { debugReturn: { ok: true } });
```

### `isDevBrowser()`

```ts
import { isDevBrowser } from '@tsfx/hooks';

if (isDevBrowser()) {
  // Avoid FiveM-only paths or load mock data
}
```

### `sendDevNuiEvent` / `sendDevNuiEvents`

Use these to simulate client -> UI messages while running in a normal browser:

```ts
import { sendDevNuiEvent } from '@tsfx/hooks';

sendDevNuiEvent({ action: 'users:list', payload: [{ id: 1, name: 'Alice' }] }, 250);
```

## Visibility: persistent/exempt UI

Use `NuiVisibilityExempt` for content that should remain mounted even when visibility toggles (for example, audio, global portals, or persistent layout shell):

```tsx
import { NuiVisibilityExempt } from '@tsfx/hooks';

export function Root() {
  return (
    <>
      <NuiVisibilityExempt>
        <AlwaysOnToaster />
      </NuiVisibilityExempt>
      <MainPanel />
    </>
  );
}
```

## Common integration notes

- **Next.js/App Router**: components using these hooks must be client components (`'use client';`).
- **Error behavior**: `useNuiEvent` throws if used without a `NuiProvider`.
- **Failure handling**: `fetchNui` can return `undefined` on non-OK HTTP or exceptions; handle that in UI code.

## Agent output constraints (for consumers)

When using this skill in another repo/project, the agent should:
- Only change the consumer project.
- Treat `@tsfx/hooks` as an external dependency.
- Prefer end-to-end type safety using generics (`useNuiEvent<T>`, `fetchNui<T>`).