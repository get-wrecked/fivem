# Clipping

The auto-clipping system that monitors in-game events and triggers Medal.tv clip capture automatically. Handles event detection, registration, and coordination with the UI.

- __lookout/__
  - Event handlers for specific game events (player kills, deaths, custom events).
- __signal/__
  - Event registration and custom signal processing.
- __vessel/__
  - Transport layer that sends clip requests to Medal.tv.
- `client-main.lua`
  - Entry point that registers UI commands, keybinds, and initializes the clipping system.
  - Command and keybind toggle the UI open/closed. Pressing again, running the command again, or clicking the X button, closes the UI.
  - Reads configuration from `Config.ClippingEvents` and builds the UI.
- `__types.lua`
  - Type definitions for event configuration and vessel cargo.

## Event Flow

1) Events are configured in `Config.ClippingEvents` or registered via the `registerSignal` export.
2) When a configured event occurs, the appropriate lookout handler triggers.
3) Event data is packaged as vessel cargo and sent to Medal.tv via the vessel system.
4) UI is updated to reflect enabled events and current status.

## Adding New Event Types

1) __Create event handler__ in `clipping/lookout/` following existing patterns:

```lua
function Medal.AC.Lookout.handleCustomEvent(eventId, tags)
    if Settings.eventToggles[eventId] then
        Medal.AC.vesselDepart({
            eventId = eventId,
            tags = tags
        })
    end
end
```

2) __Register the signal__ using the export or add to `Config.ClippingEvents`:

```lua
exports['medal--fivem-resource']:registerSignal('custom:event', {
    id = 'custom_event',
    title = 'Custom Event',
    desc = 'Triggers on custom game event',
    enabled = true,
    tags = { 'custom' }
})
```

## Exports

- `registerSignal(event, options)` - Dynamically register custom clipping events
