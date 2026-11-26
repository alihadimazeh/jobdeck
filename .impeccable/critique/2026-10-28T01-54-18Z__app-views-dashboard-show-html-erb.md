---
target: app/views/dashboard/show.html.erb
total_score: 25
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 2
target_identity: "file:/home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb"
target_fingerprint: "sha256:7647c1f34014d441e5342ddc2149fe75f35983b639ec69cf04cb257ce4eebc32"
target_path: /home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb
timestamp: 2026-10-28T01-54-18Z
slug: app-views-dashboard-show-html-erb
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent), both via the test-env system-spec harness

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | H1 names today, rows never say "today"/"tomorrow" ("Due Oct 24, 2026") |
| 2 | Match System / Real World | 3 | Plain trade talk; order rows lean on system states; date format drifts from DESIGN.md |
| 3 | User Control and Freedom | 3 | Clean ways out of landings; a follow-up can't be cleared or snoozed from the card |
| 4 | Consistency and Standards | 2 | Amber = "Quoted" and "late"; 3 of 5 cards have View all; phone landings drop the columns the dashboard rows lead with |
| 5 | Error Prevention | 3 | Landing search keeps its filter; status select can contradict the hidden status_not_in |
| 6 | Recognition Rather Than Recall | 3 | On a 375px landing, same-titled jobs are identical and the call button has no name beside it |
| 7 | Flexibility and Efficiency | 2 | No shortcuts or quick actions; money is tab stop 26 on a phone |
| 8 | Aesthetic and Minimalist Design | 3 | Calm; ~2,270px phone page; wall of same-weight amber badges |
| 9 | Error Recovery | n/a | No forms or failing actions on the dashboard |
| 10 | Help and Documentation | 3 | Empty states and landing notes explain themselves |
| **Total** | | **25/36** | **Acceptable (69%), one point short of Good** |

## Design Specificity Verdict

**LLM assessment:** Information architecture is unmistakably this trade's; the visual shell is stock daisyUI cards of equal weight, so a 30-days-late callback looks as important as a new lead due today.

**Deterministic scan:** CLI clean on dashboard, shared+layouts, jobs, leads. Overlay at 1440 and 375: only the known false positives. 0 real findings.

## Overall Impression

The drill-downs now keep their filter, sort and lateness. What's left is the card's core loop (you can't finish a follow-up where it's shown) and phone landings that strip the context the dashboard rows carried.

## What's Working

- Due Today / Overdue split with server-side urgency sorts; verified with 45 overdue leads and 8 active jobs.
- "View all" lands filtered, sorted, and labeled; the filter survives search and pagination; no horizontal scroll at 320/375/720.
- Keyboard and screen-reader basics: visible Job Blue focus everywhere, named 44px call buttons, clean heading outline, `<time datetime>`.

## Priority Issues

**[P1] A follow-up can't be cleared from the dashboard.** Lead → Edit → change date → save → back; the list never shrinks. Fix: per-row Done / snooze (+1 day / +1 week) via Turbo Stream, optionally logging an ActivityNote. → `/impeccable shape`

**[P1] Phone landings drop the dashboard row's context.** At 375, Jobs keeps Title + Ends, Leads keeps Title + Follow-up; same-titled jobs are identical and the call button has no name beside it. Fix: render landing rows like `_preview_row` (title over a muted subtitle) on phones instead of dropping columns. → `/impeccable adapt`

**[P2] Amber means both a status and lateness.** "Quoted" shares the late amber; on Due Today the status badge is the row's unlabeled right-hand value. Fix: muted status text on Due Today; long-term move `quoted` off `:warning`. → `/impeccable colorize`, then `/impeccable document`

**[P2] Money cards are mid-scroll with no path to the rest.** Below the fold at 1440×900; no View all. Fix: a quiet inline "$X owed · $Y to bill" near the H1; decide the Orders index. → `/impeccable layout`

**[P3] Date copy fights the "Today" framing.** Fix: a `relative_day` helper (today / tomorrow / weekday / "Nov 3", year only when different). → `/impeccable clarify`

## Persona Red Flags

**Alex:** can't clear or snooze in place; 20 tabs to Active Jobs; landing status select can contradict the hidden filter; landing "Search" button reads as plain text.

**Sam:** unlabeled lists (H2s cover it); long run-on row names with a bare status word; money 26+ tabs in on a phone.

**Site lead on a phone:** tap-to-call works well; Overdue landing loses the customer name next to the call icon; Jobs landing shows identical same-titled rows with no address; jobs start ~y=1,050.

## Minor Observations

- Two-line clamping hides the distinguishing tail of long same-prefix titles; 320px truncates the phone number.
- Jobs landing shows "—" for no end date where the dashboard says "Started Oct 12" / "No dates set".
- "Most urgent first" note stays when the Jobs status filter changes.
- "View all" on empty cards; server-rendered "Today" goes stale in a tab left open past midnight.

## Questions to Consider

1. If a follow-up can't be marked done where it's shown, is Due Today a to-do list or a report?
2. Should card order follow role (owner: money; site lead: jobs) rather than one fixed day order?
3. Should lateness escalate visually, or should anything past N days drop into a "stale" bucket?
4. Should "View all" just be a paginated version of the card, using the same row pattern?
