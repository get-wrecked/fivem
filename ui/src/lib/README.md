# ui/src/lib

Utilities for NUI communication, and UI helpers.

- `nui.ts`
  - `getResourceName()` — Resolves the FiveM resource name.
  - `nuiPost<T>(endpoint, body?)` — POSTs JSON to a NUI endpoint.
  - `nuiLog(data, level?)` — Logs via Lua Logger bridge (`ws:log`).
- `utils.ts`
  - `cn(...classes)` — Tailwind-friendly class name merge.

## Example

```ts
import { nuiPost, nuiLog } from '@/lib/nui';

await nuiLog('Hello from UI');
const res = await nuiPost('ws:minecart', { type: 'heartbeat' });
```
