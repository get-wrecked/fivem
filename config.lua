--[[
  Medal.tv - FiveM Resource
  =========================
  File: config.lua
  =====================
  Description:
    Configuration settings for the resource
  ---
  Exports:
    None
  ---
  Globals:
    - Config : Configuration table
]]

Config = {}

--//=-- Time unit constants
local MS = 1
local S = 1000 * MS

Config.Debug = true

Config.Command = 'medal'
Config.Keybind = 'pageup'

Config.ClippingEvents = {
    {
        id = 'player_kill',
        title = 'Player Killed',
        desc = 'Triggers when you kill another player',
        enabled = true
    },
    {
        id = 'player_death',
        title = 'Player Died',
        desc = 'Triggers when you die',
        enabled = true
    }
}

Config.Screenshots = {
    MedalPreferred = true, -- Leverages Medal to provide user screenshots (when available)
    ScreenshotBasicOverride = true -- Override exports for `screenshot-basic` resource
}

Config.GameVein = {
  WebSocket = {
    host = "127.0.0.1",
    port = 12556,
    protocol = "ws",
    --//=-- Reconnect behavior (UI WebSocket client)
    --//=-- Number of short attempts before switching to the long interval
    reconnectShortAttempts = 5,
    --//=-- Short retry interval (ms)
    reconnectShortMs = 30 * S,
    --//=-- Longer, silent retry interval (ms)
    reconnectLongMs = 120 * S,
  }
}
