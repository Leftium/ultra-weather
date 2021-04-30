// svelte.config.js
const sveltePreprocess = require('svelte-preprocess');

module.exports = {
  preprocess: sveltePreprocess({
    coffeescript: {
      bare: true
    }
  }),
  // ...other svelte options
};