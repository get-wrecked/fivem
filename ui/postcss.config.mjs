const config = {
    plugins: {
        "@tailwindcss/postcss": {},
        "postcss-preset-env": {
            features: {
                "color-function": true,
                "color-mix": true
            },
            browsers: ["chrome 102"],
            stage: 0
        },
        "postcss-color-converter": {
            enableOklch: true,
            enableSrgb: true,
            outputColorFormat: "rgb"
        }
    },
};

export default config;