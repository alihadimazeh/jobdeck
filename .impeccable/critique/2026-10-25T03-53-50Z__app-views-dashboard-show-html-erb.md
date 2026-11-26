---
target: app/views/dashboard/show.html.erb
total_score: 24
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 2
target_identity: "file:/home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb"
target_fingerprint: "sha256:237acda0b5cfbda2397473b48586ecbec0554903db5b1adb3631baa728fb1772"
target_path: /home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb
timestamp: 2026-10-25T03-53-50Z
slug: app-views-dashboard-show-html-erb
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent), both via the test-env system-spec harness

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Evening date now correct; rows still say "Due Oct 24, 2026" for today and "Ends Oct 25, 2026" for tomorrow |
| 2 | Match System / Real World | 3 | Strong trade wording; "Overdue" names both a follow-up card and unpaid money |
| 3 | User Control and Freedom | 2 | Nothing can be done from the page except call or New Lead; rescheduling a follow-up is four steps away |
| 4 | Consistency and Standards | 2 | Date format drifts from DESIGN.md; amber means "Quoted" and "late"; "View all" on some cards, even at 0; Jobs drill-down drops the urgency sort |
| 5 | Error Prevention | 3 | tel: link appends an extension's digits to the dialed number |
| 6 | Recognition Rather Than Recall | 3 | Labeled values; after "View all active jobs" the over-running job is row 6 with no end date |
| 7 | Flexibility and Efficiency | 2 | No shortcuts or inline actions; 26 tabs to the first money row; money cards can't go past 5 rows |
| 8 | Aesthetic and Minimalist Design | 3 | Calm; phone page ~6 screens; phone number repeated in subtitle and call label |
| 9 | Error Recovery | n/a | No input or failure paths |
| 10 | Help and Documentation | 3 | Empty states teach; nothing says what "Not Yet Billed" counts |
| **Total** | | **24/36** | **Acceptable (67%)** |

## Design Specificity Verdict

**LLM assessment:** The information design is Jobdeck's own (today-sheet order, tap-to-call, site and crew first, owed vs to bill, days late / over / overdue). The visual layer is generic white cards; specificity lives in structure and copy, not visuals.

**Deterministic scan:** CLI clean on dashboard, shared, layouts. Overlay at 1440 and 375: only the known false positives (Inter; daisyUI drawer transition). 0 real findings.

## Overall Impression

Both previous P1s are fixed and verified (evening date correct at 22:30 EDT; the over-running job is row 1 of 8). The page now tells the truth; what it can't do is let you act on it, or carry its meaning into the drill-downs.

## What's Working

- Preview rows hold at 375/640/1024/1440 with zero overflow; 44px+ targets; container-query stacking.
- Urgency logic on Active Jobs works; every job date is labeled.
- Keyboard and screen-reader base: H1 + H2 per card, Job Blue focus on every stop, named View-all links and call buttons, drawer focus management, correct evening date.

## Priority Issues

**[P1] "View all active jobs" throws away the card's urgency.** Lands on an id-sorted table with no end date or "days over"; the over-running job is row 6 of 8. Fix: pass a sort, have the Jobs index honour Ransack sorts, add an "Ends" column with the badge, and a "Showing active jobs" note like Leads'. → `/impeccable clarify`

**[P1] A today-sheet with no way to act on today.** No reschedule/done on follow-ups, no mark-paid on invoices; each call means open, Edit, change date, save. Fix: a per-row reschedule control (`button_to` patching `follow_up_date`, Turbo Stream row replace, gated by `policy(lead).update?`). → `/impeccable shape`, then `/impeccable harden`

**[P2] The most urgent items aren't the most prominent.** Card order is by time of day, not severity; 40-days-overdue money sits last; Due Today's "Quoted" badge uses the lateness amber. Fix: muted lead status on Due Today rows, amber for lateness only; consider an overdue-money summary near the top. → `/impeccable colorize`, `/impeccable layout`

**[P2] Dates aren't relative and drift from the spec.** "Due Oct 24, 2026" for today, "Nov 03, 2026" zero-padded. Fix: a `relative_day` helper (today / tomorrow / "Nov 3", year only when not current). → `/impeccable clarify`

**[P2] Money cards can't reach past 5 rows; tel: drops extensions.** Fix: strip or encode the extension; settle the top-level Orders index (TODO) or a filtered "View all". → `/impeccable harden`

## Persona Red Flags

**Alex:** no shortcuts; 26 tabs to money; every follow-up is a round-trip; Jobs drill-down needs re-sorting with no sortable headers.

**Sam:** phone number announced twice per follow-up row; "Due Today 3" has no noun; money total outside the heading.

**Site lead on a phone:** Active Jobs starts ~2nd screen; site address has no map link and job rows have no call button; crew name truncates at 375px; no "my jobs" filter (assigned_to is free text).

## Minor Observations

- DESIGN.md Navigation still says four rail links; admins see a fifth (Users).
- "View all" shows on cards with a count of 0.
- Due Today sorts by id.
- Ragged column heights at 1440; long eye travel on full-width job rows.
- Very large totals wrap to their own line in narrow cards.

## Questions to Consider

1. If this is a today-sheet, why can't you finish anything on it?
2. Which costs the business more, overdue calls or overdue invoices, and should the layout weigh them that way?
3. On a phone, is this page for the office PM or the site lead?
4. Does the owner want a money list, or one line: oldest debt and invoices over 30 days?
