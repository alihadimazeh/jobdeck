# Jobdeck UI/UX Redesign — Step-by-Step Summary

> **Historical record.** The slate + safety orange palette below was replaced by navy + blue
> right after this redesign (merged in PR #42). For the live palette and design rules, see
> [`DESIGN.md`](DESIGN.md) and `CLAUDE.md` → "Design System".

High-level reference for the daisyUI redesign, broken into small steps on
`feature/ui-foundation-prep`. Full technical detail lives in
`~/.claude/plans/using-the-design-skill-immutable-hippo.md` (the original design plan)
and `~/.claude/plans/let-s-tackle-the-ui-ux-fancy-pnueli.md` (this chunked execution plan) —
this file is just the plain-language "what happened and why" version.

**Design direction:** Minimalism/Swiss + Data-Dense style, "industrial slate + safety
orange" color palette, daisyUI (Tailwind plugin) as the component/theme layer, self-hosted
Inter font, light theme only for now (structured so dark mode is a later drop-in).

---

## ✅ Done (Steps 1–15 — foundation + every resource restyled + cleanup + dashboard + polish)

**1. Prep** — Deleted the unused `hello_controller.js` scaffold leftover.

**2. Vendor daisyUI + Inter** — Downloaded daisyUI's plugin files (pinned to release
v5.7.37, no Node/npm needed) and the Inter variable font, committed them, wired to
nothing yet.

**3. Wire the theme + font** — Set up the actual color palette (safety orange primary,
slate neutrals) as a daisyUI theme, switched the whole app to Inter. First step where the
app visibly looks different — new typeface everywhere, no layout changes.

**4. Shared helpers** — Added reusable helper methods: `status_badge`, `format_date`,
`format_currency`, a `btn` wrapper, and fixed a real bug for free — nested pages (like a
Quote or Order) now correctly highlight their parent section (Leads/Jobs) in the sidebar,
which they didn't before.

**5. Shared component partials** — Built the reusable building blocks every page will use:
page headers, cards, tables, badges, form fields/errors, empty states, the row "⋯" actions
menu, flash messages, and the sidebar/navbar content itself. None of this was hooked up to
a real page yet — just built and tested in isolation.

**6. Rebuild the app shell** — This is where it got visible again: replaced the old sidebar
layout with a proper responsive drawer (daisyUI) — permanent sidebar on desktop, a
collapsible drawer on mobile/tablet. Added a "skip to content" link and other accessibility
basics. Every page now renders inside this new shell.

**7. Drawer accessibility** — Added the small bit of JavaScript needed to make the mobile
drawer keyboard/screen-reader friendly: focus moves into the drawer when it opens and
back to the button when it closes, Escape key closes it. Caught and fixed two real bugs
here using an actual browser-driven test (not just a static check).

**Net result of 1–7:** new look and feel (typeface, colors, responsive nav shell), but the
actual page *content* (customer lists, lead forms, etc.) still looks like the old design.
That starts with Step 8.

**8. Customers** — the reference implementation: new page headers, tables, status badges,
the row actions menu (replacing the old dropdown, tested for real in a browser for the
first time), detail cards, and forms with proper error handling and focus management.
First merged in `feature/customer-archive` (the separate "Archive" work that was sitting
on its own branch) so the Archive action was built in from the start. Every other resource
below repeats this same pattern.

---

Same pattern as Customers, applied to each remaining resource in turn — index page,
individual row, detail/show page, and the create/edit form all get swapped over to the
new shared components.

