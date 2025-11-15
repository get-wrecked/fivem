import { defineConfig } from 'i18next-cli';

export default defineConfig({
    locales: [
        "en",
        "fr",
        "pt",
        "de",
        "es",
        "zh",
        "ja",
        "ko",
        "pr",
        "wd",
        "ar"
    ],
    extract: {
        input: "src/**/*.{js,jsx,ts,tsx}",
        output: "public\\locales\\{{language}}\\{{namespace}}.json"
    }
});
