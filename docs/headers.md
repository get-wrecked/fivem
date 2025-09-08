# Medal.tv Headers

These are the standardized headers for files in the Medal.tv FiveM Resource project:

- Use the appropriate format based on the file type.
- These can be expanded as long as the visual structure is maintained, as wide as needed.
- All lists should be unordered/unnumbered and should start with a `-`.
- All list items should have the name, and then a description after a `: `.
- There should be two blank lines after the header and before the code, with the header at the very top of the file.
- `File: [filename.ext]` should be the full path relative to the resource root, with linux style paths.
- Exports are for things explicitly exported, and Globals are for things that are not exported but are still accessible in the global namespace.
- Descriptions should be brief, and to the point, no parameters mentioned.
- If there are multiple exports or globals, they should be listed on separate lines.
- If there are no exports or globals, the line should be `None`.
- Do not add more separator characters than shown below (no extending the `=====` line for example).

## Lua Files
```
--[[
  Medal.tv - FiveM Resource
  =========================
  File: [filename.lua]
  =====================
  Description:
    [brief purpose]
  ---
  Exports:
    [list exports or None]
  ---
  Globals:
    [list globals or None]
]]
```

## TS/TSX Typescript Files
```
/*
  Medal.tv - FiveM Resource
  =========================
  File: [filename.ts] or [filename.tsx]
  =====================
  Description:
    [brief purpose]
  ---
  Exports:
    [list exports or None]
  ---
  Globals:
    [list globals or None]
*/
```
