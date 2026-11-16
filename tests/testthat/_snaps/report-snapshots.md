# exhibits of the readiness report, en (Q1)

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D1] Table D1. Verdict: sections and domains the data support
      
      section | national | region | area | expenditure_group
      Coverage of the vehicles | enabled | enabled | enabled | enabled
      Quantity among acquirers | enabled | enabled | enabled | enabled
      Risk of inadequate apparent intake | enabled | enabled | enabled | enabled
      Fortification scenarios | enabled | enabled | enabled | enabled
      Contribution of each food group | enabled | enabled | enabled | enabled
      The data support these sections of the results report: Coverage of the vehicles, Quantity among acquirers, Risk of inadequate apparent intake, Fortification scenarios and Contribution of each food group.
      Each of them can also be reported by region, area and expenditure quintile.
      Every section is supported nationally and by every domain.
      Left to do: link 44 foods, which hold 3.4% of the included grams and 2.4% of the included expenditure.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D2] Table D2. Variables: essential, and optional ones absent or partly missing
      
      table | variable | role | present | share_missing | needed_by
      households | household_id | essential | yes | 0.0 | all sections
      households | weight | essential | yes | 0.0 | all sections
      households | stratum | essential | yes | 0.0 | all sections
      households | psu | essential | yes | 0.0 | all sections
      members | household_id | essential | yes | 0.0 | all sections
      members | member_id | essential | yes | 0.0 | all sections
      members | age_years | essential | yes | 0.3 | all sections
      members | sex | essential | yes | 0.2 | all sections
      members | age_months | optional | no |  NA | adult female equivalents
      members | meals_home_share | optional | no |  NA | adult female equivalents
      members | weight_kg | optional | no |  NA | adult female equivalents
      acquisitions | record_id | essential | yes | 0.0 | all sections
      acquisitions | household_id | essential | yes | 0.0 | all sections
      acquisitions | food_code | essential | yes | 0.0 | all sections
      acquisitions | quantity | essential | yes | 0.3 | all sections
      acquisitions | unit | essential | yes | 0.2 | all sections
      acquisitions | section | essential | yes | 0.0 | all sections
      acquisitions | period_days | essential | yes | 0.0 | all sections
      acquisitions | include | essential | yes | 0.0 | all sections
      acquisitions | household_share | optional | no |  NA | quantities of each household
      households | expenditure_group | optional | yes | 1.6 | analysis by expenditure quintile
      unit_factors | NA | essential | yes |  NA | all sections
      crosswalk | NA | essential | yes |  NA | all sections
      composition | NA | essential | yes |  NA | all sections
      Optional variables present and complete are listed only in Table DA1.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D3] Table D3. Minimum quantity and quality of the data
      
      check | detail | n | value | threshold | met
      Households by status | Food module non-response |    31 |   1.6 | NA | NA
      Households by status | No food records |     5 |   0.2 | NA | NA
      Households by status | All records lost |     0 |   0.0 | NA | NA
      Households by status | No adult female equivalents |    36 |   1.8 | NA | NA
      Households by status | With an estimate |  1928 |  96.4 | NA | NA
      Records without quantity or unit | NA |   218 |   0.5 | NA | NA
      Records without grams | NA |   314 |   0.7 | NA | NA
      Included records used | NA | 42743 |  95.6 | 80 | yes
      Edible grams with a composition value | Iron |    NA | 100.0 | 80 | yes
      Edible grams with a composition value | Zinc |    NA | 100.0 | 80 | yes
      Edible grams with a composition value | Folate |    NA |  99.4 | 80 | yes
      Edible grams with a composition value | Vitamin A |    NA | 100.0 | 80 | yes
      Grams linked to composition | NA | 42743 |  96.6 | 90 | yes
      Expenditure linked to composition | NA | 42743 |  97.6 | 90 | yes
      Values of the domain with few households | Region |     3 |   0.0 | 50 | yes
      Values of the domain with few households | Area |     2 |   0.0 | 50 | yes
      Values of the domain with few households | Expenditure quintile |     6 |  16.7 | 50 | yes

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D4] Table D4. Linkage ladder
      
      step | n_records | n_households | share_records | share_grams | share_expenditure
      Included records | 44708 | 1964 | 100.0 |    NA | 100.0
      With quantity and unit | 44490 | 1964 |  99.5 |    NA |  99.5
      Converted to grams | 44394 | 1964 |  99.3 | 100.0 |  99.2
      Matched to composition | 44224 | 1964 |  98.9 | 100.0 |  99.1
      Linked (validated match, edible portion) | 42743 | 1964 |  95.6 |  96.6 |  97.6
      Records left out by the inclusion rule of the adapter: 234.
      Included records without expenditure, left out of the expenditure shares: 0.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D5] Table D5. Work queue: foods to resolve, by the share they hold
      
      rank | food_code | reasons | units_no_grams | n_not_linked | share_grams | share_expenditure | cum_share_grams | cum_share_expenditure
       1 | banana | quantity missing; unit missing; edible portion missing | piece | 1174 | 3.2 | 1.4 |  99.8 |  99.0
       2 | leafy_greens | quantity missing; match not validated | bunch |  317 | 0.2 | 0.2 | 100.0 |  99.1
       3 | local_herb | quantity missing; no composition match | bunch |  171 | 0.0 | 0.1 | 100.0 |  99.2
       4 | milk_fresh | quantity missing; unit missing; no density | cup |   45 |  NA | 0.2 | 100.0 |  99.4
       5 | onion | quantity missing; unit missing; no unit factor | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.4
       6 | sugar | quantity missing; unit missing; no unit factor | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.5
       7 | coffee | quantity missing; unit missing; no unit factor | lb; sack |   13 |  NA | 0.0 | 100.0 |  99.5
       8 | vegetable_oil | quantity missing; unit missing | l |   13 |  NA | 0.0 | 100.0 |  99.5
       9 | pasta | quantity missing; unit missing | g |   12 |  NA | 0.0 | 100.0 |  99.6
      10 | rice | quantity missing; unit missing; no unit factor | lb; sack |   12 |  NA | 0.1 | 100.0 |  99.6
      11 | salt | quantity missing; unit missing; no unit factor | lb; sack |   12 |  NA | 0.0 | 100.0 |  99.6
      12 | milk_powder | quantity missing; unit missing | g |    9 |  NA | 0.1 | 100.0 |  99.7
      13 | plantain | quantity missing; unit missing | piece |    9 |  NA | 0.0 | 100.0 |  99.7
      14 | wheat_flour | quantity missing; unit missing; no unit factor | lb; sack |    9 |  NA | 0.0 | 100.0 |  99.7
      15 | beef | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.7
      16 | cheese | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      17 | chicken | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      18 | pumpkin | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      19 | tomato | quantity missing; no unit factor | lb; sack |    7 |  NA | 0.0 | 100.0 |  99.8
      20 | carrot | quantity missing; unit missing | lb |    6 |  NA | 0.0 | 100.0 |  99.8
      21 | egg | quantity missing; unit missing | piece |    6 |  NA | 0.0 | 100.0 |  99.8
      22 | fish_fresh | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      23 | papaya | quantity missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      24 | red_beans | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      25 | sweet_pepper | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      26 | bread | quantity missing; unit missing | piece |    5 |  NA | 0.0 | 100.0 |  99.9
      27 | evaporated_milk | quantity missing; unit missing | can |    5 |  NA | 0.0 | 100.0 |  99.9
      28 | salami | quantity missing; unit missing; no unit factor | lb; sack |    5 |  NA | 0.0 | 100.0 |  99.9
      29 | avocado | quantity missing; unit missing | piece |    4 |  NA | 0.0 | 100.0 |  99.9
      30 | garlic | quantity missing; unit missing; no unit factor | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      31 | maize_flour | quantity missing | lb |    4 |  NA | 0.0 | 100.0 |  99.9
      32 | pigeon_peas | unit missing; no unit factor | sack |    4 |  NA | 0.0 | 100.0 |  99.9
      33 | potato | quantity missing; unit missing; no unit factor | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      34 | breakfast_cereal | quantity missing; unit missing | g |    3 |  NA | 0.0 | 100.0 | 100.0
      35 | cabbage | quantity missing; unit missing | lb |    3 |  NA | 0.0 | 100.0 | 100.0
      36 | mango | unit missing | NA |    3 |  NA | 0.0 | 100.0 | 100.0
      37 | pork | unit missing; no unit factor | sack |    3 |  NA | 0.0 | 100.0 | 100.0
      38 | sausage | quantity missing; no unit factor | lb; sack |    3 |  NA | 0.0 | 100.0 | 100.0
      39 | biscuit | quantity missing | g |    2 |  NA | 0.0 | 100.0 | 100.0
      40 | cassava | quantity missing | lb; sack |    2 |  NA | 0.0 | 100.0 | 100.0
      41 | orange | quantity missing; unit missing | piece |    2 |  NA | 0.0 | 100.0 | 100.0
      42 | soft_drink | quantity missing; unit missing | l |    2 |  NA | 0.0 | 100.0 | 100.0
      43 | oats | no unit factor | sack |    1 |  NA | 0.0 | 100.0 | 100.0
      44 | sardines_canned | quantity missing | can |    1 |  NA | 0.0 | 100.0 | 100.0

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D6] Figure D6. Share linked as the foods of the queue are resolved, %
      
      rank | food_code | reasons | units_no_grams | n_not_linked | share_grams | share_expenditure | cum_share_grams | cum_share_expenditure
       1 | banana | quantity missing; unit missing; edible portion missing | piece | 1174 | 3.2 | 1.4 |  99.8 |  99.0
       2 | leafy_greens | quantity missing; match not validated | bunch |  317 | 0.2 | 0.2 | 100.0 |  99.1
       3 | local_herb | quantity missing; no composition match | bunch |  171 | 0.0 | 0.1 | 100.0 |  99.2
       4 | milk_fresh | quantity missing; unit missing; no density | cup |   45 |  NA | 0.2 | 100.0 |  99.4
       5 | onion | quantity missing; unit missing; no unit factor | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.4
       6 | sugar | quantity missing; unit missing; no unit factor | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.5
       7 | coffee | quantity missing; unit missing; no unit factor | lb; sack |   13 |  NA | 0.0 | 100.0 |  99.5
       8 | vegetable_oil | quantity missing; unit missing | l |   13 |  NA | 0.0 | 100.0 |  99.5
       9 | pasta | quantity missing; unit missing | g |   12 |  NA | 0.0 | 100.0 |  99.6
      10 | rice | quantity missing; unit missing; no unit factor | lb; sack |   12 |  NA | 0.1 | 100.0 |  99.6
      11 | salt | quantity missing; unit missing; no unit factor | lb; sack |   12 |  NA | 0.0 | 100.0 |  99.6
      12 | milk_powder | quantity missing; unit missing | g |    9 |  NA | 0.1 | 100.0 |  99.7
      13 | plantain | quantity missing; unit missing | piece |    9 |  NA | 0.0 | 100.0 |  99.7
      14 | wheat_flour | quantity missing; unit missing; no unit factor | lb; sack |    9 |  NA | 0.0 | 100.0 |  99.7
      15 | beef | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.7
      16 | cheese | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      17 | chicken | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      18 | pumpkin | quantity missing; unit missing; no unit factor | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      19 | tomato | quantity missing; no unit factor | lb; sack |    7 |  NA | 0.0 | 100.0 |  99.8
      20 | carrot | quantity missing; unit missing | lb |    6 |  NA | 0.0 | 100.0 |  99.8
      21 | egg | quantity missing; unit missing | piece |    6 |  NA | 0.0 | 100.0 |  99.8
      22 | fish_fresh | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      23 | papaya | quantity missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      24 | red_beans | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      25 | sweet_pepper | quantity missing; unit missing; no unit factor | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      26 | bread | quantity missing; unit missing | piece |    5 |  NA | 0.0 | 100.0 |  99.9
      27 | evaporated_milk | quantity missing; unit missing | can |    5 |  NA | 0.0 | 100.0 |  99.9
      28 | salami | quantity missing; unit missing; no unit factor | lb; sack |    5 |  NA | 0.0 | 100.0 |  99.9
      29 | avocado | quantity missing; unit missing | piece |    4 |  NA | 0.0 | 100.0 |  99.9
      30 | garlic | quantity missing; unit missing; no unit factor | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      31 | maize_flour | quantity missing | lb |    4 |  NA | 0.0 | 100.0 |  99.9
      32 | pigeon_peas | unit missing; no unit factor | sack |    4 |  NA | 0.0 | 100.0 |  99.9
      33 | potato | quantity missing; unit missing; no unit factor | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      34 | breakfast_cereal | quantity missing; unit missing | g |    3 |  NA | 0.0 | 100.0 | 100.0
      35 | cabbage | quantity missing; unit missing | lb |    3 |  NA | 0.0 | 100.0 | 100.0
      36 | mango | unit missing | NA |    3 |  NA | 0.0 | 100.0 | 100.0
      37 | pork | unit missing; no unit factor | sack |    3 |  NA | 0.0 | 100.0 | 100.0
      38 | sausage | quantity missing; no unit factor | lb; sack |    3 |  NA | 0.0 | 100.0 | 100.0
      39 | biscuit | quantity missing | g |    2 |  NA | 0.0 | 100.0 | 100.0
      40 | cassava | quantity missing | lb; sack |    2 |  NA | 0.0 | 100.0 | 100.0
      41 | orange | quantity missing; unit missing | piece |    2 |  NA | 0.0 | 100.0 | 100.0
      42 | soft_drink | quantity missing; unit missing | l |    2 |  NA | 0.0 | 100.0 | 100.0
      43 | oats | no unit factor | sack |    1 |  NA | 0.0 | 100.0 | 100.0
      44 | sardines_canned | quantity missing | can |    1 |  NA | 0.0 | 100.0 | 100.0
      Dashed line: the share of the stopping rule.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D7] Table D7. Stopping rule and unlinked share, % (95% CI)
      
      Rule: link at least 90% of the included grams and of the included expenditure. The rule is met.
      measure | n | unlinked | ci_low | ci_high
      Grams | 2000 | 3.4 | 3.3 | 3.6
      Expenditure | 2000 | 2.4 | 2.3 | 2.6
      n = 2,000 households

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D8_area] Table D8. Unlinked share by area, % (95% CI)
      
      domain_value | measure | n | unlinked | ci_low | ci_high | rest | difference | difference_ci_low | difference_ci_high | differs
      Rural | Grams |  870 | 3.2 | 2.9 | 3.5 | 3.7 | -0.5 | -0.9 | -0.2 | yes
      Urban | Grams | 1130 | 3.7 | 3.5 | 3.9 | 3.2 |  0.5 |  0.2 |  0.9 | yes
      Rural | Expenditure |  870 | 2.4 | 2.1 | 2.7 | 2.5 | -0.1 | -0.4 |  0.3 | no
      Urban | Expenditure | 1130 | 2.5 | 2.3 | 2.7 | 2.4 |  0.1 | -0.3 |  0.4 | no
      A value differs when the 95% CI of the difference excludes zero, without adjustment for multiple comparisons.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D8_expenditure_group] Table D8. Unlinked share by expenditure quintile, % (95% CI)
      
      domain_value | measure | n | unlinked | ci_low | ci_high | rest | difference | difference_ci_low | difference_ci_high | differs
      Q1 (lowest expenditure) | Grams | 354 | 3.2 | 2.8 | 3.7 | 3.5 | -0.3 | -0.8 | 0.2 | no
      Q2 | Grams | 382 | 3.1 | 2.6 | 3.6 | 3.5 | -0.4 | -1.0 | 0.1 | no
      Q3 | Grams | 395 | 3.4 | 3.1 | 3.8 | 3.4 |  0.0 | -0.4 | 0.4 | no
      Q4 | Grams | 404 | 3.4 | 3.1 | 3.8 | 3.4 |  0.0 | -0.4 | 0.3 | no
      Q5 (highest expenditure) | Grams | 434 | 3.9 | 3.6 | 4.3 | 3.3 |  0.6 |  0.2 | 1.0 | yes
      No data | Grams |  31 |  NA |  NA |  NA | 3.4 |   NA |   NA |  NA | NA
      Q1 (lowest expenditure) | Expenditure | 354 | 2.1 | 1.8 | 2.5 | 2.5 | -0.3 | -0.7 | 0.0 | yes
      Q2 | Expenditure | 382 | 2.4 | 2.1 | 2.7 | 2.4 |  0.0 | -0.4 | 0.3 | no
      Q3 | Expenditure | 395 | 2.5 | 2.1 | 2.9 | 2.4 |  0.1 | -0.4 | 0.5 | no
      Q4 | Expenditure | 404 | 2.4 | 2.1 | 2.7 | 2.4 | -0.1 | -0.4 | 0.3 | no
      Q5 (highest expenditure) | Expenditure | 434 | 2.6 | 2.3 | 3.0 | 2.4 |  0.3 | -0.1 | 0.6 | no
      No data | Expenditure |  31 |  NA |  NA |  NA | 2.4 |   NA |   NA |  NA | NA
      A value differs when the 95% CI of the difference excludes zero, without adjustment for multiple comparisons.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D9] Figure D9. Apparent energy intake per adult female equivalent, kcal per day
      
      Median apparent energy intake: 2,329 kcal per adult female equivalent per day (95% CI 2,273 to 2,392), 101.7% of the energy of the reference person (2,291 kcal). Households outside the plausible range (500 to 6,000 kcal): 1.8% (95% CI 1.2 to 2.6).
      n | median | ci_low | ci_high | pct_reference | outside | outside_ci_low | outside_ci_high
      1928 | 2329 | 2273 | 2392 | 101.7 | 1.8 | 1.2 | 2.6
      n = 1,928 households
      Dashed lines: the plausible range; solid line: the energy of the reference person.
      9 households above 6,000 kcal, not shown.
      The 33 households outside the plausible range are left out of the results report (choice `energy_action`, Table D10).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D10] Table D10. Decisions taken with the data
      
      decision | choice | evidence
      Source of the unit conversion factors | Unit factors of hces_example, invented for the example | Linkage ladder: records converted to grams
      Composition table | Composition of hces_example, invented; added nutrients of enriched foods removed to obtain the unfortified baseline | Linkage ladder and work queue
      Outlier rule | No rule applied in this example | No acquisition was flagged or excluded
      Day divisor | period_days of each record, the reference period of its module | Variable inventory: period_days present
      Imputation | None | Records without quantity, unit or grams are left out and counted in the linkage ladder
      Households with implausible apparent energy | Left out of the results (energy_action = "exclude"): an apparent energy outside the plausible range points to recording errors, such as stored purchases or food given away, and such households can drive an estimate above the upper level | Readiness report, section 7 (Figure D9): households outside the range

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [DA1] Table DA1. Inventory of variables
      
      table | variable | role | present | share_missing | needed_by
      households | household_id | essential | yes | 0.0 | all sections
      households | weight | essential | yes | 0.0 | all sections
      households | stratum | essential | yes | 0.0 | all sections
      households | psu | essential | yes | 0.0 | all sections
      households | food_module_response | optional | yes | 0.0 | status of each household
      members | household_id | essential | yes | 0.0 | all sections
      members | member_id | essential | yes | 0.0 | all sections
      members | age_years | essential | yes | 0.3 | all sections
      members | sex | essential | yes | 0.2 | all sections
      members | age_months | optional | no |  NA | adult female equivalents
      members | pregnant | optional | yes | 0.0 | adult female equivalents
      members | lactating | optional | yes | 0.0 | adult female equivalents
      members | meals_home_share | optional | no |  NA | adult female equivalents
      members | weight_kg | optional | no |  NA | adult female equivalents
      acquisitions | record_id | essential | yes | 0.0 | all sections
      acquisitions | household_id | essential | yes | 0.0 | all sections
      acquisitions | food_code | essential | yes | 0.0 | all sections
      acquisitions | quantity | essential | yes | 0.3 | all sections
      acquisitions | unit | essential | yes | 0.2 | all sections
      acquisitions | section | essential | yes | 0.0 | all sections
      acquisitions | period_days | essential | yes | 0.0 | all sections
      acquisitions | include | essential | yes | 0.0 | all sections
      acquisitions | origin | optional | yes | 0.0 | none
      acquisitions | household_share | optional | no |  NA | quantities of each household
      acquisitions | expenditure_lcu | optional | yes | 0.0 | linkage by expenditure
      households | region | optional | yes | 0.0 | analysis by region
      households | area | optional | yes | 0.0 | analysis by area
      households | expenditure_group | optional | yes | 1.6 | analysis by expenditure quintile
      unit_factors | NA | essential | yes |  NA | all sections
      crosswalk | NA | essential | yes |  NA | all sections
      composition | NA | essential | yes |  NA | all sections
      enrichment | NA | optional | yes |  NA | unfortified baseline
      vehicles | NA | optional | yes |  NA | Coverage of the vehicles, Quantity among acquirers and Fortification scenarios
      scenarios | NA | optional | yes |  NA | Fortification scenarios
      food_groups | NA | optional | yes |  NA | Contribution of each food group

