# Design system notes (loads when working under `app/views/`)

The UI is built on **daisyUI** with one custom theme, `jobdeck` ("navy + blue CTA"), defined in
`app/assets/tailwind/application.css` via `@plugin "./daisyui-theme.mjs"`. Light only for now.
Palette values live in that file.

## Rules

- **Always use daisyUI semantic classes (`bg-base-200`, `text-base-content`, `badge-success`, …),
  never raw hex or Tailwind default scales (`amber-*`, `gray-*`) in a view.** This keeps a future
  `jobdeck-dark` theme a zero-view-change drop-in. `amber-*` was the pre-redesign accent; seeing it
  means a regression.
- The first redesign shipped an "industrial slate + safety orange" palette (primary `#EA580C`),
  retinted to navy + blue right after. Nothing on `main` should use the orange values (they're in
  git history at `cdc4e38` if ever needed).
- Files **outside the Tailwind pipeline** can't use tokens and hardcode hex:
  `layouts/mailer.html.erb` and `pwa/manifest.json.erb`. If the palette changes, update both by
  hand. `spec/views/stale_palette_spec.rb` fails if `#EA580C`/`#1E293B` reappear under
  `app/views` or `app/helpers`.
- `--color-error` is `#B91C1C`, darkened from `#DC2626` (PR #54): the lighter value failed WCAG AA
  on `badge-soft`/`alert-soft` (4.27:1). Re-check contrast if you touch status colors.
- **Every form/filter control needs an accessible name** (a label, visible or `sr-only`, or an
  `aria-label`). Placeholders don't count. `spec/requests/form_control_labels_spec.rb` checks the
  Lead index and the Quote/Order forms, including their JS row `<template>`s. Known gap: the Job
  index's `status_eq` select still has no label.
- Inter is self-hosted (`app/assets/fonts/inter/`) so the app works offline on a job site; don't
  add external font requests.

## Shared partials: the non-obvious parts

- `render "shared/card", { title: "X" } do ... end` (bare string + plain hash), **not**
  `render partial:, locals:` — the latter doesn't pass a block the same way. Same for
  `shared/form_container`.
- `shared/_field` marks required fields automatically (asterisk + native `required`) from the
  model's unconditional presence validations, via `field_required?` in `ApplicationHelper`; pass
  `required:` to override. It is not used by the 12-column room/line-item editor rows, which stay
  hand-written because they're the JS-templated ones.
- Tables are zebra-striped by one CSS rule (`.table tbody tr:nth-child(even)` in
  `application.css`, a `color-mix()` off `base-content`) rather than daisyUI's `table-zebra`,
  because `table-zebra` reuses `base-200`, which is already the page canvas color.
- `shared/_row_actions` is the kebab menu, built on the Popover API (no JS). A delete rendered
  inside a Turbo Frame needs its `turbo_frame: "_top"` local to escape the frame.
- `leads/_lead` and `jobs/_job` take `show_customer:`/`show_actions:` (both default true); show
  pages render them compact rather than hand-rolling preview rows.

## App shell & JS

- `layouts/application.html.erb` is a daisyUI `drawer`: permanent sidebar rail `>=lg`, toggleable
  overlay below, from one markup. Page titles and breadcrumbs come only from
  `shared/_page_header` inside `<main>`. Don't reintroduce `content_for(:page_heading)` /
  `(:breadcrumbs)`; the old layout `<header>` driven by them was never used and was removed
  (PR #59).
- The sidebar's "Sign out" button still uses a raw `hover:text-white`, deliberately left for the
  Phase 5 view-gating work.
- `drawer_controller.js` is an a11y layer (focus management, Escape-to-close, `aria-expanded`) on
  top of the checkbox-driven drawer, which needs no JS to open/close.
- `quote_form_controller.js` / `order_form_controller.js` (estimation tool, dynamic rows) depend
  on `data-*` hooks in the row partials; preserve them when restyling. Keyboard focus after
  add/remove is handled by the shared `controllers/row_focus.js` helper (not a `*_controller`,
  so Stimulus doesn't register it).
