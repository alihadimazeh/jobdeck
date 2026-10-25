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
  Lead index and the Quote/Order forms, including their JS row `<template>`s; the Job index's
  status filter label is covered by `spec/requests/jobs_spec.rb`.
- Inter is self-hosted (`app/assets/fonts/inter/`) so the app works offline on a job site; don't
  add external font requests.

## Shared partials: the non-obvious parts

- `render "shared/card", { title: "X" } do ... end` (bare string + plain hash), **not**
  `render partial:, locals:` — the latter doesn't pass a block the same way. Same for
  `shared/form_container`.
- `shared/_field` marks required fields automatically (asterisk + `aria-required`, never native
  `required` — see root CLAUDE.md → "Required fields") from the model's unconditional presence
  validations, via `field_required?` in `ApplicationHelper`; pass `required:` to override. It is not used by the 12-column room/line-item editor rows, which stay
  hand-written because they're the JS-templated ones.
- Tables are zebra-striped by one CSS rule (`.table tbody tr:nth-child(even)` in
  `application.css`, a `color-mix()` off `base-content`) rather than daisyUI's `table-zebra`,
  because `table-zebra` reuses `base-200`, which is already the page canvas color.
- `shared/_row_actions` is the kebab menu, built on the Popover API (no JS). A delete rendered
  inside a Turbo Frame needs its `turbo_frame: "_top"` local to escape the frame. Its `edit:`/
  `destroy:` locals (default `true`) let a caller role-gate each item individually — pass
  `policy(record).edit?`/`destroy?` — and the whole trigger is skipped when both are false.
- `leads/_lead` and `jobs/_job` take `show_customer:`/`show_actions:` (both default true); show
  pages render them compact rather than hand-rolling preview rows.
- **Role-based view gating (Phase 5, milestone 2 — shipped)**: every Edit/Delete/"Accept Quote"/
  "New X"/"Create Quote" control, and the ActivityNote/Document "add" forms, are wrapped in
  `policy(record).action?` (or a class-level `policy(Model).create?` where there's no instance
  yet, e.g. index "New X" buttons). No ad-hoc role checks — see root CLAUDE.md → "Required
  fields" sibling section for the same pattern applied to `field_required?`. Nav itself needs no
  gating: every role has `index?`/`show?` on Customer/Lead/Job, so nothing in the sidebar hides.

## App shell & JS

- `layouts/application.html.erb` is a daisyUI `drawer`: permanent sidebar rail `>=lg`, toggleable
  overlay below, from one markup. Page titles and breadcrumbs come only from
  `shared/_page_header` inside `<main>`. Don't reintroduce `content_for(:page_heading)` /
  `(:breadcrumbs)`; the old layout `<header>` driven by them was never used and was removed
  (PR #59).
- `drawer_controller.js` is an a11y layer (focus management, Escape-to-close, `aria-expanded`,
  Enter/Space on the hamburger) on top of the checkbox-driven drawer, which needs no JS to
  open/close by mouse or touch. A focused `<label>` does **not** toggle its checkbox on
  Enter/Space natively, hence `triggerKeydown`.
- Keyboard order is pinned by `spec/system/shell_keyboard_spec.rb`: the drawer checkbox is
  `tabindex="-1" aria-hidden` (the hamburger label is the real control), "Skip to navigation"
  (lg+ only) jumps to `#primary-nav` because the rail sits after `<main>` in the DOM, and the
  focus ring's color is re-asserted unlayered in `application.css` because daisyUI's `.btn`
  outline color otherwise wins for ghost buttons.
- `quote_form_controller.js` / `order_form_controller.js` (estimation tool, dynamic rows) depend
  on `data-*` hooks in the row partials; preserve them when restyling. Keyboard focus after
  add/remove is handled by the shared `controllers/row_focus.js` helper (not a `*_controller`,
  so Stimulus doesn't register it).
