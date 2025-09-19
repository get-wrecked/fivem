# ui/src

React-based NUI application source code that provides the Medal.tv integration interface and WebSocket communication with the game client.

- `main.tsx`
  - App entrypoint that renders providers and main component tree.
- `providers.tsx`
  - Global context providers for WebSocket, API status, and settings management.
- **handlers/**
  - NUI event handlers that bridge communication between React UI and Lua client.
  - Handles show/hide, settings updates, and event registration.
- **ws/**
  - WebSocket client implementation for real-time communication with gameVein.
  - Message types and connection management.
- **lib/**
  - NUI utility functions (`nui.ts`), Medal.tv integration (`medal.ts`), and shared helpers (`utils.ts`).
- **components/**
  - React components for UI elements and Medal.tv controls.
  - Includes auto-clipping toggles, server details, and status indicators.
- **contexts/**
  - React contexts for state management across components.
- **providers/**
  - Context provider implementations for centralized state.
- **hooks/**
  - Custom React hooks for accessing context state.
- **assets/**
  - Static assets including logos and icons.
- **superSoaker/**
  - Screenshot capture functionality using CitizenFX Three binding.
