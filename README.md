# broccoli-pug

`broccoli-pug` compiles or renders `pug` templates.

This plugin does NOT cache its output, and is thus rather slow on incremental
rebuilds. It is not production-ready.

Because of Broccoli's design, this plugin is unable to resolve relative
imports to files outside of its input nodes. The workaround for this is to move
all relative imports into the input nodes (e.g. using `broccoli-funnel`).

# Usage
```
var pug = require('broccoli-pug');
var html = pug([inputTree1, inputTree2], {
  render: true
  pugOptions: {
    // ...
  }
});
```

## `pug(inputs, options)`
`inputs` is an array of input Broccoli nodes.

`options` is an optional object specifying plugin options.

`options.render` is a boolean. If true, `broccoli-pug` will render templates to
HTML rather than compiling to a JS function.

`options.pugOptions` specifies options for the `pug` compiler. It is passed
directly to the compiler.

# License
Copyright 2016 Lehao Zhang. Released to the general public under the terms of
the ISC license.
