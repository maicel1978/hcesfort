# Contributing to hcesfort

Thank you for considering a contribution. The package is at an early stage:
please open an issue before starting work on a pull request, so the change
can be placed in the [roadmap](docs/roadmap.md).

## Ground rules

- No survey microdata in the repository, in tests, examples or vignettes.
- The core knows no survey and no country. Survey adapters, food composition
  tables and national standards live outside this repository.
- Every reference value carries a source that can be opened and checked.
- Every core function validates its input, raises classed errors, checks the
  cardinality of its joins and counts each exclusion in the audit log.

## Workflow

1. Fork and create a branch.
2. Write the test first: minimal hand-built fixtures, with the expected result
   computed by hand inside the test; assert the class of every error.
3. Keep functions to 40 lines of body and files in `R/` to 300 lines (a test
   enforces both).
4. Run `devtools::document()`, `devtools::test()`, `lintr::lint_package()` and
   `devtools::check()` (0 errors, 0 warnings, 0 notes).
5. Add a line to `NEWS.md` for any user-visible change.

Code follows the [tidyverse style guide](https://style.tidyverse.org).

## Code of conduct

This project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md).
By participating you agree to abide by its terms.
