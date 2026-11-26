---
target: app/views/dashboard/show.html.erb
total_score: 25
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 2
target_identity: "file:/home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb"
target_fingerprint: "sha256:237acda0b5cfbda2397473b48586ecbec0554903db5b1adb3631baa728fb1772"
target_path: /home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb
timestamp: 2026-10-25T02-50-46Z
slug: app-views-dashboard-show-html-erb
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent), both via the test-env system-spec harness

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | "Today" is UTC: after 8pm Eastern the H1 shows tomorrow and today's calls count as overdue |
| 2 | Match System / Real World | 3 | Trade voice throughout; amber "Quoted" status sits beside amber "N days late" |
| 3 | User Control and Freedom | 3 | Plain links, Back works; searching the filtered Leads list silently drops the dashboard filter |
| 4 | Consistency and Standards | 3 | Right-hand value means status in one card, lateness in the next; job-titled money rows land on an ORD-titled page |
| 5 | Error Prevention | 3 | tel: link appends an extension's digits to the number, dialing a wrong number |
| 6 | Recognition Rather Than Recall | 3 | Everything labeled; "View all" lands on a table with no lateness or call button |
| 7 | Flexibility and Efficiency | 2 | Tap-to-call only; money cards have no way past 5 rows; 19 tab stops through the follow-up cards |
| 8 | Aesthetic and Minimalist Design | 3 | Clean and on-system, but five equal-weight cards and up to 8 tinted badges above the fold |
| 9 | Error Recovery | n/a | No input or error path |
| 10 | Help and Documentation | 3 | Empty states teach how rows arrive |
| **Total** | | **25/36** | **Acceptable (69%), at the edge of Good** |

## Design Specificity Verdict

**LLM assessment:** Authored for the trade in content and structure ("Today" framing, day-order cards, "days late" vs "days overdue", crew and site first, labeled money, tap-to-call, teaching empty states). The form is still five identical cards on a 2-column grid: nothing visually says the calls outrank the billing backlog.

**Deterministic scan:** CLI clean on `app/views/dashboard`, `shared`, `layouts`. Overlay at 1440 and 375: only the known false positives (`overused-font` Inter; daisyUI drawer `layout-transition`). 0 real findings.

## Overall Impression

Close to Good. The remaining problems are less about layout and more about truth: the page's "today" is UTC, and the most urgent job (one running over) can be cut from the preview.

## What's Working

- Phone-first rows: container-query stacking, two-line titles, true 44px call button with a gap, no overflow at 375/640/1024/1440 even with extreme content.
- Copy and labels in the trade's voice; empty states teach the pipeline.
- Accessibility base: one H1, H2 per card, Job Blue focus ring on every stop, named call buttons and per-card "View all" names, New Lead hidden for viewers.

## Priority Issues

**[P1] "Today" is UTC, not the business's day.** No `config.time_zone`; from 8pm Eastern the H1 shows tomorrow, today's calls count as overdue, Due Today shows tomorrow's. Fix: set `config.time_zone` (later a per-business setting). → `/impeccable harden`

**[P1] A job running over can be hidden.** Active Jobs sorts by start_date with a 5-row cap; a job 5 days past its end date was 6th and never shown. Fix: order by urgency (running over first, then nearest end date, then start date). → `/impeccable clarify`

**[P2] Five equal-weight cards; no reading order beyond the grid.** Fix: give Due Today primary treatment; add "N overdue" to money headers; drop the status badge from Due Today rows so badges mean urgency. → `/impeccable layout`, then `/impeccable quieter`

**[P2] "View all" breaks the flow.** Leads landing has no lateness or call action, the Follow-up column is off-screen at 375px, search drops the filter; Overdue sorts oldest first, so the freshest misses get cut. Fix: hidden filter fields in the search form; lateness + call on the filtered list (or reuse the preview row); reconsider Overdue sort. → `/impeccable adapt`

**[P3] tel: details.** Extensions get appended to the dialed number; long names truncate the phone off-screen. Fix: dial with `,` pause or drop the extension; phone on its own line. → `/impeccable harden`

## Persona Red Flags

**Alex:** 19 tab stops through the follow-up cards; money cards can't go past 5 rows; job-titled order rows land on "ORD-…" pages.

**Sam:** row names end in a bare status word ("New"); lists unlabeled (H2 covers it); "Due Today 3" has no noun. Focus rings correct everywhere tested.

**Site lead on a phone:** first screen is right (calls); the over-running site is ~1,000px down and may not appear; site line truncates with no map link; "View all overdue" lands on a squeezed table with no call button.

## Minor Observations

- "View all" text sits ~13px left of the row values' right edge (btn padding).
- Full-width Active Jobs rows at 1440 leave ~900px between title and date.
- `format_date` reads "Nov 04, 2026"; in-year dates could be "Nov 4" like the header.
- First-run (all empty) has no "log your first lead" CTA.
- The `status_not_in` filter isn't represented in the Leads form.

## Questions to Consider

1. If it's a today-sheet, why are the calls and the billing backlog the same size?
2. Is the 30-days-late lead the first call, or the one to mark lost? Split "missed this week" from "going cold"?
3. Should "View all" ever leave the row format?
4. What does the owner (viewer role) want first: the PM's call list, or the money line?