**9. Leads** — same pattern as Customers. Confirms the pattern generalizes to a resource
with related records (a lead's job and quotes shown on its detail page). Found and fixed a
real gap in the shared form-field component along the way (it had no way to show a
"Select a customer..." blank prompt on a dropdown — Customers didn't need one, Leads did).

**10. Jobs** — same pattern as Customers. Third resource in a row confirming the pattern
holds; reused the address-formatting helper built for Customers, and this was the last
resource using the old badge-color helper methods, so those got deleted as dead code.

**11. Quotes** — same pattern, plus reworking the room/line-item editor grid so it's usable
on a phone screen (no JavaScript changes — the estimation tool keeps working exactly as-is,
verified with a real click-through: add/remove a room, add a line item, run the estimation
tool end-to-end, all in an actual browser). Also fixed a pre-existing accessibility bug
found along the way (the Labor/Material Rate inputs had no label association at all) and a
testing-setup gap (aria-label-based accessible names weren't being checked by the test
tooling by default).

**12. Orders** — same pattern, plus the same mobile-friendly rework for its line-item
editor. **All five resources (Customers, Leads, Jobs, Quotes, Orders) are now restyled.**

**13. Retire the old dropdown menu code** — `dropdown_controller.js` (the old kebab-menu
implementation) deleted. Checked the actual browser console, not just curl, to confirm
nothing broke.

**14. Dashboard** — the app's new home page (root path). Three sections — leads needing
follow-up, active jobs, outstanding orders — each showing up to 5 with a real total count.
Checked first that the parallel Phase-4 work hadn't already built one (it hadn't) before
building fresh. Added "Dashboard" as the first sidebar link.

---

**15. Small polish items** — favicon (SVG + regenerated PNG), PWA manifest colors, a real
branded email template (there wasn't one at all before), and the 5 static error pages
(400/404/406/422/500) recolored to match. All outside the main app pipeline by design (an
error page has to work even if the app itself is down), so each got checked in whatever
way actually fits it — an HTML parser pass, a direct template render, an actual browser
screenshot of the 404 page.

---

**16. Final sweep** — done. Grepped for leftover old styling (clean). Ran a real
accessibility/contrast pass rather than assuming the per-resource work already covered it,
and found two genuine regressions the earlier steps had introduced:

- **Touch targets under 44px, again.** The Step 3 CSS bumped `.btn` to a 44px floor but its
  `.btn-sm` variant was left at 36px, and the row-actions popover's menu links were only
  33px — so the kebab trigger, the room/line-item "remove row" buttons, and the popover's
  Edit/Delete links all fell back under the exact target the original audit (A2/U8) asked
  for. Fixed by unifying `.btn-sm` to 44px and adding the same floor to the popover menu
  links; re-measured with a real headless-browser check afterward (all 44px) and
  screenshotted a couple of dense pages to confirm no visual regression.
- **A real contrast failure**, not just a theoretical one: `btn-primary`'s white text on
  the brand orange measured 3.56:1 — below the 4.5:1 AA minimum for normal text. Fixed by
  making the button text dark navy instead of white (5.02:1), leaving the orange itself
  untouched. Checked every other color pairing in the theme by hand afterward — all already
  passed comfortably.

Also verified `prefers-reduced-motion` genuinely disables the drawer/toast transitions at
runtime (emulated via Chrome DevTools, not just read from the CSS source), then re-ran the
whole test suite (19 Minitest + 251 RSpec) clean after both fixes.

Updated `CLAUDE.md`: replaced the old "Planned: UI Revamp" section with a real "Design
System" section documenting the finished theme, palette, and component set, plus what's
still intentionally not done. Updated `TODO.md`'s audit checklist item-by-item — most items
are checked off, a few note they were solved differently than originally scoped (e.g. the
old dropdown's ARIA gaps were fixed by deleting it and switching to daisyUI's native Popover
API instead of patching it), and three stay open because they're genuinely out of scope for
a visual redesign (Pagy/Ransack pagination, `tax_rate` percent-entry semantics, a Customer
status filter).

**The 16-step plan is complete.**

---

## Noted, not scheduled yet

- Try a "navy + blue CTA" color scheme in place of the current "industrial slate + safety
  orange" — see `TODO.md` → Follow-up PRs. Deliberately picked up only when you say so, not
  automatically, since it means re-running the same contrast/badge-variant checks across
  all 5 resources a second time.

## Where things stand

- **Branch:** `feature/ui-foundation-prep` (not merged to `main` yet)
- **Commits so far:** 18 (7 for Steps 1–7, one merging in `feature/customer-archive`, one
  fixing a test for that merge's behavior change, one each for Steps 8–15, one for Step 16)
- Every step has been covered by real automated tests (including, as of Step 7, tests that
  drive an actual browser) and a full regression run of the existing test suite before
  being committed. Test suite is now at 251 RSpec examples + 19 Minitest, up from 122/14
  before this work started.
- Not yet done: merging this branch to `main`, and the deferred navy+blue color-scheme pass
  above.
