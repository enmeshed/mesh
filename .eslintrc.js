module.exports = {
  "parser": "@lightscript/eslint-plugin",
  "plugins": ["@lightscript/eslint-plugin"],
  "extends": [
    "eslint:recommended",
    "plugin:@lightscript/recommended"
  ],
  "parserOptions": {
    "sourceType": "module"
  },
  "env": {
    "node": true,
    "es6": true
  },
  "rules": {
    "no-this-before-super": 0,
    "constructor-super": 0,
    "no-unreachable": 0
  },
  "globals": {
    "log": true,
    "Context": true
  }
}