# exhibits of the readiness report, es (Q1)

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D1] Cuadro D1. Veredicto: secciones y dominios que los datos permiten
      
      section | national | region | area | expenditure_group
      Cobertura de los vehículos | habilitada | habilitada | habilitada | habilitada
      Cantidad entre quienes adquieren | habilitada | habilitada | habilitada | habilitada
      Riesgo de ingesta aparente inadecuada | habilitada | habilitada | habilitada | habilitada
      Escenarios de fortificación | habilitada | habilitada | habilitada | habilitada
      Aporte de cada grupo de alimentos | habilitada | habilitada | habilitada | habilitada
      Los datos permiten estas secciones del informe de resultados: Cobertura de los vehículos, Cantidad entre quienes adquieren, Riesgo de ingesta aparente inadecuada, Escenarios de fortificación y Aporte de cada grupo de alimentos.
      Cada una puede informarse también por región, área y quintil de gasto.
      Todas las secciones se permiten a nivel nacional y en todos los dominios.
      Falta por hacer: vincular 44 alimentos, que representan el 3.4% de los gramos incluidos y el 2.4% del gasto incluido.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D2] Cuadro D2. Variables: esenciales, y opcionales ausentes o con faltantes
      
      table | variable | role | present | share_missing | needed_by
      households | household_id | esencial | sí | 0.0 | todas las secciones
      households | weight | esencial | sí | 0.0 | todas las secciones
      households | stratum | esencial | sí | 0.0 | todas las secciones
      households | psu | esencial | sí | 0.0 | todas las secciones
      members | household_id | esencial | sí | 0.0 | todas las secciones
      members | member_id | esencial | sí | 0.0 | todas las secciones
      members | age_years | esencial | sí | 0.3 | todas las secciones
      members | sex | esencial | sí | 0.2 | todas las secciones
      members | age_months | opcional | no |  NA | equivalentes de mujer adulta
      members | meals_home_share | opcional | no |  NA | equivalentes de mujer adulta
      members | weight_kg | opcional | no |  NA | equivalentes de mujer adulta
      acquisitions | record_id | esencial | sí | 0.0 | todas las secciones
      acquisitions | household_id | esencial | sí | 0.0 | todas las secciones
      acquisitions | food_code | esencial | sí | 0.0 | todas las secciones
      acquisitions | quantity | esencial | sí | 0.3 | todas las secciones
      acquisitions | unit | esencial | sí | 0.2 | todas las secciones
      acquisitions | section | esencial | sí | 0.0 | todas las secciones
      acquisitions | period_days | esencial | sí | 0.0 | todas las secciones
      acquisitions | include | esencial | sí | 0.0 | todas las secciones
      acquisitions | household_share | opcional | no |  NA | cantidades de cada hogar
      households | expenditure_group | opcional | sí | 1.6 | análisis por quintil de gasto
      unit_factors | NA | esencial | sí |  NA | todas las secciones
      crosswalk | NA | esencial | sí |  NA | todas las secciones
      composition | NA | esencial | sí |  NA | todas las secciones
      Las variables opcionales presentes y completas solo aparecen en el Cuadro DA1.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D3] Cuadro D3. Cantidad y calidad mínimas de los datos
      
      check | detail | n | value | threshold | met
      Hogares por estado | No respuesta al módulo de alimentos |    31 |   1.6 | NA | NA
      Hogares por estado | Sin registros de alimentos |     5 |   0.2 | NA | NA
      Hogares por estado | Todos los registros perdidos |     0 |   0.0 | NA | NA
      Hogares por estado | Sin equivalentes de mujer adulta |    36 |   1.8 | NA | NA
      Hogares por estado | Con estimación |  1928 |  96.4 | NA | NA
      Registros sin cantidad o unidad | NA |   218 |   0.5 | NA | NA
      Registros sin gramos | NA |   314 |   0.7 | NA | NA
      Registros incluidos utilizados | NA | 42743 |  95.6 | 80 | sí
      Gramos comestibles con valor de composición | Hierro |    NA | 100.0 | 80 | sí
      Gramos comestibles con valor de composición | Zinc |    NA | 100.0 | 80 | sí
      Gramos comestibles con valor de composición | Folato |    NA |  99.4 | 80 | sí
      Gramos comestibles con valor de composición | Vitamina A |    NA | 100.0 | 80 | sí
      Gramos vinculados a la composición | NA | 42743 |  96.6 | 90 | sí
      Gasto vinculado a la composición | NA | 42743 |  97.6 | 90 | sí
      Valores del dominio con pocos hogares | Región |     3 |   0.0 | 50 | sí
      Valores del dominio con pocos hogares | Área |     2 |   0.0 | 50 | sí
      Valores del dominio con pocos hogares | Quintil de gasto |     6 |  16.7 | 50 | sí

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D4] Cuadro D4. Escalera de vinculación
      
      step | n_records | n_households | share_records | share_grams | share_expenditure
      Registros incluidos | 44708 | 1964 | 100.0 |    NA | 100.0
      Con cantidad y unidad | 44490 | 1964 |  99.5 |    NA |  99.5
      Convertidos a gramos | 44394 | 1964 |  99.3 | 100.0 |  99.2
      Emparejados con la composición | 44224 | 1964 |  98.9 | 100.0 |  99.1
      Vinculados (emparejamiento validado, porción comestible) | 42743 | 1964 |  95.6 |  96.6 |  97.6
      Registros excluidos por la regla de inclusión del adaptador: 234.
      Registros incluidos sin gasto, excluidos de las proporciones de gasto: 0.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D5] Cuadro D5. Cola de trabajo: alimentos por resolver, según la proporción que representan
      
      rank | food_code | reasons | units_no_grams | n_not_linked | share_grams | share_expenditure | cum_share_grams | cum_share_expenditure
       1 | banana | falta la cantidad; falta la unidad; falta la porción comestible | piece | 1174 | 3.2 | 1.4 |  99.8 |  99.0
       2 | leafy_greens | falta la cantidad; emparejamiento no validado | bunch |  317 | 0.2 | 0.2 | 100.0 |  99.1
       3 | local_herb | falta la cantidad; sin emparejamiento en la composición | bunch |  171 | 0.0 | 0.1 | 100.0 |  99.2
       4 | milk_fresh | falta la cantidad; falta la unidad; sin densidad | cup |   45 |  NA | 0.2 | 100.0 |  99.4
       5 | onion | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.4
       6 | sugar | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.5
       7 | coffee | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   13 |  NA | 0.0 | 100.0 |  99.5
       8 | vegetable_oil | falta la cantidad; falta la unidad | l |   13 |  NA | 0.0 | 100.0 |  99.5
       9 | pasta | falta la cantidad; falta la unidad | g |   12 |  NA | 0.0 | 100.0 |  99.6
      10 | rice | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   12 |  NA | 0.1 | 100.0 |  99.6
      11 | salt | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   12 |  NA | 0.0 | 100.0 |  99.6
      12 | milk_powder | falta la cantidad; falta la unidad | g |    9 |  NA | 0.1 | 100.0 |  99.7
      13 | plantain | falta la cantidad; falta la unidad | piece |    9 |  NA | 0.0 | 100.0 |  99.7
      14 | wheat_flour | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    9 |  NA | 0.0 | 100.0 |  99.7
      15 | beef | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.7
      16 | cheese | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      17 | chicken | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      18 | pumpkin | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      19 | tomato | falta la cantidad; sin factor de unidad | lb; sack |    7 |  NA | 0.0 | 100.0 |  99.8
      20 | carrot | falta la cantidad; falta la unidad | lb |    6 |  NA | 0.0 | 100.0 |  99.8
      21 | egg | falta la cantidad; falta la unidad | piece |    6 |  NA | 0.0 | 100.0 |  99.8
      22 | fish_fresh | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      23 | papaya | falta la cantidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      24 | red_beans | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      25 | sweet_pepper | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      26 | bread | falta la cantidad; falta la unidad | piece |    5 |  NA | 0.0 | 100.0 |  99.9
      27 | evaporated_milk | falta la cantidad; falta la unidad | can |    5 |  NA | 0.0 | 100.0 |  99.9
      28 | salami | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    5 |  NA | 0.0 | 100.0 |  99.9
      29 | avocado | falta la cantidad; falta la unidad | piece |    4 |  NA | 0.0 | 100.0 |  99.9
      30 | garlic | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      31 | maize_flour | falta la cantidad | lb |    4 |  NA | 0.0 | 100.0 |  99.9
      32 | pigeon_peas | falta la unidad; sin factor de unidad | sack |    4 |  NA | 0.0 | 100.0 |  99.9
      33 | potato | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      34 | breakfast_cereal | falta la cantidad; falta la unidad | g |    3 |  NA | 0.0 | 100.0 | 100.0
      35 | cabbage | falta la cantidad; falta la unidad | lb |    3 |  NA | 0.0 | 100.0 | 100.0
      36 | mango | falta la unidad | NA |    3 |  NA | 0.0 | 100.0 | 100.0
      37 | pork | falta la unidad; sin factor de unidad | sack |    3 |  NA | 0.0 | 100.0 | 100.0
      38 | sausage | falta la cantidad; sin factor de unidad | lb; sack |    3 |  NA | 0.0 | 100.0 | 100.0
      39 | biscuit | falta la cantidad | g |    2 |  NA | 0.0 | 100.0 | 100.0
      40 | cassava | falta la cantidad | lb; sack |    2 |  NA | 0.0 | 100.0 | 100.0
      41 | orange | falta la cantidad; falta la unidad | piece |    2 |  NA | 0.0 | 100.0 | 100.0
      42 | soft_drink | falta la cantidad; falta la unidad | l |    2 |  NA | 0.0 | 100.0 | 100.0
      43 | oats | sin factor de unidad | sack |    1 |  NA | 0.0 | 100.0 | 100.0
      44 | sardines_canned | falta la cantidad | can |    1 |  NA | 0.0 | 100.0 | 100.0

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D6] Figura D6. Proporción vinculada a medida que se resuelven los alimentos de la cola, %
      
      rank | food_code | reasons | units_no_grams | n_not_linked | share_grams | share_expenditure | cum_share_grams | cum_share_expenditure
       1 | banana | falta la cantidad; falta la unidad; falta la porción comestible | piece | 1174 | 3.2 | 1.4 |  99.8 |  99.0
       2 | leafy_greens | falta la cantidad; emparejamiento no validado | bunch |  317 | 0.2 | 0.2 | 100.0 |  99.1
       3 | local_herb | falta la cantidad; sin emparejamiento en la composición | bunch |  171 | 0.0 | 0.1 | 100.0 |  99.2
       4 | milk_fresh | falta la cantidad; falta la unidad; sin densidad | cup |   45 |  NA | 0.2 | 100.0 |  99.4
       5 | onion | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.4
       6 | sugar | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   17 |  NA | 0.0 | 100.0 |  99.5
       7 | coffee | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   13 |  NA | 0.0 | 100.0 |  99.5
       8 | vegetable_oil | falta la cantidad; falta la unidad | l |   13 |  NA | 0.0 | 100.0 |  99.5
       9 | pasta | falta la cantidad; falta la unidad | g |   12 |  NA | 0.0 | 100.0 |  99.6
      10 | rice | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   12 |  NA | 0.1 | 100.0 |  99.6
      11 | salt | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |   12 |  NA | 0.0 | 100.0 |  99.6
      12 | milk_powder | falta la cantidad; falta la unidad | g |    9 |  NA | 0.1 | 100.0 |  99.7
      13 | plantain | falta la cantidad; falta la unidad | piece |    9 |  NA | 0.0 | 100.0 |  99.7
      14 | wheat_flour | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    9 |  NA | 0.0 | 100.0 |  99.7
      15 | beef | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.7
      16 | cheese | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      17 | chicken | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      18 | pumpkin | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    8 |  NA | 0.0 | 100.0 |  99.8
      19 | tomato | falta la cantidad; sin factor de unidad | lb; sack |    7 |  NA | 0.0 | 100.0 |  99.8
      20 | carrot | falta la cantidad; falta la unidad | lb |    6 |  NA | 0.0 | 100.0 |  99.8
      21 | egg | falta la cantidad; falta la unidad | piece |    6 |  NA | 0.0 | 100.0 |  99.8
      22 | fish_fresh | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      23 | papaya | falta la cantidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      24 | red_beans | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      25 | sweet_pepper | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    6 |  NA | 0.0 | 100.0 |  99.9
      26 | bread | falta la cantidad; falta la unidad | piece |    5 |  NA | 0.0 | 100.0 |  99.9
      27 | evaporated_milk | falta la cantidad; falta la unidad | can |    5 |  NA | 0.0 | 100.0 |  99.9
      28 | salami | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    5 |  NA | 0.0 | 100.0 |  99.9
      29 | avocado | falta la cantidad; falta la unidad | piece |    4 |  NA | 0.0 | 100.0 |  99.9
      30 | garlic | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      31 | maize_flour | falta la cantidad | lb |    4 |  NA | 0.0 | 100.0 |  99.9
      32 | pigeon_peas | falta la unidad; sin factor de unidad | sack |    4 |  NA | 0.0 | 100.0 |  99.9
      33 | potato | falta la cantidad; falta la unidad; sin factor de unidad | lb; sack |    4 |  NA | 0.0 | 100.0 |  99.9
      34 | breakfast_cereal | falta la cantidad; falta la unidad | g |    3 |  NA | 0.0 | 100.0 | 100.0
      35 | cabbage | falta la cantidad; falta la unidad | lb |    3 |  NA | 0.0 | 100.0 | 100.0
      36 | mango | falta la unidad | NA |    3 |  NA | 0.0 | 100.0 | 100.0
      37 | pork | falta la unidad; sin factor de unidad | sack |    3 |  NA | 0.0 | 100.0 | 100.0
      38 | sausage | falta la cantidad; sin factor de unidad | lb; sack |    3 |  NA | 0.0 | 100.0 | 100.0
      39 | biscuit | falta la cantidad | g |    2 |  NA | 0.0 | 100.0 | 100.0
      40 | cassava | falta la cantidad | lb; sack |    2 |  NA | 0.0 | 100.0 | 100.0
      41 | orange | falta la cantidad; falta la unidad | piece |    2 |  NA | 0.0 | 100.0 | 100.0
      42 | soft_drink | falta la cantidad; falta la unidad | l |    2 |  NA | 0.0 | 100.0 | 100.0
      43 | oats | sin factor de unidad | sack |    1 |  NA | 0.0 | 100.0 | 100.0
      44 | sardines_canned | falta la cantidad | can |    1 |  NA | 0.0 | 100.0 | 100.0
      Línea discontinua: la proporción de la regla de parada.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D7] Cuadro D7. Regla de parada y proporción no vinculada, % (IC 95%)
      
      Regla: vincular al menos el 90% de los gramos incluidos y del gasto incluido. La regla se cumple.
      measure | n | unlinked | ci_low | ci_high
      Gramos | 2000 | 3.4 | 3.3 | 3.6
      Gasto | 2000 | 2.4 | 2.3 | 2.6
      n = 2,000 hogares

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D8_area] Cuadro D8. Proporción no vinculada por área, % (IC 95%)
      
      domain_value | measure | n | unlinked | ci_low | ci_high | rest | difference | difference_ci_low | difference_ci_high | differs
      Rural | Gramos |  870 | 3.2 | 2.9 | 3.5 | 3.7 | -0.5 | -0.9 | -0.2 | sí
      Urbana | Gramos | 1130 | 3.7 | 3.5 | 3.9 | 3.2 |  0.5 |  0.2 |  0.9 | sí
      Rural | Gasto |  870 | 2.4 | 2.1 | 2.7 | 2.5 | -0.1 | -0.4 |  0.3 | no
      Urbana | Gasto | 1130 | 2.5 | 2.3 | 2.7 | 2.4 |  0.1 | -0.3 |  0.4 | no
      Un valor difiere cuando el IC 95% de la diferencia excluye el cero, sin ajuste por comparaciones múltiples.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D8_expenditure_group] Cuadro D8. Proporción no vinculada por quintil de gasto, % (IC 95%)
      
      domain_value | measure | n | unlinked | ci_low | ci_high | rest | difference | difference_ci_low | difference_ci_high | differs
      Q1 (menor gasto) | Gramos | 354 | 3.2 | 2.8 | 3.7 | 3.5 | -0.3 | -0.8 | 0.2 | no
      Q2 | Gramos | 382 | 3.1 | 2.6 | 3.6 | 3.5 | -0.4 | -1.0 | 0.1 | no
      Q3 | Gramos | 395 | 3.4 | 3.1 | 3.8 | 3.4 |  0.0 | -0.4 | 0.4 | no
      Q4 | Gramos | 404 | 3.4 | 3.1 | 3.8 | 3.4 |  0.0 | -0.4 | 0.3 | no
      Q5 (mayor gasto) | Gramos | 434 | 3.9 | 3.6 | 4.3 | 3.3 |  0.6 |  0.2 | 1.0 | sí
      Sin dato | Gramos |  31 |  NA |  NA |  NA | 3.4 |   NA |   NA |  NA | NA
      Q1 (menor gasto) | Gasto | 354 | 2.1 | 1.8 | 2.5 | 2.5 | -0.3 | -0.7 | 0.0 | sí
      Q2 | Gasto | 382 | 2.4 | 2.1 | 2.7 | 2.4 |  0.0 | -0.4 | 0.3 | no
      Q3 | Gasto | 395 | 2.5 | 2.1 | 2.9 | 2.4 |  0.1 | -0.4 | 0.5 | no
      Q4 | Gasto | 404 | 2.4 | 2.1 | 2.7 | 2.4 | -0.1 | -0.4 | 0.3 | no
      Q5 (mayor gasto) | Gasto | 434 | 2.6 | 2.3 | 3.0 | 2.4 |  0.3 | -0.1 | 0.6 | no
      Sin dato | Gasto |  31 |  NA |  NA |  NA | 2.4 |   NA |   NA |  NA | NA
      Un valor difiere cuando el IC 95% de la diferencia excluye el cero, sin ajuste por comparaciones múltiples.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D9] Figura D9. Ingesta aparente de energía por equivalente de mujer adulta, kcal por día
      
      Mediana de la ingesta aparente de energía: 2,329 kcal por equivalente de mujer adulta por día (IC 95% 2,273 a 2,392), el 101.7% de la energía de la persona de referencia (2,291 kcal). Hogares fuera del rango plausible (500 a 6,000 kcal): 1.8% (IC 95% 1.2 a 2.6).
      n | median | ci_low | ci_high | pct_reference | outside | outside_ci_low | outside_ci_high
      1928 | 2329 | 2273 | 2392 | 101.7 | 1.8 | 1.2 | 2.6
      n = 1,928 hogares
      Líneas discontinuas: el rango plausible; línea continua: la energía de la persona de referencia.
      9 hogares por encima de 6,000 kcal, no representados.
      Los 33 hogares fuera del rango plausible quedan fuera del informe de resultados (elección `energy_action`, tabla D10).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [D10] Cuadro D10. Decisiones tomadas con los datos
      
      decision | choice | evidence
      Fuente de los factores de conversión de unidades | Factores de unidad de hces_example, inventados para el ejemplo | Escalera de vinculación: registros convertidos a gramos
      Tabla de composición | Composición de hces_example, inventada; se restan los nutrientes añadidos de los alimentos enriquecidos para obtener la línea de base sin fortificar | Escalera de vinculación y cola de trabajo
      Regla de valores extremos | No se aplica ninguna regla en este ejemplo | Ninguna adquisición se marcó ni se excluyó
      Divisor de días | period_days de cada registro, el período de referencia de su módulo | Inventario de variables: period_days presente
      Imputación | Ninguna | Los registros sin cantidad, unidad o gramos quedan fuera y se cuentan en la escalera de vinculación
      Hogares con energía aparente implausible | Fuera de los resultados (energy_action = "exclude"): una energía aparente fuera del rango plausible apunta a errores de registro, como compras almacenadas o alimentos regalados, y esos hogares pueden determinar una estimación por encima del nivel superior | Informe de preparación, sección 7 (figura D9): hogares fuera del rango

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [DA1] Cuadro DA1. Inventario de variables
      
      table | variable | role | present | share_missing | needed_by
      households | household_id | esencial | sí | 0.0 | todas las secciones
      households | weight | esencial | sí | 0.0 | todas las secciones
      households | stratum | esencial | sí | 0.0 | todas las secciones
      households | psu | esencial | sí | 0.0 | todas las secciones
      households | food_module_response | opcional | sí | 0.0 | estado de cada hogar
      members | household_id | esencial | sí | 0.0 | todas las secciones
      members | member_id | esencial | sí | 0.0 | todas las secciones
      members | age_years | esencial | sí | 0.3 | todas las secciones
      members | sex | esencial | sí | 0.2 | todas las secciones
      members | age_months | opcional | no |  NA | equivalentes de mujer adulta
      members | pregnant | opcional | sí | 0.0 | equivalentes de mujer adulta
      members | lactating | opcional | sí | 0.0 | equivalentes de mujer adulta
      members | meals_home_share | opcional | no |  NA | equivalentes de mujer adulta
      members | weight_kg | opcional | no |  NA | equivalentes de mujer adulta
      acquisitions | record_id | esencial | sí | 0.0 | todas las secciones
      acquisitions | household_id | esencial | sí | 0.0 | todas las secciones
      acquisitions | food_code | esencial | sí | 0.0 | todas las secciones
      acquisitions | quantity | esencial | sí | 0.3 | todas las secciones
      acquisitions | unit | esencial | sí | 0.2 | todas las secciones
      acquisitions | section | esencial | sí | 0.0 | todas las secciones
      acquisitions | period_days | esencial | sí | 0.0 | todas las secciones
      acquisitions | include | esencial | sí | 0.0 | todas las secciones
      acquisitions | origin | opcional | sí | 0.0 | ninguna
      acquisitions | household_share | opcional | no |  NA | cantidades de cada hogar
      acquisitions | expenditure_lcu | opcional | sí | 0.0 | vinculación por gasto
      households | region | opcional | sí | 0.0 | análisis por región
      households | area | opcional | sí | 0.0 | análisis por área
      households | expenditure_group | opcional | sí | 1.6 | análisis por quintil de gasto
      unit_factors | NA | esencial | sí |  NA | todas las secciones
      crosswalk | NA | esencial | sí |  NA | todas las secciones
      composition | NA | esencial | sí |  NA | todas las secciones
      enrichment | NA | opcional | sí |  NA | línea de base sin fortificar
      vehicles | NA | opcional | sí |  NA | Cobertura de los vehículos, Cantidad entre quienes adquieren y Escenarios de fortificación
      scenarios | NA | opcional | sí |  NA | Escenarios de fortificación
      food_groups | NA | opcional | sí |  NA | Aporte de cada grupo de alimentos

