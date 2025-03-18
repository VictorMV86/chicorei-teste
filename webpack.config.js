const path = require('path');

module.exports = {
  entry: './chicorei-teste/webpack.config.js', // Update this path
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};