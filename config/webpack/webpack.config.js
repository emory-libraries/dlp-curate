const { webpackConfig, merge } = require("shakapacker")
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
    extensions: ['.mjs', '.js', '.es6', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg']
  }
}

module.exports = merge(customConfig, webpackConfig)