# exhibits of the results report, en (Q1)

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R0] Figure R0. Households with inadequate apparent intake, without fortification and with each scenario, % (95% CI)
      
      nutrient | scenario | n | inadequate | ci_low | ci_high | mark
      Iron | Without fortification | 1895 | 79.4 | 77.6 | 81.2 | NA
      Iron | Wheat flour with iron, zinc and folic acid | 1895 | 66.3 | 64.1 | 68.4 | NA
      Iron | Wheat and maize flour with iron, zinc and folic acid | 1895 | 64.3 | 62.1 | 66.5 | NA
      Iron | Wheat and maize flour, and rice with iron and folic acid | 1895 | 47.3 | 45.1 | 49.6 | NA
      Iron | Wheat and maize flour, rice, and sugar with vitamin A | 1895 | 47.3 | 45.1 | 49.6 | NA
      Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | 1895 | 47.3 | 45.1 | 49.6 | NA
      Zinc | Without fortification | 1895 | 36.9 | 34.0 | 39.9 | NA
      Zinc | Wheat flour with iron, zinc and folic acid | 1895 | 24.1 | 21.5 | 26.8 | NA
      Zinc | Wheat and maize flour with iron, zinc and folic acid | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Wheat and maize flour, and rice with iron and folic acid | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Wheat and maize flour, rice, and sugar with vitamin A | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | 1895 | 21.9 | 19.4 | 24.5 | NA
      Folate | Without fortification | 1895 | 34.5 | 32.1 | 37.0 | NA
      Folate | Wheat flour with iron, zinc and folic acid | 1895 | 11.6 |  9.8 | 13.6 | NA
      Folate | Wheat and maize flour with iron, zinc and folic acid | 1895 |  9.0 |  7.5 | 10.7 | NA
      Folate | Wheat and maize flour, and rice with iron and folic acid | 1895 |  0.4 |  0.1 |  0.8 | NA
      Folate | Wheat and maize flour, rice, and sugar with vitamin A | 1895 |  0.4 |  0.1 |  0.8 | NA
      Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | 1895 |  0.4 |  0.1 |  0.8 | NA
      Vitamin A | Without fortification | 1895 | 75.5 | 72.8 | 78.0 | NA
      Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | 1895 | 37.0 | 34.1 | 40.0 | NA
      Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | 1895 | 11.7 | 10.0 | 13.7 | NA
      n = 1,895 households
      Method: Iron: probability approach, iron bioavailability 10%; Zinc: EAR cut-point; Folate: EAR cut-point; Vitamin A: EAR cut-point.
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.1] Figure R1.1. Households that acquire each fortification vehicle, % (95% CI)
      
      vehicle | n | acquired | ci_low | ci_high | mark
      Wheat flour | 1931 | 63.9 | 61.4 | 66.4 | NA
      Bread | 1931 | 78.7 | 76.3 | 80.9 | NA
      Pasta | 1931 | 59.6 | 57.0 | 62.2 | NA
      Maize flour | 1931 | 29.3 | 26.7 | 32.0 | NA
      Rice | 1931 | 95.8 | 94.6 | 96.7 | NA
      Sugar | 1931 | 96.1 | 95.1 | 96.9 | NA
      Vegetable oil | 1931 | 93.5 | 92.1 | 94.7 | NA
      n = 1,931 households

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.2] Figure R1.2. Households that acquire each vehicle group or any vehicle, % (95% CI)
      
      vehicle_group | n | acquired | ci_low | ci_high | mark
      Wheat flour (any form) | 1931 | 96.6 | 95.5 |  97.5 | NA
      Any vehicle | 1931 | 99.9 | 99.6 | 100.0 | NA
      n = 1,931 households
      Groups. Wheat flour (any form): Wheat flour, Bread and Pasta; Any vehicle: Rice, Wheat flour, Bread, Pasta, Maize flour, Vegetable oil and Sugar.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.3] Figure R1.3. Quantity of each vehicle among the households that acquire it, median g per adult female equivalent per day (95% CI)
      
      vehicle | n | median_g | ci_low | ci_high | mark
      Wheat flour | 1217 |  35 |  33 |  37 | NA
      Bread | 1510 |  34 |  33 |  35 | NA
      Pasta | 1138 |  28 |  27 |  29 | NA
      Maize flour |  542 |  42 |  41 |  44 | NA
      Rice | 1817 | 143 | 140 | 147 | NA
      Sugar | 1822 |  64 |  62 |  66 | NA
      Vegetable oil | 1773 |  43 |  42 |  45 | NA
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_region] Figure R1.4. Households that acquire no vehicle, by region, % (95% CI)
      In the sample, the same value in every household: North = 0% (n = 678; interval limit 0.5%).
      domain_value | n | none | ci_low | ci_high | mark
      Central | 676 | 0.2 | 0 | 0.9 | NA
      South | 577 | 0.2 | 0 | 0.9 | NA

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_area] Figure R1.4. Households that acquire no vehicle, by area, % (95% CI)
      In the sample, the same value in every household: Rural = 0% (n = 850; interval limit 0.4%).
      domain_value | n | none | ci_low | ci_high | mark
      Urban | 1081 | 0.2 | 0 | 0.8 | NA
      n = 1,081 households

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_expenditure_group] Figure R1.4. Households that acquire no vehicle, by expenditure quintile, % (95% CI)
      In the sample, the same value in every household: Q2 = 0% (n = 381; interval limit 1%); Q3 = 0% (n = 395; interval limit 0.9%); Q4 = 0% (n = 402; interval limit 0.9%); Q5 (highest expenditure) = 0% (n = 428; interval limit 0.9%).
      domain_value | n | none | ci_low | ci_high | mark
      Q1 (lowest expenditure) | 325 | 0.6 | 0.1 | 2.1 | NA
      No data |   0 |  NA |  NA |  NA | NA
      — No data: no household with an estimate.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.1] Figure R2.1. Households with inadequate apparent intake without fortification, by nutrient, % (95% CI)
      
      nutrient | n | inadequate | ci_low | ci_high | mark
      Iron | 1895 | 79.4 | 77.6 | 81.2 | NA
      Zinc | 1895 | 36.9 | 34.0 | 39.9 | NA
      Folate | 1895 | 34.5 | 32.1 | 37.0 | NA
      Vitamin A | 1895 | 75.5 | 72.8 | 78.0 | NA
      n = 1,895 households
      Method: Iron: probability approach, iron bioavailability 10%; Zinc: EAR cut-point; Folate: EAR cut-point; Vitamin A: EAR cut-point.
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_region] Figure R2.2. Households with inadequate apparent intake without fortification, by region, % (95% CI)
      
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      North | Iron | 667 | 78.0 | 74.7 | 81.1 | NA
      North | Zinc | 667 | 35.0 | 30.0 | 40.2 | NA
      North | Folate | 667 | 32.5 | 28.9 | 36.3 | NA
      North | Vitamin A | 667 | 73.4 | 68.3 | 78.1 | NA
      Central | Iron | 659 | 78.2 | 74.8 | 81.3 | NA
      Central | Zinc | 659 | 34.4 | 29.3 | 39.7 | NA
      Central | Folate | 659 | 32.2 | 28.1 | 36.4 | NA
      Central | Vitamin A | 659 | 73.9 | 69.1 | 78.3 | NA
      South | Iron | 569 | 82.6 | 79.2 | 85.6 | NA
      South | Zinc | 569 | 42.2 | 36.7 | 47.9 | NA
      South | Folate | 569 | 39.6 | 34.6 | 44.9 | NA
      South | Vitamin A | 569 | 79.8 | 75.4 | 83.7 | NA
      Dashed line: the national estimate.
      Method: Iron: probability approach, iron bioavailability 10%; Zinc: EAR cut-point; Folate: EAR cut-point; Vitamin A: EAR cut-point.
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_area] Figure R2.2. Households with inadequate apparent intake without fortification, by area, % (95% CI)
      
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      Urban | Iron | 1064 | 74.1 | 71.4 | 76.7 | NA
      Urban | Zinc | 1064 | 25.0 | 21.7 | 28.4 | NA
      Urban | Folate | 1064 | 29.2 | 26.1 | 32.4 | NA
      Urban | Vitamin A | 1064 | 67.4 | 63.5 | 71.2 | NA
      Rural | Iron |  831 | 84.2 | 81.5 | 86.6 | NA
      Rural | Zinc |  831 | 47.6 | 42.8 | 52.4 | NA
      Rural | Folate |  831 | 39.2 | 35.6 | 43.0 | NA
      Rural | Vitamin A |  831 | 82.6 | 78.9 | 86.0 | NA
      Dashed line: the national estimate.
      Method: Iron: probability approach, iron bioavailability 10%; Zinc: EAR cut-point; Folate: EAR cut-point; Vitamin A: EAR cut-point.
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_expenditure_group] Figure R2.2. Households with inadequate apparent intake without fortification, by expenditure quintile, % (95% CI)
      In the sample, the same value in every household: Q5 (highest expenditure), Zinc = 0% (n = 421; interval limit 0.9%).
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      Q1 (lowest expenditure) | Iron | 318 | 96.7 | 94.1 | 98.4 | NA
      Q1 (lowest expenditure) | Zinc | 318 | 90.9 | 86.6 | 94.2 | NA
      Q1 (lowest expenditure) | Folate | 318 | 65.1 | 59.5 | 70.3 | NA
      Q1 (lowest expenditure) | Vitamin A | 318 | 97.2 | 94.3 | 98.9 | NA
      Q2 | Iron | 369 | 91.4 | 88.1 | 94.1 | NA
      Q2 | Zinc | 369 | 60.3 | 54.9 | 65.4 | NA
      Q2 | Folate | 369 | 43.9 | 38.8 | 49.1 | NA
      Q2 | Vitamin A | 369 | 93.0 | 89.8 | 95.5 | NA
      Q3 | Iron | 389 | 84.1 | 80.1 | 87.6 | NA
      Q3 | Zinc | 389 | 31.7 | 26.7 | 37.1 | NA
      Q3 | Folate | 389 | 32.9 | 28.0 | 38.2 | NA
      Q3 | Vitamin A | 389 | 84.3 | 80.0 | 88.1 | NA
      Q4 | Iron | 398 | 75.1 | 70.6 | 79.3 | NA
      Q4 | Zinc | 398 |  6.6 |  4.3 |  9.5 | NA
      Q4 | Folate | 398 | 22.6 | 18.6 | 27.1 | NA
      Q4 | Vitamin A | 398 | 67.2 | 62.2 | 72.0 | NA
      Q5 (highest expenditure) | Iron | 421 | 51.3 | 46.4 | 56.2 | NA
      Q5 (highest expenditure) | Folate | 421 | 10.7 |  7.7 | 14.3 | NA
      Q5 (highest expenditure) | Vitamin A | 421 | 37.5 | 32.7 | 42.6 | NA
      No data | Iron |   0 |   NA |   NA |   NA | NA
      No data | Zinc |   0 |   NA |   NA |   NA | NA
      No data | Folate |   0 |   NA |   NA |   NA | NA
      No data | Vitamin A |   0 |   NA |   NA |   NA | NA
      — No data: no household with an estimate.
      Dashed line: the national estimate.
      Method: Iron: probability approach, iron bioavailability 10%; Zinc: EAR cut-point; Folate: EAR cut-point; Vitamin A: EAR cut-point.
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.1] Table R3.1. Fortification scenarios
      
      scenario | abbreviation | vehicle | nutrient | compound_form | level_mg_kg | compliance | source
      Wheat flour with iron, zinc and folic acid | Wheat flour | Wheat flour | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Wheat flour | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Wheat flour | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Bread | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Bread | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Bread | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Pasta | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Pasta | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat flour with iron, zinc and folic acid | Wheat flour | Pasta | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Wheat flour | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Wheat flour | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Wheat flour | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Bread | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Bread | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Bread | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Pasta | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Pasta | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Pasta | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Maize flour | Iron | sodium iron EDTA | 40 | 60 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Maize flour | Zinc | zinc oxide | 20 | 60 | Invented for the example
      Wheat and maize flour with iron, zinc and folic acid | + maize flour | Maize flour | Folate | folic acid |  2 | 60 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Wheat flour | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Wheat flour | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Wheat flour | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Bread | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Bread | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Bread | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Pasta | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Pasta | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Pasta | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Maize flour | Iron | sodium iron EDTA | 40 | 60 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Maize flour | Zinc | zinc oxide | 20 | 60 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Maize flour | Folate | folic acid |  2 | 60 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Rice | Iron | ferric pyrophosphate | 40 | 50 | Invented for the example
      Wheat and maize flour, and rice with iron and folic acid | + rice | Rice | Folate | folic acid |  4 | 50 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Wheat flour | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Wheat flour | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Wheat flour | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Bread | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Bread | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Bread | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Pasta | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Pasta | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Pasta | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Maize flour | Iron | sodium iron EDTA | 40 | 60 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Maize flour | Zinc | zinc oxide | 20 | 60 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Maize flour | Folate | folic acid |  2 | 60 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Rice | Iron | ferric pyrophosphate | 40 | 50 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Rice | Folate | folic acid |  4 | 50 | Invented for the example
      Wheat and maize flour, rice, and sugar with vitamin A | + sugar | Sugar | Vitamin A | vitamin A compound (invented) |  5 | 70 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Wheat flour | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Wheat flour | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Wheat flour | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Bread | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Bread | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Bread | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Pasta | Iron | ferrous fumarate | 40 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Pasta | Zinc | zinc oxide | 20 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Pasta | Folate | folic acid |  2 | 80 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Maize flour | Iron | sodium iron EDTA | 40 | 60 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Maize flour | Zinc | zinc oxide | 20 | 60 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Maize flour | Folate | folic acid |  2 | 60 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Rice | Iron | ferric pyrophosphate | 40 | 50 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Rice | Folate | folic acid |  4 | 50 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Sugar | Vitamin A | vitamin A compound (invented) |  5 | 70 | Invented for the example
      Wheat and maize flour, rice, sugar, and oil with vitamin A | + oil | Vegetable oil | Vitamin A | retinol |  6 | 90 | Invented for the example
      A scenario lists every vehicle it fortifies, so cumulative scenarios repeat the vehicles of the one before.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_iron] Figure R3.2. Effect of each scenario on inadequate apparent intake of iron, % and percentage points (95% CI)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 1895 | 79.4 | 66.3 | -13.1 | -13.7 | -12.6 | NA
      Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 1895 | 79.4 | 64.3 | -15.1 | -15.7 | -14.5 | NA
      Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      n = 1,895 households
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_zinc] Figure R3.2. Effect of each scenario on inadequate apparent intake of zinc, % and percentage points (95% CI)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 1895 | 36.9 | 24.1 | -12.8 | -14.5 | -11.1 | NA
      Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      n = 1,895 households
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_folate] Figure R3.2. Effect of each scenario on inadequate apparent intake of folate, % and percentage points (95% CI)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 1895 | 34.5 | 11.6 | -22.9 | -24.8 | -21.0 | NA
      Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 1895 | 34.5 |  9.0 | -25.5 | -27.4 | -23.6 | NA
      Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      n = 1,895 households
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_vitamin_a] Figure R3.2. Effect of each scenario on inadequate apparent intake of vitamin A, % and percentage points (95% CI)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 1895 | 75.5 | 37.0 | -38.5 | -40.9 | -36.1 | NA
      Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 1895 | 75.5 | 11.7 | -63.7 | -66.2 | -61.2 | NA
      n = 1,895 households
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.3] Figure R3.3. Households above the upper level, by scenario, % (95% CI)
      In the sample, the same value in every household: Folate, Wheat flour with iron, zinc and folic acid = 0% (n = 1,895; interval limit 0.19%); Folate, Wheat and maize flour with iron, zinc and folic acid = 0% (n = 1,895; interval limit 0.19%).
      In the sample (n = 1,895), no household exceeds the upper level of iron, zinc and vitamin A under any scenario (upper limit of the 95% CI: iron 0.19%; zinc 0.19%; vitamin A 0.19% of households).
      nutrient | scenario | n | above_ul | ci_low | ci_high | mark
      Folate | Wheat and maize flour, and rice with iron and folic acid | 1895 | 0.4 | 0.17 | 0.8 | NA
      Folate | Wheat and maize flour, rice, and sugar with vitamin A | 1895 | 0.4 | 0.17 | 0.8 | NA
      Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | 1895 | 0.4 | 0.17 | 0.8 | NA
      n = 1,895 households
      Iron: Total intake under the scenario is compared. Supplements and water are not counted, and missing records or composition values lower it (IOM 2001, Summary, pp. 26-27).
      Zinc: Total intake under the scenario is compared. Supplements and water are not counted, and missing records or composition values lower it (IOM 2001, Summary, pp. 26-27).
      Folate: The upper level applies to folate from fortified food or supplements, not to food folate, so the folic acid added by the scenario is the quantity to compare. Folic acid from foods fortified outside the scenarios and from supplements is not recorded by the survey: where they exist, the share is a lower bound (IOM 1998, pp. 13, 280).
      Vitamin A: The upper level applies to preformed vitamin A from food, fortified food and supplements. Only the retinol added by the scenario is compared; preformed vitamin A of the diet and of supplements is not counted, so the share is a lower bound (IOM 2001, pp. 126, 142).
      The adult upper level is applied to intake per adult female equivalent; children have lower upper levels.
      Under average content with a compliance below 1, every gram of the vehicle carries part of the level and no household receives the full level, so the share above the upper level is understated; the same levels at compliance 1 give its upper bound.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_iron_expenditure_group] Figure R3.4. Effect of each scenario on inadequate apparent intake of iron, by expenditure quintile, % and percentage points (95% CI)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (lowest expenditure) | Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 318 | 96.7 | 91.4 |  -5.3 |  -6.2 |  -4.3 | NA
      Q1 (lowest expenditure) | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 318 | 96.7 | 89.5 |  -7.2 |  -8.3 |  -6.1 | NA
      Q1 (lowest expenditure) | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q1 (lowest expenditure) | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q1 (lowest expenditure) | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q2 | Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 369 | 91.4 | 80.9 | -10.5 | -11.5 |  -9.6 | NA
      Q2 | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 369 | 91.4 | 78.3 | -13.2 | -14.2 | -12.1 | NA
      Q2 | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q2 | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q2 | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q3 | Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 389 | 84.1 | 69.5 | -14.6 | -15.7 | -13.5 | NA
      Q3 | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 389 | 84.1 | 67.4 | -16.7 | -18.0 | -15.5 | NA
      Q3 | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q3 | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q3 | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q4 | Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 398 | 75.1 | 58.3 | -16.8 | -17.8 | -15.7 | NA
      Q4 | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 398 | 75.1 | 56.3 | -18.8 | -19.9 | -17.7 | NA
      Q4 | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q4 | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q4 | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q5 (highest expenditure) | Iron | Wheat flour with iron, zinc and folic acid | Without fortification | 421 | 51.3 | 33.5 | -17.9 | -18.7 | -17.0 | NA
      Q5 (highest expenditure) | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 421 | 51.3 | 32.3 | -19.0 | -19.9 | -18.1 | NA
      Q5 (highest expenditure) | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      Q5 (highest expenditure) | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      Q5 (highest expenditure) | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      No data | Iron | Wheat flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Iron | Wheat and maize flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Iron | Wheat and maize flour, and rice with iron and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Iron | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Iron | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — No data: no household with an estimate.
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_zinc_expenditure_group] Figure R3.4. Effect of each scenario on inadequate apparent intake of zinc, by expenditure quintile, % and percentage points (95% CI)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (lowest expenditure) | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 318 | 90.9 | 77.8 | -13.1 | -16.7 |  -9.4 | NA
      Q1 (lowest expenditure) | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (lowest expenditure) | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (lowest expenditure) | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (lowest expenditure) | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q2 | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 369 | 60.3 | 34.5 | -25.8 | -30.1 | -21.5 | NA
      Q2 | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q3 | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 389 | 31.7 | 10.7 | -21.0 | -25.2 | -16.8 | NA
      Q3 | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q4 | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 398 |  6.6 |  2.0 |  -4.5 |  -6.5 |  -2.5 | NA
      Q4 | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q5 (highest expenditure) | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (highest expenditure) | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (highest expenditure) | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (highest expenditure) | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (highest expenditure) | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      No data | Zinc | Wheat flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Zinc | Wheat and maize flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Zinc | Wheat and maize flour, and rice with iron and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Zinc | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Zinc | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — No data: no household with an estimate.
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_folate_expenditure_group] Figure R3.4. Effect of each scenario on inadequate apparent intake of folate, by expenditure quintile, % and percentage points (95% CI)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (lowest expenditure) | Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 318 | 65.1 | 33.2 | -31.8 | -37.3 | -26.4 | NA
      Q1 (lowest expenditure) | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 318 | 65.1 | 24.5 | -40.5 | -45.6 | -35.4 | NA
      Q1 (lowest expenditure) | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q1 (lowest expenditure) | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q1 (lowest expenditure) | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q2 | Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 369 | 43.9 | 13.9 | -30.0 | -35.2 | -24.9 | NA
      Q2 | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 369 | 43.9 | 10.7 | -33.2 | -38.4 | -28.0 | NA
      Q2 | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q2 | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q2 | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q3 | Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 389 | 32.9 |  8.6 | -24.3 | -28.3 | -20.3 | NA
      Q3 | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 389 | 32.9 |  7.4 | -25.5 | -29.5 | -21.6 | NA
      Q3 | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q3 | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q3 | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q4 | Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 398 | 22.6 |  3.1 | -19.5 | -23.3 | -15.7 | NA
      Q4 | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 398 | 22.6 |  2.6 | -20.1 | -23.9 | -16.2 | NA
      Q4 | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q4 | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q4 | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q5 (highest expenditure) | Folate | Wheat flour with iron, zinc and folic acid | Without fortification | 421 | 10.7 |  1.2 |  -9.5 | -12.3 |  -6.7 | NA
      Q5 (highest expenditure) | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification | 421 | 10.7 |  1.2 |  -9.5 | -12.3 |  -6.7 | NA
      Q5 (highest expenditure) | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      Q5 (highest expenditure) | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      Q5 (highest expenditure) | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      No data | Folate | Wheat flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Folate | Wheat and maize flour with iron, zinc and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Folate | Wheat and maize flour, and rice with iron and folic acid | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Folate | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Folate | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — No data: no household with an estimate.
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_vitamin_a_expenditure_group] Figure R3.4. Effect of each scenario on inadequate apparent intake of vitamin A, by expenditure quintile, % and percentage points (95% CI)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (lowest expenditure) | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 318 | 97.2 | 76.5 | -20.7 | -25.2 | -16.3 | NA
      Q1 (lowest expenditure) | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 318 | 97.2 | 39.4 | -57.8 | -63.9 | -51.6 | NA
      Q2 | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 369 | 93.0 | 53.1 | -40.0 | -45.2 | -34.7 | NA
      Q2 | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 369 | 93.0 | 14.8 | -78.2 | -82.4 | -74.0 | NA
      Q3 | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 389 | 84.3 | 34.8 | -49.5 | -54.9 | -44.1 | NA
      Q3 | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 389 | 84.3 |  5.1 | -79.2 | -83.5 | -74.9 | NA
      Q4 | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 398 | 67.2 | 17.5 | -49.7 | -54.3 | -45.1 | NA
      Q4 | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 398 | 67.2 |  1.0 | -66.2 | -70.9 | -61.4 | NA
      Q5 (highest expenditure) | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification | 421 | 37.5 |  6.6 | -30.9 | -35.6 | -26.1 | NA
      Q5 (highest expenditure) | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification | 421 | 37.5 |  0.7 | -36.8 | -41.7 | -31.9 | NA
      No data | Vitamin A | Wheat and maize flour, rice, and sugar with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      No data | Vitamin A | Wheat and maize flour, rice, sugar, and oil with vitamin A | Without fortification |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — No data: no household with an estimate.
      Left panel: hollow point, the scenario compared with (Without fortification); filled point, the scenario. Right panel: paired difference in percentage points, with its 95% CI.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).
      Apparent intake, not usual intake: the share of households whose acquisitions over the recall period, per adult female equivalent, fall below the requirement. The cut-point and the probability approach are defined on usual intake (IOM 2000b, pp. 73 and 99; IOM 2001, p. 703); this is a figure for comparing scenarios on the same data, not a prevalence of inadequacy.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R4.1] Figure R4.1. Share of each food group in apparent intake, by nutrient, % (95% CI)
      
      nutrient | food_group | n | share | ci_low | ci_high | mark
      Iron | Cereals | 1895 | 32.4 | 31.8 | 33.0 | NA
      Iron | Roots and tubers | 1895 |  7.4 |  7.1 |  7.6 | NA
      Iron | Pulses | 1895 | 34.3 | 33.6 | 35.1 | NA
      Iron | Meat and fish | 1895 | 11.9 | 11.5 | 12.3 | NA
      Iron | Eggs | 1895 |  3.9 |  3.8 |  4.0 | NA
      Iron | Dairy | 1895 |  1.1 |  1.0 |  1.1 | NA
      Iron | Fats and oils | 1895 |  0.0 |  0.0 |  0.0 | NA
      Iron | Sugars | 1895 |  1.4 |  1.3 |  1.4 | NA
      Iron | Vegetables | 1895 |  5.1 |  4.9 |  5.2 | NA
      Iron | Fruits | 1895 |  0.6 |  0.6 |  0.7 | NA
      Iron | Beverages | 1895 |  1.3 |  1.3 |  1.4 | NA
      Zinc | Cereals | 1895 | 35.8 | 35.2 | 36.5 | NA
      Zinc | Roots and tubers | 1895 |  2.9 |  2.8 |  3.0 | NA
      Zinc | Pulses | 1895 | 18.6 | 18.1 | 19.2 | NA
      Zinc | Meat and fish | 1895 | 24.7 | 23.9 | 25.4 | NA
      Zinc | Eggs | 1895 |  3.5 |  3.4 |  3.6 | NA
      Zinc | Dairy | 1895 |  9.2 |  8.8 |  9.6 | NA
      Zinc | Vegetables | 1895 |  4.0 |  3.9 |  4.1 | NA
      Zinc | Fruits | 1895 |  0.5 |  0.5 |  0.5 | NA
      Zinc | Beverages | 1895 |  0.6 |  0.5 |  0.6 | NA
      Folate | Cereals | 1895 | 17.9 | 17.4 | 18.4 | NA
      Folate | Roots and tubers | 1895 |  7.0 |  6.7 |  7.2 | NA
      Folate | Pulses | 1895 | 57.1 | 56.3 | 58.0 | NA
      Folate | Meat and fish | 1895 |  1.6 |  1.5 |  1.7 | NA
      Folate | Eggs | 1895 |  2.7 |  2.6 |  2.8 | NA
      Folate | Dairy | 1895 |  2.1 |  2.0 |  2.2 | NA
      Folate | Fats and oils | 1895 |  0.0 |  0.0 |  0.0 | NA
      Folate | Vegetables | 1895 |  8.0 |  7.7 |  8.2 | NA
      Folate | Fruits | 1895 |  3.6 |  3.4 |  3.8 | NA
      Folate | Beverages | 1895 |  0.0 |  0.0 |  0.0 | NA
      Vitamin A | Cereals | 1895 |  1.3 |  1.2 |  1.4 | NA
      Vitamin A | Roots and tubers | 1895 | 10.5 | 10.0 | 11.0 | NA
      Vitamin A | Pulses | 1895 |  0.0 |  0.0 |  0.0 | NA
      Vitamin A | Meat and fish | 1895 |  6.5 |  6.2 |  6.7 | NA
      Vitamin A | Eggs | 1895 |  9.5 |  9.1 |  9.8 | NA
      Vitamin A | Dairy | 1895 | 17.7 | 17.0 | 18.5 | NA
      Vitamin A | Vegetables | 1895 | 51.3 | 50.2 | 52.4 | NA
      Vitamin A | Fruits | 1895 |  3.2 |  3.0 |  3.4 | NA
      n = 1,895 households
      No zinc from: fats and oils and sugars.
      No folate from: sugars.
      No vitamin A from: fats and oils, sugars and beverages.
      Share of foods with no group assigned: iron 0.6%; zinc 0.2%; folate 0%; vitamin A 0%.
      Not a proportion: judged only by the number of households and the degrees of freedom (technical note, departure S1).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT1] Table RT1. Requirements and upper levels used
      
      nutrient | ear | unit | ul | ul_unit | source
      Iron |   8.1 | mg |   45 | mg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Zinc |   6.8 | mg |   40 | mg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Vitamin A | 500.0 | µg RAE | 3000 | µg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Folate | 320.0 | µg DFE | 1000 | µg | IOM 1998, Dietary Reference Intakes for Thiamin, Riboflavin, Niacin, Vitamin B6, Folate, Vitamin B12, Pantothenic Acid, Biotin, and Choline

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT2] Table RT2. Presentation standard used
      
      criterion | value | source | location
      Confidence level of the interval |  0.95 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (a 95% two-sided confidence interval, Clopper-Pearson, or Korn-Graubard for complex surveys); p. 3
      Fewest households of an estimate (suppressed below) | 30.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (minimum denominator sample size of 30; below 30, suppress); p. 3
      Smallest effective sample size (suppressed below) | 30.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (minimum effective denominator sample size of 30; below 30, suppress); p. 3 (effective sample size: n divided by the design effect; when it is above n, or undefined because there are 0 events or n events, n is used)
      Interval width presented without the relative check (at most) |  0.05 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width above 0 and at most 0.05: present if there are events and the degrees of freedom criterion is met, otherwise flag for statistical review); p. 4
      Interval width suppressed (at least) |  0.30 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width 0.30 or more: suppress); p. 4
      Largest relative width of the interval (suppressed above, when the width lies between the two widths) |  1.30 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width between 0.05 and 0.30 and relative width more than 130%: suppress); p. 3 (relative width: absolute width divided by the proportion); p. 4
      Fewest degrees of freedom (flagged for review below) |  8.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (fewer than 8 degrees of freedom: flag for statistical review); p. 4 (degrees of freedom: PSUs minus strata as a rule of thumb, computed directly for a subgroup present in a subset of PSUs)
      Departure S1. Estimates other than proportions (medians, paired differences, shares of food groups) are judged only by their number of households and degrees of freedom, and their interval is always shown: the standard gives no thresholds for them (p. 5).
      Departure S2. Where inadequacy is a probability (iron), the proportion is the mean probability, and the standard is applied to it. Its variance is at most that of a yes-or-no outcome, so the width criteria are conservative; its effective sample size is the number of households divided by the design effect, computed from the variance of the probabilities themselves, as the standard defines it. Zero events means a mean of exactly 0 or 1.
      Departure S3. In this report, estimates flagged for statistical review are printed with the mark † and the reason. The standard allows them to be shown after review or suppressed (pp. 2, 5).
      Departure S4. A proportion with no household, or every household, in the sample is reported in a sentence with its n and the limit of its Clopper-Pearson interval, not as a row of a table or a point of a figure.
      Strata with a single primary sampling unit: their contribution to the variance is centred at the overall mean.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT3] Table RT3. Households with inadequate apparent intake of iron, by iron bioavailability, % (95% CI)
      
      bioavailability_pct | n | inadequate | ci_low | ci_high | mark
      5% | 1895 | 99.0 | 98.5 | 99.4 | NA
      10% | 1895 | 79.4 | 77.6 | 81.2 | NA
      15% | 1895 | 49.7 | 47.4 | 52.0 | NA
      n = 1,895 households
      The other exhibits use an iron bioavailability of 10%.

