const path = require('path');

module.exports = {
  entry: './src/index.js', // Entry point
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
  target: 'node', // Ensure Webpack bundles for Node.js
  externals: {
    express: 'commonjs express', // Exclude express from the bundle
  },
};