[
  import_deps: [:ash],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Ash.ResourceFormatter]
]
