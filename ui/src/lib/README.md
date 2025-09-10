# ui/src/lib

Utilities for NUI communication, and UI helpers.

- `nui.ts`
  - `nuiLog(data, level?)` — Logs via Lua Logger bridge (`ws:log`).
- `utils.ts`
  - `cn(...classes)` — Tailwind-friendly class name merge.

## Example

```ts
import { nuiLog } from '@/lib/nui';
import { fetchNui } from '@tsfx/hooks';

await nuiLog('Hello from UI');
const res = await fetchNui('ws:minecart', { payload: { type: 'heartbeat' } });
```
