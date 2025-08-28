Config = {}

Config.Debug = true

Config.Command = 'medal'
Config.Keybind = 'pageup'

Config.ClippingEvents = {
    {
        id = 'player_killed',
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

Config.GameVein = {
    WebSocket = {
        host = "127.0.0.1",
        port = 63325,
        protocol = "ws",
    }
}
