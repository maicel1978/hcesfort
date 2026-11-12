# Model routing and handoffs

The maintainer's quota is limited. The most capable model (Fable) is used only where its reasoning changes the result; implementation and mechanical work go to Opus or Sonnet. Every session follows this document.

## At the start of every session
1. State which model you are, as far as you know. If unsure, ask.
2. Read `docs/handoff.md` (if present) and continue from it.
3. Check the model recommended for the next task in the table below. If it is not you, say so before working and wait for the maintainer.

## Which model for which work

| Work | Model |
|---|---|
| Design that fixes contracts or the public API; methodological decisions; reviewing a methodological choice against the literature | **Fable** |
| Implementing an approved design; tests; porting code from the original analysis; fixing failing checks | **Opus 5.5** |
| Mechanical work: documentation wording, renames, lint fixes, NEWS, roadmap updates | **Sonnet 5.5** |

Recommended model per roadmap task (the roadmap may renumber; match by content):

| Task | Content | Model |
|---|---|---|
| 2 | Data contracts, classed errors, audit log | Fable |
| 3 | Synthetic example data | Opus |
| 4 | Reference tables with sources | Opus |
| 5 | Adult female equivalents | Opus |
| 6 | Unit conversion, outlier flag | Opus |
| 7 | Composition link and coverage; `unmatched_foods()` | Opus |
| 7b | `check_crosswalk()` (crosswalk quality controls) | Opus |
| 8 | Apparent intake | Opus |
| 9 | Unfortified baseline, scenarios, vehicle coverage | **Fable** designs (level basis, enrichment subtraction); Opus implements |
| 10 | Inadequacy (cut-point, iron probability) and UL forms | **Fable** designs; Opus implements |
| 11 | Design-based estimation, paired differences | Opus |
| 12 | Vignettes, website | Sonnet |
| v0.2 | Food-matching support module | **Fable** designs; Opus implements |

## When to stop and ask for a switch

**Opus or Sonnet → Fable.** Stop when:
- the same test or check fails after two genuine attempts;
- a methodological question is not settled by `CLAUDE.md`, the specification or `docs/analysis-map.md`;
- a change would alter a data contract or an exported function's interface;
- a result disagrees with the original analysis and the reason is not obvious.

**Fable → Opus or Sonnet.** Stop when:
- the design of the current task is written and approved, and what remains is implementation;
- the remaining work is mechanical (tests from an agreed list, documentation, lint, renames).

**Any model → stop.** When the session quota (if visible to you) passes 85%, or the maintainer must decide something.

## How to stop (handoff protocol)
1. Finish or revert the current change: never leave a broken state. Commit and push.
2. Update `docs/roadmap.md` (tick what is done; add sub-items if a task was split).
3. Overwrite `docs/handoff.md` with: date; model that worked; what was done (commits); exact next step; open questions; recommended model for the next session.
4. Tell the maintainer in Spanish, in this format:

```
PARA AQUÍ. Cambia a: <modelo>.
Motivo: <una línea>.
Estado: <commit> en main, check en verde / en rojo.
Mensaje para la nueva sesión: Lee CLAUDE.md, docs/model-routing.md y docs/handoff.md, y continúa.
```

## Each new session
The maintainer opens a new session with the recommended model and sends only:
`Lee CLAUDE.md, docs/model-routing.md y docs/handoff.md, y continúa.`
