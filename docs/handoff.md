# Handoff

- **Date:** 2026-11-15
- **Model:** Fable, high effort (design note of step 12e.5).
- **Branch:** `claude/wonderful-ritchie-s1uc1z`, pushed. Documents only: no
  file of `R/`, `tests/`, `inst/` or `data-raw/` changed.
- **Environment:** run `R CMD INSTALL .` at the start (the Quarto render
  test uses the installed package).

## What was done

- `docs/design-12e5.md`: the design of step 12e.5 (P158 with P57, P159,
  P162, P163 with P69). It fixes the interfaces Opus implements, in eight
  steps (its section 6), and asks nine decisions (its section 7).
- `docs/improvements.md`: the maintainer's answers of 2026-11-15 recorded
  as R2-D1 to R2-D9; P158 reworded; P176 to P181 added; tasks of P57, P69,
  P159, P162 and P163 updated.
- `docs/roadmap.md`: 12e.5.0 ticked; 12e.5.1 to 12e.5.8 added.
- `devtools::test()` on the source tree: 48 files, 492 tests, 3,194
  expectations, 0 failures, 0 skipped. `devtools::check()` and the lint
  were not re-run (no code changed).

## The one thing to read first

**Finding 4 of the review v0.2 overstated the infant problem** (section 1.1
of the design). A breastfed infant eats none of the food recorded, but its
mother eats for it: FAO/WHO/UNU 2004, section 7.2, adds 505 to 675 kcal per
day to a lactating woman in the first six months. Today's AFE of a woman
with an infant (1.24) is inside the range the source gives (1.22 to 1.29).
Removing the infant without adding lactation, as the finding suggested,
would understate the AFE by about 0.24. The argument without default stays,
with a second one (`milk_energy_cost`); the value 1 stays defensible and is
recommended for ENGIH, with one sensitivity run.

## Answers of the maintainer (2026-11-15, design of 12e.5)

Approved by the maintainer: the nine decisions of section 7 of `docs/design-12e5.md`, all as recommended. They amend answers 3 and 5 of the review v0.2 (two arguments for infants; `fortifiable` used only when the call says `"use"`). `hces_example` gets an invented `fortifiable` column (false for own production); golden values and snapshots change and the change is recorded in `NEWS.md`. Order: 12e.1 to 12e.4, then 12e.5.1 to 12e.5.8, then A2. Record these in `docs/improvements.md` with the first commit of 12e.1.

## Exact next step

**12e.1 (P155, P156), Opus.** Read only: sections "Finding 1" and "Finding 2" of `docs/review-v0.2.md`, its section 8 (order of work), and the ids P155 and P156 in `docs/improvements.md`. Then 12e.2 in a new session (sections "Finding 6", "Finding 15", 5.3 and 5.4 of the review; P160, P169, P174).

## Open questions

None.

## Sources not obtained

No PDF was attached to this session. Opened online: FAO/WHO/UNU 2004
(chapters 3, 6 and 7), Aaron et al. 2017, Tang et al. 2021 (article text).
Not obtained (`# SOURCE PENDING`, P181): the supplement of Tang et al. 2021
(Table S3), Weisell and Dop 2012, Coates et al. 2017, the PAHO/WHO guiding
principles for complementary feeding (2003), and a national source of
infant feeding for the Dominican Republic. `pmc.ncbi.nlm.nih.gov` is now
reachable for article pages; its file downloads, `ncbi.nlm.nih.gov/books`
and the files of `iris.who.int` answer with a browser check;
`iris.paho.org` and `ebi.ac.uk` are outside the network.

## Recommended model for the next session

**Opus** for 12e.1, then 12e.2 and 12e.4. Sonnet for the text of 12e.3.
Opus for 12e.5.1 to 12e.5.8 after the approval. Fable only if a decision
of section 7 is answered against the recommendation and the design must
change.

## Maintainer review points

1. **The infant against the cost of lactation (section 1.1):**

   ```r
   library(hcesfort)
   ref <- reference_energy("female", 25, weight_kg = 55, pal = 1.76)
   m <- data.frame(household_id = 1, member_id = 1:2, age_years = c(25, 0),
                   sex = "female", age_months = c(NA, 2))
   adult_equivalents(m, ref, c(female = 55, male = 65), 1.76)$afe
   # 1.240: today's rule, the infant's own requirement
   1 + c(505, 675) / ref
   # 1.220 and 1.295: infant 0, lactation of FAO/WHO/UNU 2004
   c(807, 550) * 0.67 / 0.80
   # 675.9 and 460.6; the source prints 675 and 460
   ```

   Compare with section 7.2 of
   <https://www.fao.org/4/y5686e/y5686e0b.htm> ("807 g milk/day × 2.8
   kJ/g/0.80 efficiency = 2.8 MJ/day (675 kcal/day)"; "well-nourished
   women … 2.1 MJ/day (505 kcal/day)").

2. **The seven values of pregnancy and lactation (table of section 1.4):**
   85, 285, 475 and 360 kcal in section 6.3 of
   <https://www.fao.org/4/y5686e/y5686e0a.htm> (the paragraph after Table
   6.3); 505, 675 and 460 kcal in section 7.2 of the page above.

   ```r
   c(mean = mean(c(85, 285, 475)), over_280_days = 77000 / 280)
   # 281.7 and 275: two ways to one number when the trimester is unknown
   ```

3. **How much of each vehicle is own production in `hces_example`
   (section 2.4):** the size of what `fortifiable` would change there.

   ```r
   e <- hces_example
   g <- convert_units(e$acquisitions, e$unit_factors, priority = "food")
   v <- merge(as.data.frame(g), as.data.frame(e$vehicles), by = "food_code")
   v <- v[v$include & !is.na(v$qty_g_d), ]
   own <- v$origin == "own_production"
   round(tapply(v$qty_g_d * v$vehicle_fraction * own, v$vehicle, sum) /
           tapply(v$qty_g_d * v$vehicle_fraction, v$vehicle, sum), 3)
   # 0.052 (sugar) to 0.070 (maize flour)
   ```
