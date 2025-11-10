/*
  Medal.tv - FiveM Resource
  =========================
  File: scripts/release.js
  =====================
  Description:
    Build and package the FiveM resource for release
  ---
  Exports:
    None
  ---
  Globals:
    None
*/


import { promises as fs, existsSync, readFileSync } from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

//=-- Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

//=-- Configuration
const RELEASE_DIR = 'release';
const RESOURCE_NAME = 'medal';

//=-- Files and folders to include in the release
const INCLUDE_PATTERNS = [
  //=-- Core resource files
  'fxmanifest.lua',
  'config.lua',
  
  //=-- Lua files (all client/server/shared scripts)
  'lib/*.lua',
  'services/*.lua',
  'gameVein/*.lua',
  'gameVein/**/*.lua',
  'clipping/*.lua',
  'clipping/**/*.lua',
  'superSoaker/*.lua',
  
  //=-- Built JavaScript files
  'superSoaker/dist/*',
  'superSoaker/dist/**/*',
  
  //=-- UI dist files
  'ui/dist/*',
  'ui/dist/**/*',
  
  //=-- Documentation
  'README.md',
  'LICENSE',
  'docs/**/*',
  '*.md',
  '**/README.md',  //=-- Include all README files in subdirectories
  'ui/README.md',  //=-- Specifically include UI README
];

/**
 * Load patterns from gitignore files
 * @param {string} rootDir - Root directory of the project
 * @returns {string[]} Array of patterns to exclude
 */
function loadGitIgnorePatterns(rootDir) {
  const patterns = [];
  
  //=-- Load .gitignore
  const gitignorePath = path.join(rootDir, '.gitignore');
  if (existsSync(gitignorePath)) {
    const content = readFileSync(gitignorePath, 'utf8');
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      //=-- Skip comments and empty lines
      if (trimmed && !trimmed.startsWith('#')) {
        //=-- Override: Skip dist patterns from gitignore since we need built files for release
        //=-- (ui/dist and superSoaker/dist contain the compiled production code)
        if (!trimmed.includes('/dist') && !trimmed.includes('dist/')) {
          patterns.push(trimmed);
        }
      }
    }
  }
  
  //=-- Load .git/info/exclude
  const excludePath = path.join(rootDir, '.git', 'info', 'exclude');
  if (existsSync(excludePath)) {
    const content = readFileSync(excludePath, 'utf8');
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      //=-- Skip comments and empty lines
      if (trimmed && !trimmed.startsWith('#')) {
        patterns.push(trimmed);
      }
    }
  }
  
  return patterns;
}

//=-- Base exclude patterns (always exclude these)
const BASE_EXCLUDE_PATTERNS = [
  //=-- Source and development files
  '**/src/**',
  '**/package.json',
  '**/tsconfig.json',
  '**/pnpm-lock.yaml',
  '**/pnpm-workspace.yaml',
  '**/turbo.json',
  '**/biome.json',
  '**/vite.config.*',
  '**/postcss.config.*',
  '**/components.json',
  
  //=-- Version control and IDE
  '**/.git/**',
  '**/.github/**',
  '**/.vscode/**',
  '**/.windsurf/**',
  
  //=-- Specific excludes
  'ui/index.html',  //=-- Exclude source ui index.html but not ui/dist/index.html
  'scripts/**',
  'release/**',
];

/**
 * Check if a path matches any of the given patterns
 * @param {string} filePath - Path to check
 * @param {string[]} patterns - Array of glob patterns
 * @returns {boolean} True if path matches any pattern
 */
function matchesPattern(filePath, patterns) {
  const normalizedPath = filePath.replace(/\\/g, '/');
  
  for (const pattern of patterns) {
    const normalizedPattern = pattern.replace(/\\/g, '/');
    
    //=-- Exact match
    if (normalizedPath === normalizedPattern) {
      return true;
    }
    
    //=-- Convert glob pattern to regex
    let regexPattern = normalizedPattern;
    
    //=-- Escape special regex characters except * and ?
    regexPattern = regexPattern.replace(/([.+^${}()|[\]\\])/g, '\\$1');
    
    //=-- Replace ** with .* (matches any number of directories)
    regexPattern = regexPattern.replace(/\*\*/g, '___DOUBLE_STAR___');
    
    //=-- Replace * with [^/]* (matches any characters except /)
    regexPattern = regexPattern.replace(/\*/g, '[^/]*');
    
    //=-- Replace ? with . (matches single character)
    regexPattern = regexPattern.replace(/\?/g, '.');
    
    //=-- Restore ** as .*
    regexPattern = regexPattern.replace(/___DOUBLE_STAR___/g, '.*');
    
    //=-- Create regex and test
    const regex = new RegExp('^' + regexPattern + '$');
    if (regex.test(normalizedPath)) {
      return true;
    }
  }
  
  return false;
}

