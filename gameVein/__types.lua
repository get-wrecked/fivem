--//=-- Centralized type aliases for GameVein

---@meta

---@alias FrameworkKey 'qbx'|'qb'|'esx'|'ox'|'nd'|'tmc'|'unknown'
---@alias WsProtocol 'ws'|'wss'

---@class Job
---@field id string
---@field name string
---@field rank integer   --//=-- -1 indicates unknown
---@field rankName string
