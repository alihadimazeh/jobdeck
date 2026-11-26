---
target: app/views/dashboard/show.html.erb
total_score: 20
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 3
target_identity: "file:/home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb"
target_fingerprint: "sha256:efe70e045125cf728987286ecbf005ab183e73aadd0bd96c4a3c596d0e18e7fa"
target_path: /home/ahm/Work/projects/jobdeck/app/views/dashboard/show.html.erb
timestamp: 2026-10-21T12-43-37Z
slug: app-views-dashboard-show-html-erb
---
Method: dual-agent (A: design review sub-agent · B: detector + browser sub-agent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Counts are true totals, but nothing shows how late anything is: follow-up is a bare date, orders sort by `due_date` without showing it, no $ outstanding |
| 2 | Match System / Real World | 2 | "Outstanding Orders" includes unbilled `draft`/`confirmed` orders; a contractor hears "outstanding" as money owed |
| 3 | User Control and Freedom | 3 | Read-only page with nav always present; "View all" drops the card's filter |
| 4 | Consistency and Standards | 2 | "View all" → unfiltered lists; Orders card has no header action so its table sits ~24px higher; row links get browser-default focus, not the 2px Job Blue ring |
| 5 | Error Prevention | 3 | Little to prevent; duplicate job titles with no site address invite opening the wrong job |
| 6 | Recognition Rather Than Recall | 2 | Row links look like plain text; stat tiles look clickable but aren't |
| 7 | Flexibility and Efficiency | 1 | No quick actions (New Lead, tap-to-call), no drill-down, no filtered deep links |
| 8 | Aesthetic and Minimalist Design | 3 | Clean and on-token; stat strip repeats the three card titles verbatim |
| 9 | Error Recovery | n/a | Read-only surface, no error paths |
| 10 | Help and Documentation | 2 | Nothing says what "needing follow-up" or "outstanding" counts |
| **Total** | | **20/36** | **Acceptable (56%)** |

## Design Specificity Verdict

**LLM assessment:** Well-executed generic. Three stat tiles over three identical title/customer/date tables could be relabeled for any CRM. None of PRODUCT.md's positioning reaches this screen: follow-up is a date rather than a call to make (no phone, though `customers.phone` is NOT NULL), active jobs show no site address (the stated differentiator), and nothing expresses money lagging the work. The "Site Clipboard" north star (read at a glance, on site, phone in hand) isn't served: at 375px the first viewport is the H1 plus three stacked counters.

**Deterministic scan:** CLI detector clean (exit 0) on the dashboard view and on `app/views/shared` + `app/views/layouts`. The in-page overlay reported 3 findings at both 1440 and 375, all false positives: `overused-font` (Inter, deliberate and self-hosted), and two `layout-transition` hits from daisyUI's compiled drawer transition (sidebar and body; vendor CSS, never animates at `lg+`). The detector caught nothing the review missed; every real problem here is layout, semantics, and copy, which pattern-matching doesn't see.

## Overall Impression

Disciplined and consistent with the design system, but it answers "how many?" when a contractor opens it to learn "what do I do today?". The biggest opportunity: make it a today-sheet (calls to make, sites to visit, money owed) instead of three equal counters.

## What's Working

- **System discipline.** Everything renders through shared partials (`_page_header`, `_stats`, `_card`, `_table`, `_empty_state`, `status_badge`); no raw colors, no card shadows. Fixes will be cheap.
- **Honest numbers.** Stats are true totals with 5-row previews, and `includes(:customer)` avoids N+1. No "count = rows shown" lie.
- **Sound semantics.** One H1, an H2 per card, labeled nav, skip link, real `<table>`/`<th>`, and empty states as colspan rows.

## Priority Issues

**[P1] Money column hidden at laptop and phone widths.** `lg:grid-cols-3` (show.html.erb:13) squeezes a 4-column orders table into ~227px at 1024px (scrollWidth 370 vs 227): Status and Total sit off-card behind a scroll with no visible cue. Total also clips at 375px; order numbers wrap to 3 lines even at 1440. The dollar figure is the most important cell on the page, and PRODUCT.md says it must not break on a smaller screen.
Fix: go 3-up only at `xl` (or 2+1 with orders full width); `whitespace-nowrap` + right-align on order # and Total; on phones render rows as stacked list items (title + meta line) rather than a squeezed table. → `/impeccable adapt`

**[P1] "Outstanding Orders" mixes unbilled work with money owed.** `Order.outstanding` = draft + confirmed + invoiced (order.rb:17). In seed data every visible row is a Draft (one is $0.00). No $ total, no due date shown despite sorting by it.
Fix: split into "To bill" (draft/confirmed) and "Waiting on payment" (invoiced, with due date / days overdue), and put the $ sum in the card header and stat. → `/impeccable clarify`

**[P1] No "what do I do today" hierarchy; not authored for the trade.** The stat strip repeats the card titles; all three cards weigh the same.
Fix: lead with follow-ups (days overdue + customer phone as a `tel:` link); show site city/address on active jobs (also disambiguates the two identical "Kitchen Renovation — Mitchell Residence" rows); either link the stats to filtered lists or drop them and put counts in card headers, which frees the phone's first viewport. → `/impeccable distill`, then `/impeccable shape`

**[P2] "View all" loses scope; card headers misalign.** Links go to unfiltered `leads_path`/`jobs_path`. Orders has no header action, so its table starts higher than its neighbors.
Fix: link to Ransack-filtered URLs (integer enum values for status, per the CLAUDE.md enum trap); give card headers a fixed min-height or a consistent action/count slot. → `/impeccable polish`

**[P2] Row affordance and focus miss DESIGN.md.** `<tr class="hover">` (lines 22, 42, 60) does nothing in the vendored daisyUI 5 (only `row-hover` exists), so rows have no hover. Row links are ink-colored with no underline. The focus rule (application.css:95) covers `.btn, .menu a, …` but not plain links, so row links get the browser's 1px default ring instead of the 2px Job Blue one.
Fix: `row-hover` (or the whole row as the target); extend the focus-visible rule to `main a`; give the title cell a link signifier. → `/impeccable audit`, then `/impeccable polish`

## Persona Red Flags

**Alex (power user):** no New Lead from the first screen for a walk-in; stat tiles look like drill-downs but are inert; "View all" lands unfiltered, so Alex re-filters by hand; no outstanding total.

**Sam (keyboard / screen reader):** row-link focus is the 1px browser default; clipped tables sit in `.overflow-x-auto` wrappers with no `tabindex`/`role="region"`/label, so a keyboard user can't scroll to Total; stat tiles are plain divs announced as bare "0 / 9 / 6".

**"Dave", site lead on a phone between jobs (from PRODUCT.md):** first viewport at 375px holds nothing actionable; no `tel:` link to make the follow-up call; no site address on active jobs; Total clipped; each order row ~88px tall because the number wraps, so ~5 rows per screen.

## Minor Observations

- The stats bar sits on the canvas while cards are white: two surface tones for one layer (`_stats.html.erb:2`).
- The empty state renders under a header row of empty columns; hide headers when empty and offer "Log a lead" to roles allowed to create one.
- Active jobs sort by `start_date` ascending, so a job started in June tops the list and undated jobs sink.
- Muted header/stat text computes to Ink at ~60%, not the 70% DESIGN.md specifies (passes AA, but it's token drift).
- `DashboardController` has no `authorize`/`policy_scope`, unlike every other controller. Behavior is identical today (all scopes are `scope.all`), but it's a convention gap.
- Uneven card heights at 1440: Leads is mostly blank when there are no follow-ups.

## Questions to Consider

1. If the owner opens only this page, what one number should they leave with? Today it's "6 Outstanding Orders", which are unbilled drafts.
2. Should the Orders card be what finally forces the top-level Orders index decision? Its own comment admits it's a dead end.
3. Desk dashboard or site dashboard? If the phone is a primary device, should the phone layout lead with today's calls and sites instead of totals?
4. Do the stat tiles earn their space, or are they a convention borrowed from software-team tools?
