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
timestamp: 2026-10-25T04-12-48Z
slug: app-views-dashboard-show-html-erb
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent), both via the test-env system-spec harness. Reviewer A scored heuristic 9 as 3 (28/40); normalized to n/a like every earlier run for a like-for-like 25/36.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Today-anchored H1 and lateness badges; "Ends Oct 25, 2026" (tomorrow) looks like any far date |
| 2 | Match System / Real World | 3 | Trade talk; "Overdue" card title vs "N days overdue" on invoices |
| 3 | User Control and Freedom | 3 | Landing notes offer "Show all leads" / "Default order"; Leads search silently drops the follow-up filter |
| 4 | Consistency and Standards | 2 | Jobs landing adapts to phones, Leads doesn't; amber means Quoted, late, over and Invoiced; date format drifts |
| 5 | Error Prevention | 3 | The dropped filter can surface converted leads to call |
| 6 | Recognition Rather Than Recall | 3 | Labeled values; Jobs phone landing can't tell same-titled jobs apart |
| 7 | Flexibility and Efficiency | 2 | No shortcuts; 26 tabs to money; money cards have no drill-down |
| 8 | Aesthetic and Minimalist Design | 3 | Calm; phone page 2337px, Active Jobs starts at y=1064 |
| 9 | Error Recovery | n/a | No forms on this page |
| 10 | Help and Documentation | 3 | Empty states and landing notes explain themselves |
| **Total** | | **25/36** | **Acceptable (69%)** |

## Design Specificity Verdict

**LLM assessment:** A contractor's day sheet in content and structure; generic daisyUI in visual language. The specific feel stops at the "View all" landings, which fall back to stock Ransack tables. Evening time-zone fix confirmed (22:30 EDT shows Sat, Oct 24).

**Deterministic scan:** CLI clean on dashboard, shared, layouts, jobs. Overlay at 1440 and 375: only the known false positives. 0 real findings.

## Overall Impression

The dashboard itself is solid; the gaps have moved to its edges: the Leads landing and the money cards.

## What's Working

- Container-query rows: zero overflow at 375/1024/1440 even with extreme content.
- One-tap, accessible calling with named 44px targets and Job Blue focus everywhere.
- Urgency carries through to the Jobs landing, with a note saying so.

## Priority Issues

**[P1] Leads landing loses the dashboard's urgency, and hides the Follow-up column on phones.** Table overflows by ~150-176px at 375 with no cue; bare dates instead of "N days late"; no call button. Fix: the Jobs treatment for `_lead` (follow-up mode, hide Customer/Status below sm, lateness badge, maybe call). → `/impeccable adapt`

**[P1] Searching on a filtered Leads landing silently widens the list.** No hidden fields for follow_up_date / status_not_in; a search on Overdue returned today's and a Converted lead, and the note vanished. Fix: carry the filters as hidden fields (as Jobs carries its sort) or a removable chip. → `/impeccable harden`

**[P2] Jobs phone landing can't tell same-titled jobs apart.** Fix: a muted second line (site or customer) under the title below sm. → `/impeccable clarify`

**[P2] Money cards are a dead end.** No "View all"; past 5 invoices the overdue-first list is unreachable. Product decision (Orders index). → `/impeccable shape`

**[P2] Amber means too many things.** Quoted, late, over and Invoiced share it; a Quoted lead in Due Today looks late. Fix: muted status text on Due Today rows. → `/impeccable colorize`

## Persona Red Flags

**Alex:** no shortcuts; 2 tab stops per lead row, 26 to money; can't see more than 5 orders; landing search drops his filter.

**Sam:** clean headings and visible focus; row names run the whole row together and the phone number repeats on the call button.

**Site lead on a phone:** Active Jobs starts at y=1064 below 10 lead rows; site address truncated and not tappable; the address disappears on "View all".

## Minor Observations

- Dates zero-padded with year; Jobs landing shows "—" where the dashboard said "Started Oct 12".
- Empty cards still show "View all"; empty Due Today takes 207px at the top on a phone.
- Landing "Search" button looks like plain text; no link back to Today; Leads status select says "Any status" while excluding converted/lost.

## Questions to Consider

1. Should phone order follow the role rather than the time of day?
2. Do Due Today and Overdue earn two cards, or one urgency-sorted call list?
3. Should "View all" open a dedicated Follow-ups view built from the dashboard's rows?
4. What would "Ends tomorrow" / "Due today" change at a glance?