# exhibits of the results report, es (Q1)

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R0] Figura R0. Hogares con ingesta aparente inadecuada, sin fortificación y con cada escenario, % (IC 95%)
      
      nutrient | scenario | n | inadequate | ci_low | ci_high | mark
      Hierro | Sin fortificación | 1895 | 79.4 | 77.6 | 81.2 | NA
      Hierro | Harina de trigo con hierro, zinc y ácido fólico | 1895 | 66.3 | 64.1 | 68.4 | NA
      Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | 1895 | 64.3 | 62.1 | 66.5 | NA
      Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | 1895 | 47.3 | 45.1 | 49.6 | NA
      Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | 1895 | 47.3 | 45.1 | 49.6 | NA
      Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | 1895 | 47.3 | 45.1 | 49.6 | NA
      Zinc | Sin fortificación | 1895 | 36.9 | 34.0 | 39.9 | NA
      Zinc | Harina de trigo con hierro, zinc y ácido fólico | 1895 | 24.1 | 21.5 | 26.8 | NA
      Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | 1895 | 21.9 | 19.4 | 24.5 | NA
      Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | 1895 | 21.9 | 19.4 | 24.5 | NA
      Folato | Sin fortificación | 1895 | 34.5 | 32.1 | 37.0 | NA
      Folato | Harina de trigo con hierro, zinc y ácido fólico | 1895 | 11.6 |  9.8 | 13.6 | NA
      Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | 1895 |  9.0 |  7.5 | 10.7 | NA
      Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | 1895 |  0.4 |  0.1 |  0.8 | NA
      Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | 1895 |  0.4 |  0.1 |  0.8 | NA
      Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | 1895 |  0.4 |  0.1 |  0.8 | NA
      Vitamina A | Sin fortificación | 1895 | 75.5 | 72.8 | 78.0 | NA
      Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | 1895 | 37.0 | 34.1 | 40.0 | NA
      Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | 1895 | 11.7 | 10.0 | 13.7 | NA
      n = 1,895 hogares
      Método: Hierro: método probabilístico, biodisponibilidad del hierro 10%; Zinc: punto de corte del EAR; Folato: punto de corte del EAR; Vitamina A: punto de corte del EAR.
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.1] Figura R1.1. Hogares que adquieren cada vehículo de fortificación, % (IC 95%)
      
      vehicle | n | acquired | ci_low | ci_high | mark
      Harina de trigo | 1931 | 63.9 | 61.4 | 66.4 | NA
      Pan | 1931 | 78.7 | 76.3 | 80.9 | NA
      Pastas | 1931 | 59.6 | 57.0 | 62.2 | NA
      Harina de maíz | 1931 | 29.3 | 26.7 | 32.0 | NA
      Arroz | 1931 | 95.8 | 94.6 | 96.7 | NA
      Azúcar | 1931 | 96.1 | 95.1 | 96.9 | NA
      Aceite vegetal | 1931 | 93.5 | 92.1 | 94.7 | NA
      n = 1,931 hogares

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.2] Figura R1.2. Hogares que adquieren cada grupo de vehículos o algún vehículo, % (IC 95%)
      
      vehicle_group | n | acquired | ci_low | ci_high | mark
      Harina de trigo (cualquier forma) | 1931 | 96.6 | 95.5 |  97.5 | NA
      Cualquier vehículo | 1931 | 99.9 | 99.6 | 100.0 | NA
      n = 1,931 hogares
      Grupos. Harina de trigo (cualquier forma): Harina de trigo, Pan y Pastas; Cualquier vehículo: Arroz, Harina de trigo, Pan, Pastas, Harina de maíz, Aceite vegetal y Azúcar.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.3] Figura R1.3. Cantidad de cada vehículo en los hogares que lo adquieren, mediana en g por equivalente de mujer adulta por día (IC 95%)
      
      vehicle | n | median_g | ci_low | ci_high | mark
      Harina de trigo | 1217 |  35 |  33 |  37 | NA
      Pan | 1510 |  34 |  33 |  35 | NA
      Pastas | 1138 |  28 |  27 |  29 | NA
      Harina de maíz |  542 |  42 |  41 |  44 | NA
      Arroz | 1817 | 143 | 140 | 147 | NA
      Azúcar | 1822 |  64 |  62 |  66 | NA
      Aceite vegetal | 1773 |  43 |  42 |  45 | NA
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_region] Figura R1.4. Hogares que no adquieren ningún vehículo, por región, % (IC 95%)
      En la muestra, el mismo valor en todos los hogares: Norte = 0% (n = 678; límite del intervalo 0.5%).
      domain_value | n | none | ci_low | ci_high | mark
      Centro | 676 | 0.2 | 0 | 0.9 | NA
      Sur | 577 | 0.2 | 0 | 0.9 | NA

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_area] Figura R1.4. Hogares que no adquieren ningún vehículo, por área, % (IC 95%)
      En la muestra, el mismo valor en todos los hogares: Rural = 0% (n = 850; límite del intervalo 0.4%).
      domain_value | n | none | ci_low | ci_high | mark
      Urbana | 1081 | 0.2 | 0 | 0.8 | NA
      n = 1,081 hogares

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R1.4_expenditure_group] Figura R1.4. Hogares que no adquieren ningún vehículo, por quintil de gasto, % (IC 95%)
      En la muestra, el mismo valor en todos los hogares: Q2 = 0% (n = 381; límite del intervalo 1%); Q3 = 0% (n = 395; límite del intervalo 0.9%); Q4 = 0% (n = 402; límite del intervalo 0.9%); Q5 (mayor gasto) = 0% (n = 428; límite del intervalo 0.9%).
      domain_value | n | none | ci_low | ci_high | mark
      Q1 (menor gasto) | 325 | 0.6 | 0.1 | 2.1 | NA
      Sin dato |   0 |  NA |  NA |  NA | NA
      — Sin dato: ningún hogar con estimación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.1] Figura R2.1. Hogares con ingesta aparente inadecuada sin fortificación, por nutriente, % (IC 95%)
      
      nutrient | n | inadequate | ci_low | ci_high | mark
      Hierro | 1895 | 79.4 | 77.6 | 81.2 | NA
      Zinc | 1895 | 36.9 | 34.0 | 39.9 | NA
      Folato | 1895 | 34.5 | 32.1 | 37.0 | NA
      Vitamina A | 1895 | 75.5 | 72.8 | 78.0 | NA
      n = 1,895 hogares
      Método: Hierro: método probabilístico, biodisponibilidad del hierro 10%; Zinc: punto de corte del EAR; Folato: punto de corte del EAR; Vitamina A: punto de corte del EAR.
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_region] Figura R2.2. Hogares con ingesta aparente inadecuada sin fortificación, por región, % (IC 95%)
      
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      Norte | Hierro | 667 | 78.0 | 74.7 | 81.1 | NA
      Norte | Zinc | 667 | 35.0 | 30.0 | 40.2 | NA
      Norte | Folato | 667 | 32.5 | 28.9 | 36.3 | NA
      Norte | Vitamina A | 667 | 73.4 | 68.3 | 78.1 | NA
      Centro | Hierro | 659 | 78.2 | 74.8 | 81.3 | NA
      Centro | Zinc | 659 | 34.4 | 29.3 | 39.7 | NA
      Centro | Folato | 659 | 32.2 | 28.1 | 36.4 | NA
      Centro | Vitamina A | 659 | 73.9 | 69.1 | 78.3 | NA
      Sur | Hierro | 569 | 82.6 | 79.2 | 85.6 | NA
      Sur | Zinc | 569 | 42.2 | 36.7 | 47.9 | NA
      Sur | Folato | 569 | 39.6 | 34.6 | 44.9 | NA
      Sur | Vitamina A | 569 | 79.8 | 75.4 | 83.7 | NA
      Línea discontinua: la estimación nacional.
      Método: Hierro: método probabilístico, biodisponibilidad del hierro 10%; Zinc: punto de corte del EAR; Folato: punto de corte del EAR; Vitamina A: punto de corte del EAR.
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_area] Figura R2.2. Hogares con ingesta aparente inadecuada sin fortificación, por área, % (IC 95%)
      
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      Urbana | Hierro | 1064 | 74.1 | 71.4 | 76.7 | NA
      Urbana | Zinc | 1064 | 25.0 | 21.7 | 28.4 | NA
      Urbana | Folato | 1064 | 29.2 | 26.1 | 32.4 | NA
      Urbana | Vitamina A | 1064 | 67.4 | 63.5 | 71.2 | NA
      Rural | Hierro |  831 | 84.2 | 81.5 | 86.6 | NA
      Rural | Zinc |  831 | 47.6 | 42.8 | 52.4 | NA
      Rural | Folato |  831 | 39.2 | 35.6 | 43.0 | NA
      Rural | Vitamina A |  831 | 82.6 | 78.9 | 86.0 | NA
      Línea discontinua: la estimación nacional.
      Método: Hierro: método probabilístico, biodisponibilidad del hierro 10%; Zinc: punto de corte del EAR; Folato: punto de corte del EAR; Vitamina A: punto de corte del EAR.
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R2.2_expenditure_group] Figura R2.2. Hogares con ingesta aparente inadecuada sin fortificación, por quintil de gasto, % (IC 95%)
      En la muestra, el mismo valor en todos los hogares: Q5 (mayor gasto), Zinc = 0% (n = 421; límite del intervalo 0.9%).
      domain_value | nutrient | n | inadequate | ci_low | ci_high | mark
      Q1 (menor gasto) | Hierro | 318 | 96.7 | 94.1 | 98.4 | NA
      Q1 (menor gasto) | Zinc | 318 | 90.9 | 86.6 | 94.2 | NA
      Q1 (menor gasto) | Folato | 318 | 65.1 | 59.5 | 70.3 | NA
      Q1 (menor gasto) | Vitamina A | 318 | 97.2 | 94.3 | 98.9 | NA
      Q2 | Hierro | 369 | 91.4 | 88.1 | 94.1 | NA
      Q2 | Zinc | 369 | 60.3 | 54.9 | 65.4 | NA
      Q2 | Folato | 369 | 43.9 | 38.8 | 49.1 | NA
      Q2 | Vitamina A | 369 | 93.0 | 89.8 | 95.5 | NA
      Q3 | Hierro | 389 | 84.1 | 80.1 | 87.6 | NA
      Q3 | Zinc | 389 | 31.7 | 26.7 | 37.1 | NA
      Q3 | Folato | 389 | 32.9 | 28.0 | 38.2 | NA
      Q3 | Vitamina A | 389 | 84.3 | 80.0 | 88.1 | NA
      Q4 | Hierro | 398 | 75.1 | 70.6 | 79.3 | NA
      Q4 | Zinc | 398 |  6.6 |  4.3 |  9.5 | NA
      Q4 | Folato | 398 | 22.6 | 18.6 | 27.1 | NA
      Q4 | Vitamina A | 398 | 67.2 | 62.2 | 72.0 | NA
      Q5 (mayor gasto) | Hierro | 421 | 51.3 | 46.4 | 56.2 | NA
      Q5 (mayor gasto) | Folato | 421 | 10.7 |  7.7 | 14.3 | NA
      Q5 (mayor gasto) | Vitamina A | 421 | 37.5 | 32.7 | 42.6 | NA
      Sin dato | Hierro |   0 |   NA |   NA |   NA | NA
      Sin dato | Zinc |   0 |   NA |   NA |   NA | NA
      Sin dato | Folato |   0 |   NA |   NA |   NA | NA
      Sin dato | Vitamina A |   0 |   NA |   NA |   NA | NA
      — Sin dato: ningún hogar con estimación.
      Línea discontinua: la estimación nacional.
      Método: Hierro: método probabilístico, biodisponibilidad del hierro 10%; Zinc: punto de corte del EAR; Folato: punto de corte del EAR; Vitamina A: punto de corte del EAR.
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.1] Cuadro R3.1. Escenarios de fortificación
      
      scenario | abbreviation | vehicle | nutrient | compound_form | level_mg_kg | compliance | source
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Harina de trigo | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Harina de trigo | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Harina de trigo | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pan | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pan | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pan | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pastas | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pastas | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harina de trigo con hierro, zinc y ácido fólico | Harina de trigo | Pastas | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de trigo | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de trigo | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de trigo | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pan | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pan | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pan | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pastas | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pastas | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Pastas | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de maíz | Hierro | EDTA férrico sódico | 40 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de maíz | Zinc | óxido de zinc | 20 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz con hierro, zinc y ácido fólico | + harina de maíz | Harina de maíz | Folato | ácido fólico |  2 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de trigo | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de trigo | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de trigo | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pan | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pan | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pan | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pastas | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pastas | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Pastas | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de maíz | Hierro | EDTA férrico sódico | 40 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de maíz | Zinc | óxido de zinc | 20 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Harina de maíz | Folato | ácido fólico |  2 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Arroz | Hierro | pirofosfato férrico | 40 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | + arroz | Arroz | Folato | ácido fólico |  4 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de trigo | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de trigo | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de trigo | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pan | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pan | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pan | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pastas | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pastas | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Pastas | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de maíz | Hierro | EDTA férrico sódico | 40 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de maíz | Zinc | óxido de zinc | 20 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Harina de maíz | Folato | ácido fólico |  2 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Arroz | Hierro | pirofosfato férrico | 40 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Arroz | Folato | ácido fólico |  4 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | + azúcar | Azúcar | Vitamina A | compuesto de vitamina A (inventado) |  5 | 70 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de trigo | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de trigo | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de trigo | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pan | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pan | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pan | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pastas | Hierro | fumarato ferroso | 40 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pastas | Zinc | óxido de zinc | 20 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Pastas | Folato | ácido fólico |  2 | 80 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de maíz | Hierro | EDTA férrico sódico | 40 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de maíz | Zinc | óxido de zinc | 20 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Harina de maíz | Folato | ácido fólico |  2 | 60 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Arroz | Hierro | pirofosfato férrico | 40 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Arroz | Folato | ácido fólico |  4 | 50 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Azúcar | Vitamina A | compuesto de vitamina A (inventado) |  5 | 70 | Inventado para el ejemplo
      Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | + aceite | Aceite vegetal | Vitamina A | retinol |  6 | 90 | Inventado para el ejemplo
      Un escenario enumera todos los vehículos que fortifica, por lo que los escenarios acumulativos repiten los vehículos del anterior.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_iron] Figura R3.2. Efecto de cada escenario en la ingesta aparente inadecuada de hierro, % y puntos porcentuales (IC 95%)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 79.4 | 66.3 | -13.1 | -13.7 | -12.6 | NA
      Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 79.4 | 64.3 | -15.1 | -15.7 | -14.5 | NA
      Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 1895 | 79.4 | 47.3 | -32.1 | -33.0 | -31.3 | NA
      n = 1,895 hogares
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_zinc] Figura R3.2. Efecto de cada escenario en la ingesta aparente inadecuada de zinc, % y puntos porcentuales (IC 95%)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 36.9 | 24.1 | -12.8 | -14.5 | -11.1 | NA
      Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 1895 | 36.9 | 21.9 | -15.0 | -16.8 | -13.2 | NA
      n = 1,895 hogares
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_folate] Figura R3.2. Efecto de cada escenario en la ingesta aparente inadecuada de folato, % y puntos porcentuales (IC 95%)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 34.5 | 11.6 | -22.9 | -24.8 | -21.0 | NA
      Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 1895 | 34.5 |  9.0 | -25.5 | -27.4 | -23.6 | NA
      Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 1895 | 34.5 |  0.4 | -34.1 | -36.5 | -31.7 | NA
      n = 1,895 hogares
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.2_vitamin_a] Figura R3.2. Efecto de cada escenario en la ingesta aparente inadecuada de vitamina A, % y puntos porcentuales (IC 95%)
      
      nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 1895 | 75.5 | 37.0 | -38.5 | -40.9 | -36.1 | NA
      Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 1895 | 75.5 | 11.7 | -63.7 | -66.2 | -61.2 | NA
      n = 1,895 hogares
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.3] Figura R3.3. Hogares por encima del nivel máximo, por escenario, % (IC 95%)
      En la muestra, el mismo valor en todos los hogares: Folato, Harina de trigo con hierro, zinc y ácido fólico = 0% (n = 1,895; límite del intervalo 0.19%); Folato, Harinas de trigo y de maíz con hierro, zinc y ácido fólico = 0% (n = 1,895; límite del intervalo 0.19%).
      En la muestra (n = 1,895), ningún hogar supera el nivel máximo de hierro, zinc y vitamina A con ningún escenario (límite superior del IC 95%: hierro 0.19%; zinc 0.19%; vitamina A 0.19% de los hogares).
      nutrient | scenario | n | above_ul | ci_low | ci_high | mark
      Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | 1895 | 0.4 | 0.17 | 0.8 | NA
      Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | 1895 | 0.4 | 0.17 | 0.8 | NA
      Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | 1895 | 0.4 | 0.17 | 0.8 | NA
      n = 1,895 hogares
      Hierro: Se compara la ingesta total con el escenario. No se cuentan los suplementos ni el agua, y los registros o valores de composición que faltan la reducen (IOM 2001, resumen, pp. 26-27).
      Zinc: Se compara la ingesta total con el escenario. No se cuentan los suplementos ni el agua, y los registros o valores de composición que faltan la reducen (IOM 2001, resumen, pp. 26-27).
      Folato: El nivel máximo se aplica al folato de alimentos fortificados o suplementos, no al folato de los alimentos, de modo que el ácido fólico añadido por el escenario es la cantidad que se debe comparar. La encuesta no registra el ácido fólico de alimentos fortificados fuera de los escenarios ni el de suplementos: donde existan, la proporción es una cota inferior (IOM 1998, pp. 13, 280).
      Vitamina A: El nivel máximo se aplica a la vitamina A preformada de alimentos, alimentos fortificados y suplementos. Solo se compara el retinol añadido por el escenario; no se cuenta la vitamina A preformada de la dieta ni la de suplementos, de modo que la proporción es una cota inferior (IOM 2001, pp. 126, 142).
      El nivel máximo de los adultos se aplica a la ingesta por equivalente de mujer adulta; los niños tienen niveles máximos más bajos.
      Con contenido medio y un cumplimiento menor que 1, cada gramo del vehículo lleva una parte del nivel y ningún hogar recibe el nivel completo, de modo que la proporción por encima del nivel máximo está subestimada; los mismos niveles con cumplimiento 1 dan su cota superior.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_iron_expenditure_group] Figura R3.4. Efecto de cada escenario en la ingesta aparente inadecuada de hierro, por quintil de gasto, % y puntos porcentuales (IC 95%)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (menor gasto) | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 318 | 96.7 | 91.4 |  -5.3 |  -6.2 |  -4.3 | NA
      Q1 (menor gasto) | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 318 | 96.7 | 89.5 |  -7.2 |  -8.3 |  -6.1 | NA
      Q1 (menor gasto) | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q1 (menor gasto) | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q1 (menor gasto) | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 318 | 96.7 | 76.8 | -19.9 | -21.8 | -18.0 | NA
      Q2 | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 369 | 91.4 | 80.9 | -10.5 | -11.5 |  -9.6 | NA
      Q2 | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 369 | 91.4 | 78.3 | -13.2 | -14.2 | -12.1 | NA
      Q2 | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q2 | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q2 | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 369 | 91.4 | 58.7 | -32.8 | -34.4 | -31.2 | NA
      Q3 | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 389 | 84.1 | 69.5 | -14.6 | -15.7 | -13.5 | NA
      Q3 | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 389 | 84.1 | 67.4 | -16.7 | -18.0 | -15.5 | NA
      Q3 | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q3 | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q3 | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 389 | 84.1 | 47.3 | -36.8 | -38.3 | -35.2 | NA
      Q4 | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 398 | 75.1 | 58.3 | -16.8 | -17.8 | -15.7 | NA
      Q4 | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 398 | 75.1 | 56.3 | -18.8 | -19.9 | -17.7 | NA
      Q4 | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q4 | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q4 | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 398 | 75.1 | 37.1 | -38.0 | -39.3 | -36.7 | NA
      Q5 (mayor gasto) | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 421 | 51.3 | 33.5 | -17.9 | -18.7 | -17.0 | NA
      Q5 (mayor gasto) | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 421 | 51.3 | 32.3 | -19.0 | -19.9 | -18.1 | NA
      Q5 (mayor gasto) | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      Q5 (mayor gasto) | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      Q5 (mayor gasto) | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 421 | 51.3 | 19.2 | -32.1 | -33.4 | -30.8 | NA
      Sin dato | Hierro | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Hierro | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Hierro | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Hierro | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Hierro | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — Sin dato: ningún hogar con estimación.
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_zinc_expenditure_group] Figura R3.4. Efecto de cada escenario en la ingesta aparente inadecuada de zinc, por quintil de gasto, % y puntos porcentuales (IC 95%)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (menor gasto) | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 318 | 90.9 | 77.8 | -13.1 | -16.7 |  -9.4 | NA
      Q1 (menor gasto) | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (menor gasto) | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (menor gasto) | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q1 (menor gasto) | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 318 | 90.9 | 72.4 | -18.5 | -22.9 | -14.2 | NA
      Q2 | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 369 | 60.3 | 34.5 | -25.8 | -30.1 | -21.5 | NA
      Q2 | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q2 | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 369 | 60.3 | 29.4 | -30.9 | -35.6 | -26.2 | NA
      Q3 | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 389 | 31.7 | 10.7 | -21.0 | -25.2 | -16.8 | NA
      Q3 | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q3 | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 389 | 31.7 | 10.5 | -21.3 | -25.5 | -17.0 | NA
      Q4 | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 398 |  6.6 |  2.0 |  -4.5 |  -6.5 |  -2.5 | NA
      Q4 | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q4 | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 398 |  6.6 |  1.6 |  -4.9 |  -7.1 |  -2.8 | NA
      Q5 (mayor gasto) | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (mayor gasto) | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (mayor gasto) | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (mayor gasto) | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Q5 (mayor gasto) | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 421 |  0.0 |  0.0 |   0.0 |    NA |    NA | NA
      Sin dato | Zinc | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Zinc | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Zinc | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Zinc | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Zinc | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — Sin dato: ningún hogar con estimación.
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_folate_expenditure_group] Figura R3.4. Efecto de cada escenario en la ingesta aparente inadecuada de folato, por quintil de gasto, % y puntos porcentuales (IC 95%)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (menor gasto) | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 318 | 65.1 | 33.2 | -31.8 | -37.3 | -26.4 | NA
      Q1 (menor gasto) | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 318 | 65.1 | 24.5 | -40.5 | -45.6 | -35.4 | NA
      Q1 (menor gasto) | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q1 (menor gasto) | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q1 (menor gasto) | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 318 | 65.1 |  1.0 | -64.1 | -69.3 | -58.9 | NA
      Q2 | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 369 | 43.9 | 13.9 | -30.0 | -35.2 | -24.9 | NA
      Q2 | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 369 | 43.9 | 10.7 | -33.2 | -38.4 | -28.0 | NA
      Q2 | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q2 | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q2 | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 369 | 43.9 |  0.7 | -43.2 | -48.2 | -38.2 | NA
      Q3 | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 389 | 32.9 |  8.6 | -24.3 | -28.3 | -20.3 | NA
      Q3 | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 389 | 32.9 |  7.4 | -25.5 | -29.5 | -21.6 | NA
      Q3 | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q3 | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q3 | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 389 | 32.9 |  0.3 | -32.6 | -37.6 | -27.7 | NA
      Q4 | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 398 | 22.6 |  3.1 | -19.5 | -23.3 | -15.7 | NA
      Q4 | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 398 | 22.6 |  2.6 | -20.1 | -23.9 | -16.2 | NA
      Q4 | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q4 | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q4 | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 398 | 22.6 |  0.0 | -22.6 | -26.5 | -18.7 | NA
      Q5 (mayor gasto) | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación | 421 | 10.7 |  1.2 |  -9.5 | -12.3 |  -6.7 | NA
      Q5 (mayor gasto) | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación | 421 | 10.7 |  1.2 |  -9.5 | -12.3 |  -6.7 | NA
      Q5 (mayor gasto) | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      Q5 (mayor gasto) | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      Q5 (mayor gasto) | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 421 | 10.7 |  0.0 | -10.7 | -13.8 |  -7.5 | NA
      Sin dato | Folato | Harina de trigo con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Folato | Harinas de trigo y de maíz con hierro, zinc y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Folato | Harinas de trigo y de maíz, y arroz con hierro y ácido fólico | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Folato | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Folato | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — Sin dato: ningún hogar con estimación.
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R3.4_vitamin_a_expenditure_group] Figura R3.4. Efecto de cada escenario en la ingesta aparente inadecuada de vitamina A, por quintil de gasto, % y puntos porcentuales (IC 95%)
      
      domain_value | nutrient | scenario | comparator | n | from | to | difference | difference_ci_low | difference_ci_high | mark
      Q1 (menor gasto) | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 318 | 97.2 | 76.5 | -20.7 | -25.2 | -16.3 | NA
      Q1 (menor gasto) | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 318 | 97.2 | 39.4 | -57.8 | -63.9 | -51.6 | NA
      Q2 | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 369 | 93.0 | 53.1 | -40.0 | -45.2 | -34.7 | NA
      Q2 | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 369 | 93.0 | 14.8 | -78.2 | -82.4 | -74.0 | NA
      Q3 | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 389 | 84.3 | 34.8 | -49.5 | -54.9 | -44.1 | NA
      Q3 | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 389 | 84.3 |  5.1 | -79.2 | -83.5 | -74.9 | NA
      Q4 | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 398 | 67.2 | 17.5 | -49.7 | -54.3 | -45.1 | NA
      Q4 | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 398 | 67.2 |  1.0 | -66.2 | -70.9 | -61.4 | NA
      Q5 (mayor gasto) | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación | 421 | 37.5 |  6.6 | -30.9 | -35.6 | -26.1 | NA
      Q5 (mayor gasto) | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación | 421 | 37.5 |  0.7 | -36.8 | -41.7 | -31.9 | NA
      Sin dato | Vitamina A | Harinas de trigo y de maíz, arroz, y azúcar con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      Sin dato | Vitamina A | Harinas de trigo y de maíz, arroz, azúcar, y aceite con vitamina A | Sin fortificación |   0 |   NA |   NA |    NA |    NA |    NA | NA
      — Sin dato: ningún hogar con estimación.
      Panel izquierdo: punto hueco, el escenario de comparación (Sin fortificación); punto lleno, el escenario. Panel derecho: diferencia pareada en puntos porcentuales, con su IC 95%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).
      Ingesta aparente, no ingesta habitual: la proporción de hogares cuyas adquisiciones en el período de referencia, por equivalente de mujer adulta, quedan por debajo del requerimiento. El punto de corte y el enfoque probabilístico se definen sobre la ingesta habitual (IOM 2000b, pp. 73 y 99; IOM 2001, p. 703); es una cifra para comparar escenarios sobre los mismos datos, no una prevalencia de inadecuación.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [R4.1] Figura R4.1. Proporción de cada grupo de alimentos en la ingesta aparente, por nutriente, % (IC 95%)
      
      nutrient | food_group | n | share | ci_low | ci_high | mark
      Hierro | Cereales | 1895 | 32.4 | 31.8 | 33.0 | NA
      Hierro | Raíces y tubérculos | 1895 |  7.4 |  7.1 |  7.6 | NA
      Hierro | Leguminosas | 1895 | 34.3 | 33.6 | 35.1 | NA
      Hierro | Carnes y pescados | 1895 | 11.9 | 11.5 | 12.3 | NA
      Hierro | Huevos | 1895 |  3.9 |  3.8 |  4.0 | NA
      Hierro | Lácteos | 1895 |  1.1 |  1.0 |  1.1 | NA
      Hierro | Grasas y aceites | 1895 |  0.0 |  0.0 |  0.0 | NA
      Hierro | Azúcares | 1895 |  1.4 |  1.3 |  1.4 | NA
      Hierro | Hortalizas | 1895 |  5.1 |  4.9 |  5.2 | NA
      Hierro | Frutas | 1895 |  0.6 |  0.6 |  0.7 | NA
      Hierro | Bebidas | 1895 |  1.3 |  1.3 |  1.4 | NA
      Zinc | Cereales | 1895 | 35.8 | 35.2 | 36.5 | NA
      Zinc | Raíces y tubérculos | 1895 |  2.9 |  2.8 |  3.0 | NA
      Zinc | Leguminosas | 1895 | 18.6 | 18.1 | 19.2 | NA
      Zinc | Carnes y pescados | 1895 | 24.7 | 23.9 | 25.4 | NA
      Zinc | Huevos | 1895 |  3.5 |  3.4 |  3.6 | NA
      Zinc | Lácteos | 1895 |  9.2 |  8.8 |  9.6 | NA
      Zinc | Hortalizas | 1895 |  4.0 |  3.9 |  4.1 | NA
      Zinc | Frutas | 1895 |  0.5 |  0.5 |  0.5 | NA
      Zinc | Bebidas | 1895 |  0.6 |  0.5 |  0.6 | NA
      Folato | Cereales | 1895 | 17.9 | 17.4 | 18.4 | NA
      Folato | Raíces y tubérculos | 1895 |  7.0 |  6.7 |  7.2 | NA
      Folato | Leguminosas | 1895 | 57.1 | 56.3 | 58.0 | NA
      Folato | Carnes y pescados | 1895 |  1.6 |  1.5 |  1.7 | NA
      Folato | Huevos | 1895 |  2.7 |  2.6 |  2.8 | NA
      Folato | Lácteos | 1895 |  2.1 |  2.0 |  2.2 | NA
      Folato | Grasas y aceites | 1895 |  0.0 |  0.0 |  0.0 | NA
      Folato | Hortalizas | 1895 |  8.0 |  7.7 |  8.2 | NA
      Folato | Frutas | 1895 |  3.6 |  3.4 |  3.8 | NA
      Folato | Bebidas | 1895 |  0.0 |  0.0 |  0.0 | NA
      Vitamina A | Cereales | 1895 |  1.3 |  1.2 |  1.4 | NA
      Vitamina A | Raíces y tubérculos | 1895 | 10.5 | 10.0 | 11.0 | NA
      Vitamina A | Leguminosas | 1895 |  0.0 |  0.0 |  0.0 | NA
      Vitamina A | Carnes y pescados | 1895 |  6.5 |  6.2 |  6.7 | NA
      Vitamina A | Huevos | 1895 |  9.5 |  9.1 |  9.8 | NA
      Vitamina A | Lácteos | 1895 | 17.7 | 17.0 | 18.5 | NA
      Vitamina A | Hortalizas | 1895 | 51.3 | 50.2 | 52.4 | NA
      Vitamina A | Frutas | 1895 |  3.2 |  3.0 |  3.4 | NA
      n = 1,895 hogares
      Sin aporte de zinc: grasas y aceites y azúcares.
      Sin aporte de folato: azúcares.
      Sin aporte de vitamina A: grasas y aceites, azúcares y bebidas.
      Aporte de los alimentos sin grupo asignado: hierro 0.6%; zinc 0.2%; folato 0%; vitamina A 0%.
      No es una proporción: se juzga solo por el número de hogares y los grados de libertad (nota técnica, desviación S1).

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT1] Cuadro RT1. Requerimientos y niveles máximos utilizados
      
      nutrient | ear | unit | ul | ul_unit | source
      Hierro |   8.1 | mg |   45 | mg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Zinc |   6.8 | mg |   40 | mg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Vitamina A | 500.0 | µg RAE | 3000 | µg | IOM 2001, Dietary Reference Intakes for Vitamin A, Vitamin K, Arsenic, Boron, Chromium, Copper, Iodine, Iron, Manganese, Molybdenum, Nickel, Silicon, Vanadium, and Zinc
      Folato | 320.0 | µg EFD | 1000 | µg | IOM 1998, Dietary Reference Intakes for Thiamin, Riboflavin, Niacin, Vitamin B6, Folate, Vitamin B12, Pantothenic Acid, Biotin, and Choline

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT2] Cuadro RT2. Norma de presentación utilizada
      
      criterion | value | source | location
      Nivel de confianza del intervalo |  0.95 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (a 95% two-sided confidence interval, Clopper-Pearson, or Korn-Graubard for complex surveys); p. 3
      Mínimo de hogares de una estimación (se suprime por debajo) | 30.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (minimum denominator sample size of 30; below 30, suppress); p. 3
      Tamaño de muestra efectivo mínimo (se suprime por debajo) | 30.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (minimum effective denominator sample size of 30; below 30, suppress); p. 3 (effective sample size: n divided by the design effect; when it is above n, or undefined because there are 0 events or n events, n is used)
      Ancho del intervalo que se presenta sin el control relativo (como máximo) |  0.05 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width above 0 and at most 0.05: present if there are events and the degrees of freedom criterion is met, otherwise flag for statistical review); p. 4
      Ancho del intervalo que se suprime (como mínimo) |  0.30 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width 0.30 or more: suppress); p. 4
      Ancho relativo máximo del intervalo (se suprime por encima, cuando el ancho está entre los dos anchos) |  1.30 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (absolute width between 0.05 and 0.30 and relative width more than 130%: suppress); p. 3 (relative width: absolute width divided by the proportion); p. 4
      Mínimo de grados de libertad (se señala para revisión por debajo) |  8.00 | Parker JD, Talih M, Malec DJ, et al. 2017. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2(175) | Table, p. 2 (fewer than 8 degrees of freedom: flag for statistical review); p. 4 (degrees of freedom: PSUs minus strata as a rule of thumb, computed directly for a subgroup present in a subset of PSUs)
      Desviación S1. Las estimaciones que no son proporciones (medianas, diferencias pareadas, aportes de los grupos de alimentos) se juzgan solo por su número de hogares y sus grados de libertad, y su intervalo se muestra siempre: la norma no da umbrales para ellas (p. 5).
      Desviación S2. Donde la inadecuación es una probabilidad (hierro), la proporción es la probabilidad media, y la norma se aplica a ella. Su varianza es a lo sumo la de un resultado de sí o no, de modo que los criterios de amplitud son conservadores; su tamaño efectivo de muestra es el número de hogares dividido por el efecto de diseño, calculado con la varianza de las propias probabilidades, como lo define la norma. Cero eventos significa una media de exactamente 0 o 1.
      Desviación S3. En este informe, las estimaciones señaladas para revisión estadística se muestran con la marca † y el motivo. La norma permite mostrarlas tras la revisión o suprimirlas (pp. 2, 5).
      Desviación S4. Una proporción con ningún hogar, o con todos los hogares, de la muestra se informa en una frase con su n y el límite de su intervalo de Clopper-Pearson, no como fila de una tabla ni como punto de una figura.
      Estratos con una sola unidad primaria de muestreo: su aporte a la varianza se centra en la media general.

---

    Code
      cat(r$env$exhibit_text(key), sep = "\n")
    Output
      [RT3] Cuadro RT3. Hogares con ingesta aparente inadecuada de hierro, por biodisponibilidad del hierro, % (IC 95%)
      
      bioavailability_pct | n | inadequate | ci_low | ci_high | mark
      5% | 1895 | 99.0 | 98.5 | 99.4 | NA
      10% | 1895 | 79.4 | 77.6 | 81.2 | NA
      15% | 1895 | 49.7 | 47.4 | 52.0 | NA
      n = 1,895 hogares
      Las demás exhibiciones usan una biodisponibilidad del hierro del 10%.

