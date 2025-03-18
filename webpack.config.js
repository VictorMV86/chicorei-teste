const path = require('path');

module.exports = {
  entry: './src/index.js', // Entry
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};