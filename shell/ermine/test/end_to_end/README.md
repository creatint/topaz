# End to end product tests

End to end product tests for fuchsia products that contain ermine are located
here.

More end to end product tests for products in [`fuchsia.git`][1] are found in
[`//src/tests/end_to_end/`][2].

Unlike other kinds of tests, end to end product tests are specific to a product,
and therefore must not be included in the global `tests` build target mandated
by the [source tree layout][3]. Instead, end to end product tests are included
directly in the build configuration of their products in [//products][4].

[1]: https://fuchsia.googlesource.com/fuchsia/ "Fuchsia git repository"

[2]: https://fuchsia.googlesource.com/fuchsia/+/refs/heads/master/tests/end_to_end/
"Further end to end product tests in fuchsia"

[3]: https://fuchsia.googlesource.com/fuchsia/+/refs/heads/master/docs/development/source_code/layout.md#canonical-targets
"Fuchsia source tree layout specification"

[4] https://fuchsia.googlesource.com/fuchsia/+/refs/heads/master/products/
"Fuchsia product build specs"
