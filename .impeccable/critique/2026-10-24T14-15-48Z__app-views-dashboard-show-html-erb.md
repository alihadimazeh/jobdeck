---
target: app/views/dashboard/show.html.erb
total_score: 23
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 1
target_identity: "file:/home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb"
target_fingerprint: "sha256:def4a184a537a00c5f9925b2a2c61153f19651c82518aeceeee5096aa1c7827a"
target_path: /home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb
timestamp: 2026-10-24T14-15-48Z
slug: app-views-dashboard-show-html-erb
closed: true
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent), both via the test-env system-spec harness

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | True counts and lateness badges; but no date anchor, and today's follow-ups can be capped out of the preview |
| 2 | Match System / Real World | 3 | Trade wording throughout; money rows still lead with "ORD-2026-0003" and job dates are unlabeled |
| 3 | User Control and Freedom | 3 | Read-only, every row a link, no traps |
| 4 | Consistency and Standards | 3 | Close to DESIGN.md; ghost-button focus ring is ink not Job Blue; "Today" is plain text while late rows are badges |
| 5 | Error Prevention | 3 | Call button sits 0px from the row link: one mis-tap dials a customer |
| 6 | Recognition Rather Than Recall | 2 | "View all" opens unfiltered, id-sorted indexes; header totals and job dates unlabeled |
| 7 | Flexibility and Efficiency | 2 | Tap-to-call is the only accelerator; no filtered drill-down; ~26 tabs to reach the sidebar on desktop |
| 8 | Aesthetic and Minimalist Design | 3 | Calm and clean; 77px card headers, titles clipped at 375px |
| 9 | Error Recovery | n/a | No inputs or failing actions on this page |
| 10 | Help and Documentation | 1 | Empty states never say how things get onto the list; "$0.00" headers unexplained |
| **Total** | | **23/36** | **Acceptable (64%)** |

## Design Specificity Verdict

**LLM assessment:** The content is now authored for the trade (tap-to-call follow-ups, site address first, payment vs. unbilled split, "N days late"), but the form is still a generic 2×2 card grid. Nothing frames it as a today-sheet: the H1 is "Dashboard" and today's date appears nowhere, though every row's state is relative to today.

**Deterministic scan:** CLI clean (exit 0) on `app/views/dashboard` and `app/views/shared` + `layouts`. In-page overlay at 1440 and 375: `overused-font` (Inter, deliberate) and two `layout-transition` hits from daisyUI's compiled drawer CSS. 0 real findings; every issue below came from review, not pattern matching.

## Overall Impression

A real step up: the money column is never hidden, the money means one thing, and the follow-up list is first. The biggest remaining gap: the "today" sheet can fail to show today, because the oldest overdue leads fill the 5-row preview and "View all" can't get you back.

## What's Working

- Preview rows: whole-row links 64–84px tall, two-line titles, no overflow even at 320px, a clear inset 2px Job Blue focus ring.
- The call button is built right: beside the link, not nested; `aria-label` names the customer and number; icon `aria-hidden`.
- Honest money: invoiced vs. drafts never mix, overdue first, "No due date" spelled out, header totals are true sums.

## Priority Issues

**[P1] The today-sheet can hide today, and "View all" can't recover it.** Follow-ups sort oldest first and cap at 5 (dashboard_controller.rb:7), so five stale leads push today's off the card; "View all" opens all leads sorted by id. Fix: reserve the top of the card for due-today (or split "Due today" / "Overdue"), and link "View all" to a Ransack-filtered, follow-up-sorted leads list (integer status values); Jobs' "View all" to active only. → `/impeccable clarify` / `/impeccable harden`

**[P2] Active Jobs rows say nothing about today.** Bare unlabeled `start_date`, always in the past; `end_date` and `assigned_to` unused. Fix: "Ends Oct 30" / "Started Sep 24" with a label, a soft "N days over" badge past `end_date`, crew from `assigned_to`. → `/impeccable clarify`

**[P2] Money rows titled by system ID; header totals unlabeled.** Fix: job title as the row title with "Customer · ORD-…" beneath; headers read "$11,395.75 owed" / "$152,940.50 to bill" (or fold into the heading's accessible name). → `/impeccable clarify`

**[P2] App-shell keyboard order hits the dashboard first.** Phone: tab stop 2 is the 0×0 unnamed drawer checkbox (application.html.erb:29). Desktop: sidebar comes after `<main>` in DOM, so nav is reached after every row. Fix: `tabindex="-1"` on the checkbox (the label handles it); a skip-to-navigation link or nav-first order from `lg`. → `/impeccable harden`

**[P2] Tap-to-call is undersized and crowded.** 40×44px (`.btn-sm` fix only sets min-height; `btn-square` width stays 40px), flush against the row link, number not visible. Fix: `size-11`, 4–8px gap; below `sm`, move the late badge under the title so titles keep their width. → `/impeccable adapt`

## Persona Red Flags

**Alex:** "View all" drops the filter; money cards have no drill-down; no "+N more"; ~26 tabs to the sidebar.

**Sam:** phone tab stop 2 is an invisible unnamed checkbox; ghost-button focus ring is ink; money total sits outside the heading with no label; job rows end in a bare date. Lateness is text, not color-only (good).

**Site lead on a phone:** first screen is all "late" badges with no date; today's follow-up can be missing; call button flush against the row; Active Jobs starts ~675px down and shows only a past start date; address truncated and not a map link.

## Minor Observations

- "Today" as plain text vs. badges for late rows; consider a soft info badge.
- Empty states lack a hint/CTA; "$0.00" headers add noise when empty.
- Header totals inherit 16px, louder than the 14px titles (bends the No Shouting rule).
- "Confirmed" info-blue badge sits next to Job Blue links.
- `DashboardController` bypasses `policy_scope` (same behavior today).
- Viewer: no "New Lead", header right side empty; owner's money cards come 3rd and 4th on a phone.
- Four 77px card headers ≈ 300px of chrome on a phone.

## Questions to Consider

1. If it's a today-sheet, why is the H1 "Dashboard" and not "Today · Sat Oct 24"?
2. Should a lead 15 days late keep pushing today's lead off the page, or does stale need its own bucket?
3. What does a site lead need from Active Jobs: when it started, or who's on it and whether it's running over?
4. Should the owner/viewer get the same card order as the person on site?
