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
    ScreenshotBasicOverride = true -- Override exports for `screenshot-basic` resource
}

Config.GameVein = {
  WebSocket = {
    host = "127.0.0.1",
    port = 12556,
    protocol = "ws",
  }
}
