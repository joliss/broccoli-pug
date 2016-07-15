# broccoli-pug

`broccoli-pug` compiles or renders `pug` templates.

Because of Broccoli's design, this plugin is unable to resolve relative
imports to files outside of its input nodes. The workaround for this is to move
all relative imports into the input nodes (e.g. using `broccoli-funnel` and then
`broccoli-merge`). Note that imports must be in the same _input node_; it is not
sufficient to simply include imports as a separate input node. You can do this
by combining nodes using `broccoli-merge`.

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

# Contributing
I would love if anybody could contribute some tests to this repository. Feel free
to leave PRs, test or otherwise.

# License
Copyright 2016 Lehao Zhang. Released to the general public under the terms of
the ISC license.
