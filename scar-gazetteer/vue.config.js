module.exports = {
    publicPath: process.env.VUE_APP_PROXY_PATH || "/",
    chainWebpack: (config) => {
        config.plugin("html").tap((args) => {
            args[0].title = "SCAR Composite Gazetteer of Antarctica";
            return args;
        });
    },
    devServer: {
        proxy: {
            "^/api": {
                target: "http://localhost:3000",
                pathRewrite: { "^/api": "" },
            },
            "^/user/api": {
                target: "https://data.aad.gov.au",
            },
        },
    },
};