/**
 * Get all files in a directory recursively
 * @param {string} dir - Directory to scan
 * @param {string} baseDir - Base directory for relative paths
 * @param {string[]} excludePatterns - Patterns to exclude
 * @returns {Promise<string[]>} Array of relative file paths
 */
async function getAllFiles(dir, baseDir = dir, excludePatterns = []) {
  const files = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relativePath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
    
    //=-- Skip excluded patterns
    if (matchesPattern(relativePath, excludePatterns)) {
      continue;
    }
    
    if (entry.isDirectory()) {
      const subFiles = await getAllFiles(fullPath, baseDir, excludePatterns);
      files.push(...subFiles);
    } else {
      files.push(relativePath);
    }
  }
  
  return files;
}

/**
 * Copy a file to the release directory
 * @param {string} src - Source file path
 * @param {string} dest - Destination file path
 */
async function copyFile(src, dest) {
  //=-- Ensure destination directory exists
  const destDir = path.dirname(dest);
  await fs.mkdir(destDir, { recursive: true });
  
  //=-- Copy the file
  await fs.copyFile(src, dest);
}

/**
 * Build the project
 */
function buildProject() {
  console.log('📦 Building project...');
  try {
    execSync('pnpm build', { 
      stdio: 'inherit',
      shell: true
    });
    console.log('✅ Build completed successfully');
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    process.exit(1);
  }
}

/**
 * Main release function
 */
async function release() {
  try {
    console.log('🚀 Starting release process...\n');
    
    //=-- Build the project first
    buildProject();
    console.log('');
    
    //=-- Get the root directory
    const rootDir = path.resolve(__dirname, '..');
    const releaseDir = path.join(rootDir, RELEASE_DIR, RESOURCE_NAME);
    
    //=-- Load exclude patterns from git files
    console.log('📋 Loading exclude patterns from git configuration...');
    const gitPatterns = loadGitIgnorePatterns(rootDir);
    const EXCLUDE_PATTERNS = [...BASE_EXCLUDE_PATTERNS, ...gitPatterns];
    console.log(`  Found ${gitPatterns.length} patterns from git files`);
    console.log('');
    
    //=-- Clean up old release directory
    if (existsSync(releaseDir)) {
      console.log('🧹 Cleaning up old release directory...');
      await fs.rm(releaseDir, { recursive: true, force: true });
    }
    
    //=-- Create release directory
    console.log('📁 Creating release directory...');
    await fs.mkdir(releaseDir, { recursive: true });
    
    //=-- Get all files in the project
    console.log('🔍 Scanning for files to include...');
    const allFiles = await getAllFiles(rootDir, rootDir, EXCLUDE_PATTERNS);
    
    //=-- Filter files based on include patterns
    const filesToCopy = allFiles.filter(file => {
      //=-- Check if file matches any include pattern
      const shouldInclude = matchesPattern(file, INCLUDE_PATTERNS);
      
      //=-- Double-check it's not excluded
      const shouldExclude = matchesPattern(file, EXCLUDE_PATTERNS);
      
      return shouldInclude && !shouldExclude;
    });
    
    console.log(`📋 Found ${filesToCopy.length} files to include in release\n`);
    
    //=-- Copy files to release directory
    let copied = 0;
    for (const file of filesToCopy) {
      const src = path.join(rootDir, file);
      const dest = path.join(releaseDir, file);
      
      await copyFile(src, dest);
      copied++;
      
      //=-- Show progress every 10 files
      if (copied % 10 === 0) {
        console.log(`  📄 Copied ${copied}/${filesToCopy.length} files...`);
      }
    }
    
    console.log(`\n✅ Release created successfully!`);
    console.log(`📦 Release location: ${path.relative(rootDir, releaseDir)}`);
    console.log(`📊 Total files: ${copied}`);
    
    //=-- Calculate release size
    let totalSize = 0;
    for (const file of filesToCopy) {
      const filePath = path.join(releaseDir, file);
      const stats = await fs.stat(filePath);
      totalSize += stats.size;
    }
    
    const sizeInMB = (totalSize / (1024 * 1024)).toFixed(2);
    console.log(`💾 Release size: ${sizeInMB} MB`);
    
  } catch (error) {
    console.error('❌ Release failed:', error);
    process.exit(1);
  }
}

//=-- Run the release
release().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
