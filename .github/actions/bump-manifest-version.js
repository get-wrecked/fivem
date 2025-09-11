import { readFile, writeFile } from 'node:fs/promises';

async function updateVersion() {
    try {
        const manifest = await readFile('./fxmanifest.lua', 'utf8');

        let version = process.env.TGT_RELEASE_VERSION;
        version = version.replace('v', '');

        const content = manifest.replace(/\bversion\s+(.*)$/gm, `version '${version}'`);

        await writeFile('./fxmanifest.lua', content);

        console.log(`Successfully updated version to ${version}`);
    } catch (error) {
        console.error('Error updating version:', error);
    }
}

updateVersion();
