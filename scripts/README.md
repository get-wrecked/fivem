# Medal FiveM Resource - Build Scripts

## Release Script

The `release.js` script creates a production-ready release of the Medal FiveM resource.

### Usage

Run the following command from the root directory:

```bash
pnpm release
```

### What it does

1. **Builds the project** - Runs `pnpm build` to compile TypeScript and build the UI
2. **Creates release folder** - Creates a `release/medal` directory
3. **Copies resource files** - Includes only the files needed for the FiveM resource:
   - `fxmanifest.lua` and `config.lua`
   - All Lua scripts (client/server/shared)
   - Built JavaScript files (`superSoaker/dist/`)
   - Built UI files (`ui/dist/`)
   - Documentation files (README, LICENSE, etc.)

### Excluded files

The release script automatically excludes:

- **Dynamically loaded from git:**
  - All patterns from `.gitignore` (except `dist` folders which are needed for release)
  - All patterns from `.git/info/exclude`
- **Always excluded:**
  - Source code (`src/` folders)
  - Node modules (`node_modules/`)
  - Development configuration files
  - Build system files (turbo, pnpm, typescript configs)
  - Version control files (`.git/`, `.github/`)
  - IDE configurations (`.vscode/`, `.windsurf/`)

### Output

The release will be created in: `release/medal/`

This folder can be directly copied to your FiveM server's resources directory.

### Requirements

- Node.js (v14 or higher)
- pnpm package manager
- All project dependencies installed (`pnpm install`)

### Notes

- The script is OS-independent and works on Windows, Linux, and macOS
- Always test the release in a development environment before deploying to production
- The script automatically runs the build process, so you don't need to build manually
- Typical release contains ~60 files totaling ~2.3 MB
- All component README files are preserved in the release for documentation
- Respects git-ignored patterns including items in `.git/info/exclude`
