/*
  Medal.tv - FiveM Resource
  =========================
  File: scripts/verify-release.js
  =====================
  Description:
    Validate the generated release package for required contents
  ---
  Exports:
    None
  ---
  Globals:
    None
*/

import { execSync } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const RELEASE_ROOT = 'release';
const RESOURCE_NAME = 'medal';

const REQUIRED_FILES = [
  'config.lua',
  'fxmanifest.lua',
  'superSoaker/dist/server.js',
  'ui/dist/index.html',
];

const REQUIRED_READMES = [
  'README.md',
  'clipping/README.md',
  'gameVein/README.md',
  'gameVein/assayer/README.md',
  'gameVein/ore/README.md',
  'gameVein/shaft/README.md',
  'lib/README.md',
  'services/README.md',
  'superSoaker/README.md',
  'ui/README.md',
];

const FORBIDDEN_PATTERNS = [
  '**/node_modules/**',
  '**/src/**',
  '**/.git/**',
  '**/.turbo/**',
  '**/screenshot-basic/**',
  '**/.vscode/**',
  '**/.windsurf/**',
];

const FORBIDDEN_EXTENSIONS = ['.ts', '.tsx', '.jsx'];

//=-- Utility helpers -------------------------------------------------------
function matchesPattern(filePath, patterns) {
  const normalizedPath = filePath.replace(/\\/g, '/');

  for (const pattern of patterns) {
    const normalizedPattern = pattern.replace(/\\/g, '/');

    if (normalizedPath === normalizedPattern) {
      return true;
    }

    let regexPattern = normalizedPattern
      .replace(/([.+^${}()|[\]\\])/g, '\\$1')
      .replace(/\*\*/g, '___DOUBLE_STAR___')
      .replace(/\*/g, '[^/]*')
      .replace(/\?/g, '.');

    regexPattern = regexPattern.replace(/___DOUBLE_STAR___/g, '.*');

    const regex = new RegExp(`^${regexPattern}$`);
    if (regex.test(normalizedPath)) {
      return true;
    }
  }

  return false;
}

async function getAllFiles(dir, baseDir = dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relativePath = path
      .relative(baseDir, fullPath)
      .replace(/\\/g, '/');

    if (entry.isDirectory()) {
      const subFiles = await getAllFiles(fullPath, baseDir);
      files.push(...subFiles);
    } else {
      files.push(relativePath);
    }
  }

  return files;
}

async function getTotalSize(dir) {
  const files = await getAllFiles(dir, dir);
  let total = 0;

  for (const file of files) {
    const stats = await fs.stat(path.join(dir, file));
    total += stats.size;
  }

  return { files, total };
}
/* //=-- Maybe in the future
function runRelease(rootDir) {
  execSync('pnpm release', {
    cwd: rootDir,
    stdio: 'inherit',
    shell: true,
  });
}
*/

function formatList(items) {
  return items.map(item => `  - ${item}`).join('\n');
}

async function verifyRelease() {
  const rootDir = path.resolve(__dirname, '..');
  const releaseDir = path.join(rootDir, RELEASE_ROOT, RESOURCE_NAME);

  console.log('⚙️  Starting release verification...');
  //runRelease(rootDir); //=-- Maybe in the future

  console.log('\n📁 Checking release contents...');

  try {
    await fs.access(releaseDir);
  } catch (error) {
    console.error('❌ Release directory is missing. Did the release script run successfully?');
    process.exit(1);
  }

  const { files, total } = await getTotalSize(releaseDir);
  const present = new Set(files);

  const missingRequired = REQUIRED_FILES.filter(file => !present.has(file));
  const missingReadmes = REQUIRED_READMES.filter(file => !present.has(file));

  const forbiddenMatches = files.filter(file => {
    if (FORBIDDEN_EXTENSIONS.includes(path.extname(file))) {
      return true;
    }

    return matchesPattern(file, FORBIDDEN_PATTERNS);
  });

  if (missingRequired.length > 0) {
    console.error('❌ Required files are missing:\n' + formatList(missingRequired));
  }

  if (missingReadmes.length > 0) {
    console.error('❌ Required documentation files are missing:\n' + formatList(missingReadmes));
  }

  if (forbiddenMatches.length > 0) {
    console.error('❌ Forbidden files were found in the release:\n' + formatList(forbiddenMatches));
  }

  if (missingRequired.length > 0 || missingReadmes.length > 0 || forbiddenMatches.length > 0) {
    console.error('\nRelease verification failed. See errors above.');
    process.exit(1);
  }

  console.log('✅ Release verification passed.');
  console.log(`📦 File count: ${files.length}`);
  console.log(`💾 Size: ${(total / (1024 * 1024)).toFixed(2)} MB`);
}

verifyRelease().catch(error => {
  console.error('❌ Unexpected verification error:', error);
  process.exit(1);
});
