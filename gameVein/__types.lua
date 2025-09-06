--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/__types.lua
  =====================
  Description:
    Centralized type aliases for GameVein
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

---@meta

---@alias FrameworkKey 'qbx'|'qb'|'esx'|'ox'|'nd'|'tmc'|'unknown'
---@alias WsProtocol 'ws'|'wss'

---@class Job
---@field id string
---@field name string
---@field rank integer   --//=-- -1 indicates unknown
---@field rankName string
