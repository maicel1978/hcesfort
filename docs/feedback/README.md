# Feedback log

One file per round of expert comments on the two report templates, named
`YYYY-MM-DD-round-N.csv`. A round is added when the comments arrive; none
has been received yet, so the log has no round files.

| Column | Content |
|---|---|
| `comment` | The comment, as received or summarised in one sentence. |
| `exhibit_id` | ID of `inst/report/exhibits.csv` that the comment cites (for example `R2.2`, `D4`). Empty when the comment is about the report as a whole. |
| `decision` | `accepted`, `rejected` or `deferred`. |
| `reason` | Why, in one sentence. Required for `rejected` and `deferred`. |
| `result` | Requirement ID, test or commit that resulted from an accepted comment. |

Reviewers are identified by role (for example "nutrition epidemiologist"),
never by name. The test `tests/testthat/test-feedback-log.R` checks the
columns, the values of `decision` and that every `exhibit_id` is in the
registry. It is skipped where `docs/` is absent (an installed package).
