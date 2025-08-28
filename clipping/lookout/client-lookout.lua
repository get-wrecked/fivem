--//=-- Auto Clipping Lookout: Handles the various "signals" (networked game events) to pass off into "vessels."
--//=-- -- Each different "signal" is a different networked game event, and thus each "signal" is retrieved in a different way, by a different file.

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Signal = Medal.AC.Signal or {}

--- Client-side Lookout API
---@class AutoClippingLookoutClient
Medal.AC.Lookout = Medal.AC.Lookout or {}
