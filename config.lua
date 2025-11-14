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

--//=-- Enable/disable debug mode for additional logging and information
Config.Debug = false

--//=-- Command name used to open the Medal Auto-Clipping UI
Config.Command = 'medal'

--//=-- Keybind used to open the Medal Auto-Clipping UI
Config.Keybind = 'pageup'

--//=-- List of events that can trigger automatic clipping
--//=-- To add new events, reference the clipping folder for implementation examples
--//=-- Custom events can also be registered via the 'registerSignal' export
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

--//=-- Screenshot functionality configuration
Config.Screenshots = {
    MedalPreferred = true, --//=-- Use Medal.tv for screenshots when available, fallback to FiveM native if not
    ScreenshotBasicOverride = true --//=-- Override `screenshot-basic` resource exports with Medal functionality
}



--[[
    WARNING: DO NOT MODIFY ANYTHING IN Config.GameVein, or below this point
    This table contains critical connection settings for the GameVein integration.
    Modifying these values may break the resource functionality.
]]
--//=-- GameVein integration settings - used for communication with external Medal.tv service
Config.GameVein = {
    WebSocket = {
        host = "127.0.0.1",
        port = 12556,
        protocol = "ws",
        --//=-- Reconnect behavior (UI WebSocket client)
        reconnectShortAttempts = 5, --//=-- Number of short attempts before switching to the long interval
        reconnectShortMs = 30 * S, --//=-- Short retry interval (ms)
        reconnectLongMs = 120 * S, --//=-- Longer, silent retry interval (ms)
    }
}

--//=-- Assayer defaults (used by nearby data aggregation)
Config.Assayer = {
    ProximityRadius = 60.0, --//=-- Default radius (meters) used when a request specifies proximity fan-out but omits radius
    RequestTimeoutMs = 1500, --//=-- Default timeout (ms) for waiting on nearby players' responses
    BucketMismatchLogTolerance = 5.0, --//=-- Extra tolerance (meters) used only for debug logging on bucket mismatches
}

--//=-- Medal client integration settings
Config.Medal = {
    CheckIntervalMs = 3 * S --//=-- How often to check Medal client availability (milliseconds). Lower = faster detection, higher = less CPU usage
}
