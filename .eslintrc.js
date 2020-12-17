module.exports = {
  "parser": "@lightscript/eslint-plugin",
  "plugins": [
    "@lightscript/eslint-plugin",
    "react"
  ],
  "extends": [
    "plugin:@lightscript/recommended"
  ],
  "parserOptions": {
    "sourceType": "module"
  },
  "env": {
    "node": true,
    "es6": true
  },
  "globals": {
    "log": true,
    "Context": true
  }
}
