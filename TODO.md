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

- [ ] **P7.1** — `/impeccable critique app/views/dashboard/show.html.erb`. No surface has been
      critiqued yet. The dashboard is the first screen after sign-in and the one PRODUCT.md
      centers on. Its scored snapshot becomes the backlog for a follow-up `/impeccable polish`.
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
