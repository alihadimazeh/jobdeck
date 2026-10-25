# Jobdeck — Task Tracker

Open work only. When an item ships, delete it here in the same PR; the PR and git history are
the record. Durable lessons go in CLAUDE.md (or a code comment), not in this file.
Everything completed through PR #98 (2026-10-20) is in
[`docs/archive/TODO-2026-10-20.md`](docs/archive/TODO-2026-10-20.md), including the full bug
traces CLAUDE.md links to.

## Next up

- [ ] **Migrate `assigned_to` / `author` / `uploaded_by` free text to `user_id` references.**
      Touches Lead, Job, ActivityNote, and Document forms and views. Unblocked since roles and
      Pundit shipped (PRs #92/#93). It's also what would let ActivityNote/Document permissions
      narrow to "your own" notes; today any non-viewer role can edit any of them.

## Phase 7 — Design Quality Pass (Impeccable)

A scored design review of the surfaces a portfolio reviewer sees first, judged against
[`DESIGN.md`](DESIGN.md) and [`PRODUCT.md`](PRODUCT.md) rather than taste. One branch + PR per
item, off `origin/main`. If an item changes a token or component, re-run `/impeccable document`
in the same PR so DESIGN.md stays in sync with `application.css`.

- [ ] **P7.1** — Dashboard (`app/views/dashboard/show.html.erb`), in progress. Critiqued four
      times (20 → 23 → 25 → 24 out of 36; snapshots in `.impeccable/critique/`), fixes in PRs
      #102–#112: now a "Today" sheet with due-today/overdue follow-ups, urgency-sorted active
      jobs, and owed vs to-bill money, on Eastern time. Still open from the 4th critique:
      - **P1 Jobs drill-down:** "View all active jobs" lands on an id-sorted table with no end
        date or "days over"; keep the card's urgency sort and show it there.
      - **P1 Act on today:** no way to reschedule or close a follow-up (or mark an invoice paid)
        from the dashboard; each call is open lead → Edit → change date → save. Wants a
        per-row reschedule control (Turbo Stream, gated by `policy(lead).update?`).
      - **P2 Severity hierarchy:** cards follow time of day, so 40-day-overdue money sits last;
        Due Today's "Quoted" badge shares the lateness amber. Show lead status as muted text,
        keep amber for lateness, consider an overdue-money summary up top.
      - **P2 Relative dates:** rows say "Due Oct 24, 2026" for today and zero-pad ("Nov 03");
        DESIGN.md wants "today" / "tomorrow" / "Nov 3", year only when not current.
      - **P2 Money drill-down:** the money cards stop at 5 rows with no "View all" (tied to the
        top-level Orders decision below).
      - **P3 Call links:** `tel:` appends an extension's digits to the number; dial with a
        pause or drop the extension.
- [ ] **P7.2** — `/impeccable polish public`. The Rails error pages (`400`, `404`,
      `406-unsupported-browser`, `422`, `500.html`) are still stock. They sit outside the
      Tailwind pipeline, so like `layouts/mailer.html.erb` they must hardcode hex. Add them to
      the hand-update list in `app/views/CLAUDE.md`, and consider extending
      `spec/views/stale_palette_spec.rb` to `public/`.
- [ ] **P7.3** — `/impeccable audit app/views/quotes`. The estimation editor is the signature
      feature and the most complex layout. Check a11y, responsive behavior, and performance;
      keep every `data-*` hook `quote_form_controller.js` depends on.
- [ ] **P7.4** — Decide the unused `accent` token (`#075985`). Described as primary's hover
      color, but no view uses it (daisyUI darkens the button's own color instead). Wire it in or
      remove it, then update the `application.css` comment, CLAUDE.md's palette table, and
      DESIGN.md.
- [ ] **P7.5** — After P7.1: critique the next surfaces in reviewer order (Lead show with its
      quotes, Quote show / Accept, Job show with orders, Customer index). One critique + polish
      PR per surface.
- [ ] **P7.6** — Quiet the detector's known false positives before `/impeccable hooks on`:
      `overused-font` on Inter is deliberate (self-hosted for offline use), and every hit in
      `app/assets/builds/tailwind.css` is compiled daisyUI output. Use `/impeccable hooks
      ignore-rule` / `ignore-file`.

## Needs a product decision

- [ ] **Top-level Quotes / Orders pages?** Both are only listed nested under a Lead/Job, so
      there's nothing to put Ransack + Pagy on yet.
- [ ] **Lead + Customer creation on one form** — the original intent, never built
      (`leads/_form.html.erb` only selects an existing customer). Build it or drop it, then
      update CLAUDE.md's UX notes to match.
- [ ] **Customer show "Lifetime Value" / "Outstanding" tiles** always render "—"
      (`customers/show.html.erb`). Compute them (from which orders and statuses?) or remove them.
- [ ] **`tax_rate` input format** — "0.13 for 13%" confuses people. Accepting "13" needs a
      `before_validation` normalization and touches Quote's and Order's show pages.
- [ ] **Customer index status filter** — no way to filter by Active/Inactive today.

## Smaller follow-ups

- [ ] Firefox lacks CSS anchor positioning, so `shared/_row_actions`' popover centers in the
      viewport instead of tethering to its button (daisyUI's documented fallback). Needs a
      manual look in a real Firefox; can't be verified headless.
- [ ] Document image thumbnails use the original blob, not a resized variant, because libvips
      isn't installed in every dev environment. Switch to a variant once it is.
- [ ] Dark theme (`jobdeck-dark`). The token structure supports it as a drop-in.

## Parked

- **Delete / deactivate a user** — deferred (YAGNI). `User` has no `deactivated_at`/status
  concept. Reopen when someone actually leaves the company.
- **SSO** — postponed 2026-10-18 until a second business runs Jobdeck or a partner asks for their
  own IdP. Design is in CLAUDE.md → "Role-based Authorization" → "Rollout order": OmniAuth,
  an `Identity` join model (`user_id`/`provider`/`uid`), Google Workspace → Microsoft Entra ID
  → generic SAML 2.0, JIT provisioning as `viewer`, optional "SSO only" mode.
