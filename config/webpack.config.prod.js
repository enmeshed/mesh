const path = require('path');
const webpack = require('webpack');

const paths = {
  src: path.resolve(__dirname, '../packages'),
  output: path.resolve(__dirname, '../gitops/build'),
  modules: [path.resolve(__dirname, '../packages')]
};
paths.allCodePaths = [paths.src, ...paths.modules];

const nullModulePath = path.resolve(__dirname, 'null.js');
const throwModulePath = path.resolve(__dirname, 'throw.js');

const babelPreset = [
  '@lightscript',
  {
    env: { targets: { node: 10 } },
    stdlib: { lodash: false }
  }
]

const externalModules = {
  "@enmeshed/grpc": true,
  "@enmeshed/node-control-plane": true,
  "@enmeshed/protobuf": true,
  "@elastic/elasticsearch": true,
  "kafkajs": true,
  "mysql2": true,
  "mysql2/promise": true,
  "express": true,
  "jaeger-client": true,
  "ioredis": true,
  "bull": true
}

module.exports = {
  mode: 'production',
  target: 'node',
  watch: false,
  entry: {
    'bowser': path.resolve(paths.src, '@enmeshed/bowser/src/main.lsc'),
    'api': path.resolve(paths.src, '@test/api/index.lsc'),
    'worker_io': path.resolve(paths.src, '@test/worker_io/index.lsc')
  },
  devtool: 'source-map',
  output: {
    path: paths.output,
    filename: '[name].js'
  },
  optimization: {
    // Don't minify server code
    minimize: false
  },
  node: {
    __dirname: true,
    __filename: true
  },
  resolve: {
    modules: ['node_modules', ...paths.modules],
    extensions: ['.js', '.json', '.lsc'],
    alias: {
      hiredis: throwModulePath,
      WNdb: throwModulePath,
      lapack: throwModulePath
    }
  },
  module: {
    rules: [
      // Disable require.ensure as it's not a standard language feature.
      { parser: { requireEnsure: false } },
      // Lint
      // {
      //   test: /\.(js|jsx|lsc|lsx)$/,
      //   exclude: /node_modules/,
      //   enforce: 'pre',
      //   use: [
      //     {
      //       loader: require.resolve('eslint-loader'),
      //       options: {
      //         eslintPath: require.resolve('eslint'),
      //       },
      //     },
      //   ],
      //   include: paths.allCodePaths,
      // },
      // Compile JS
      {
        // "oneOf" will traverse all following loaders until one will
        // match the requirements. When no loader matches it will fall
        // back to the "file" loader at the end of the loader list.
        oneOf: [
          // Process application JS with Babel.
          // The preset includes JSX, Flow, and some ESnext features.
          {
            // LightScript
            test: /\.(js|lsc)$/,
            include: paths.allCodePaths,
            exclude: /node_modules/,
            loader: require.resolve('babel-loader'),
            options: {
              babelrc: false,

              presets: [ babelPreset ],

              // This is a feature of `babel-loader` for webpack (not Babel itself).
              // It enables caching results in ./node_modules/.cache/babel-loader/
              // directory for faster rebuilds.
              cacheDirectory: true,
              // Don't waste time on Gzipping the cache
              cacheCompression: false,
            },
          },
        ],
      },
    ]
  },
  plugins: [
    new webpack.DefinePlugin({
      'IS_BUILDING_WITH_WEBPACK': JSON.stringify(true)
    })
    // Don't let Kue bundle its http server, we don't want it
    // new webpack.NormalModuleReplacementPlugin(
    //   /kue\/lib\/http/,
    //   nullModulePath
    // ),
  ].filter(Boolean),
  externals: [
    function(context, request, callback) {
      if (externalModules[request]) {
        return callback(null, 'commonjs ' + request)
      }
      callback()
    }
  ]
}
