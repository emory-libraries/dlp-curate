const { webpackConfig, merge } = require("@rails/webpacker")
const customConfig = {
  module: {
    rules: [
      {
        test: require.resolve("jquery"),
        loader: "expose-loader",
        options: {
          exposes: ["$", "jQuery", "jquery"]
        }
      },
      {
        test: require.resolve("popper.js"),
        loader: "expose-loader",
        options: {
          exposes: ["Popper"]
        }
      }
    ]
  },
  resolve: {
    extensions: ['.mjs', '.js', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg']
  }
}

module.exports = merge(webpackConfig, customConfig)
