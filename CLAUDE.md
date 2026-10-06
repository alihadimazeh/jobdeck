# Project: Construction PM App

A simple project management web app for a small construction business (flooring/tile installer). General project managers use this to track customers, sales leads, quotes, active jobs, and billing.

## Stack notes

Rails 8 + PostgreSQL + Turbo/Stimulus; the Gemfile has the rest. What the Gemfile doesn't show:

- **No Node/npm anywhere.** Tailwind CSS v4 runs through `tailwindcss-rails`'s standalone CLI
  (CSS-first config). **daisyUI is vendored** as standalone `.mjs` files
  (`app/assets/tailwind/daisyui.mjs`, `daisyui-theme.mjs`), not an npm package.
- Design-system rules live in `app/views/CLAUDE.md`; testing details in `spec/CLAUDE.md`.
- **`DESIGN.md`** (repo root) is the canonical visual spec (tokens, components, named rules), with
  a `.impeccable/design.json` sidecar; **`PRODUCT.md`** holds users, purpose, and product
  principles. Both are read by the Impeccable design skill (`/impeccable`).

## Testing

**All new test files go in `spec/` (RSpec), never `test/` (Minitest), unless explicitly stated
otherwise.** `bundle exec rspec` runs RSpec; `bin/rails test` still runs the old Minitest suite,
which is kept passing but gets no new coverage. See `spec/CLAUDE.md` for the auth helpers,
system-spec setup, and how to run system specs on this machine.

## Domain Overview

```
Customer → Lead → Quote (with Room measurements) → Job → Order(s) → LineItems
```

A **Customer** walks in or calls. A **Lead** is logged for them describing what they're interested in. One or more **Quotes** are created for the lead — each includes room measurements (the estimation tool calculates sq footage and multiplies by labor/material rates to produce line items). If the customer accepts the quote, it converts into a **Job** and the quote's line items are seeded into the first **Order**. A Job can have additional Orders (e.g. change orders, materials orders), and each Order is made up of **LineItems**.

At any point, **ActivityNotes** (a running log/timeline entry) and **Documents** (PDFs, Excel
sheets, photos) can be attached to a Customer, Lead, Job, or Order via polymorphic associations.
These are deliberately separate from the free-text `notes` column on `Quote`/`Order`.

### Naming notes
- "Job" is used instead of "Project" — it matches how contractors actually talk ("I've got 3 jobs this week").
- "Order" is kept as-is rather than renamed to "Invoice."
- "Quote" lives on the Lead (pre-commitment). Orders live on the Job (post-commitment). They are intentionally separate models with different lifecycles.
- **`ActivityNote`, not `Note`** — named to avoid colliding with the existing free-text `notes`
  column on `Quote`/`Order`, which stays a single field on the record; ActivityNote is a separate
  one-to-many log.

---

## Model behavior and gotchas

Columns and associations are in `db/schema.rb` and the model files. This section covers what
they don't say.

- **Customer** is the root: every Lead, Job, Quote, and Order has a non-nullable `customer_id`.
- **Lead** is never deleted on conversion; it stays as the historical record. A Lead can have
  several Quotes (revisions, split scopes) but at most one `accepted`
  (`Quote#only_one_accepted_quote_per_lead`). `Lead#convert_to_job!(quote)` creates the Job from
  the Lead's data (plus the customer's address), creates the first Order seeded from the Quote's
  line items, and flips the Lead to `converted`. It raises if the Lead already has a Job.
- **Quote** accepting (status → `accepted`) triggers `convert_to_job!` via `after_save`. Rooms and
  line items are nested attributes (`allow_destroy: true, reject_if: :all_blank`), so the form
  saves everything in one submit. `total_area` treats unsaved rooms (`area` is `nil` until their
  own `before_save`) as `0`.
- **Job** has a nullable `lead_id` (repeat customers can skip the quote flow). Its job-site address
  is separate from the customer's address because the work location can differ from billing.
- **Order** status is independent of Job status (a Job can be "completed" while its Order is still
  "invoiced"). `lead_id` is nullable, kept for reporting only.
- `quote_number` / `order_number` auto-generate on create as `QUO-<year>-<seq>` / `ORD-<year>-<seq>`.
  Subtotal/total and line-item totals are recalculated before save.
- **ActivityNote** rows are Turbo Frames (`turbo_frame_tag activity_note`) so inline edit/delete
  don't reload the page; the row's delete needs `data-turbo-frame="_top"` to escape its own frame.
- **Failed ActivityNote/Document create keeps the user's input** (PR #58). Both controllers
  `include RendersParentShow`: on validation failure they re-render the parent's show page with a
  422 and the invalid record as `@activity_note`/`@document`. The `_section` partials take that as
  an optional `activity_note:`/`document:` local, so the form keeps what was typed and
  `shared/_form_errors` fires. **Any parent show page that renders these sections must pass the
  local through.**
- **Document**: `acceptable_file` requires an attached file of an `ACCEPTED_TYPES` type (PDF,
  XLS/XLSX, JPEG, PNG) under `MAX_SIZE` (50MB). **Active Storage ignores the declared
  `content_type:` and re-sniffs the bytes with Marcel.** PDFs and images get an inline "View"
  link (new tab); images also get a thumbnail, which uses the original blob rather than a variant
  because libvips isn't installed in every dev environment. Other types get "Download".
- **Customer email** has a format validation (blank allowed). `Customer#archive!` uses
  `update_attribute` so a legacy invalid value can't block the automatic archive.

## Deletion Semantics (`dependent:` conventions)

Three `dependent:` strategies are used across the model layer, chosen by what the
child record actually represents — not chosen ad hoc per association:

- **`dependent: :destroy`** — the child has no independent value outside its parent;
  deleting the parent should clean it up. Used for `Customer → leads`, `Customer →
  quotes`, `Lead → quotes`, `Quote → rooms`/`quote_line_items`, `Order → line_items`, and every
  `activity_notes`/`documents` association.
- **`dependent: :restrict_with_error`** — the child is financial/billing data with
  real-world consequences (work performed, money owed) and a `NOT NULL` FK back to the
  parent, so it must never be silently destroyed or orphaned. Deleting the parent is
  blocked until the child is dealt with explicitly. Used for `Customer → jobs`,
  `Customer → orders`, `Job → orders`, `Lead → orders`.
- **`dependent: :nullify`** — the child is independently meaningful and its FK back to
  the parent is nullable, so deleting the parent should just decouple it, not destroy
  or block on it. Used for `Lead → job` (`Job.lead_id` is nullable — a Job and its
  billing history are real, completed work and shouldn't vanish or block Lead cleanup
  just because the originating Lead is removed).

When a model declares more than one `restrict_with_error` association, **declaration
order matters**: `restrict_with_error` is a `before_destroy` callback that `throw(:abort)`s
on the first non-empty association it checks, halting the rest of that model's own
callback chain — so whichever guard is declared first is the one whose message the
caller actually sees. Order them so the most specific/always-true guard comes first
(see `Customer`: `jobs` before `orders`, since every Order requires a Job, so checking
`jobs` first always fires when either condition holds).

**Restrict-before-destroy, always:** the ordering rule above generalizes one level
further — within any single model's `before_destroy` chain, every
`restrict_with_error` association must be declared *before* any `destroy`/`nullify`
one. This isn't just style: a `restrict_with_error` guard reached via another model's
`dependent: :destroy` cascade (e.g. `Customer → leads (destroy)` reaching down into
`Lead → orders (restrict_with_error)`) does not surface its error message on the
top-level record, and — because none of the `transaction` calls involved open a real
savepoint — doesn't cleanly roll back whatever the cascade already did before the
abort (see TODO.md → Bugs for the full trace this was found from). Declaring the
restrict checks first on both `Customer` and `Lead` means a blocked delete is caught
immediately, before any cascade that could partially mutate data even starts.

**Customer's archive fallback:** `Customer` is the one model where a blocked delete isn't
just an error — `CustomersController#destroy` tries `@customer.destroy` first, and if
that returns `false` (blocked by the `restrict_with_error` chain above), it calls
`Customer#archive!` instead and shows a different flash message. This works without
re-deriving "does this customer have history" in the view, because the `restrict_with_error`
chain is already the single source of truth for that question. Archived customers are
excluded from default views via `Customer.visible`, but never deleted.

`Customer.status` is string-backed (the other status enums are integer-backed) and mixes two
concepts: `active`/`inactive` is a manual, staff-chosen label with no behavioral effect;
`archived` is system-driven, set only via `Customer#archive!`, and never selectable in the form.

## UX / Workflow Notes

- **Lead + Customer creation on one form** was the original intent (a separate customer-creation step adds friction during a quick walk-in or phone inquiry) but was **never built** — `leads/_form.html.erb` only offers a `customer_id` select of existing customers. Parked in TODO.md's UI Backlog as "needs a product decision" (build it or drop it).
- **Quotes live on the Lead show page** — there's a "Create Quote" button that opens the quote form, and the page lists all of the lead's quotes. A lead can have several (revisions, or split scopes), but only one can be `accepted`.
- **Estimation tool on the Quote form** — a Stimulus-powered room calculator where you enter room name + dimensions. It sums sq footage across all rooms and auto-populates labor and material line items (based on rates you enter). Line items remain fully editable after the tool runs.
- **Quote → Job conversion** is triggered from the Quote show page ("Accept Quote" button).
- **ActivityNotes and Documents** use shared partials (`activity_notes/_section.html.erb`,
  `documents/_section.html.erb`) on the Customer, Lead, Job, and Order show pages; only the
  polymorphic target (`notable:`/`documentable:`) changes.
- Dashboard should surface: leads needing follow-up, active jobs, and unpaid/outstanding orders.

---

## Authentication (Phase 5, milestone 1 — shipped)

Every controller requires a signed-in user. Roles/Pundit (milestone 2) and SSO (milestone 3) are
still planned — see "Planned: Authorization & SSO" below.

- **Session-based**, not token/JWT: a real `Session` row per sign-in, referenced by a signed,
  `httponly`, `same_site: :lax` cookie holding only the session's id
  (`app/controllers/concerns/authentication.rb`, the Rails 8 generator pattern). Sign-out (or
  `User.destroy`) deletes the row, which immediately invalidates the cookie — no revocation list.
- `Current` (`ActiveSupport::CurrentAttributes`) holds the resolved `session`/`user`, resolved once
  per request via `resume_session`.
- `before_action :require_authentication` runs everywhere by default; opt out per action with
  `allow_unauthenticated_access only: [...]`. Unauthenticated requests redirect to
  `new_session_path`, and `after_authentication_url` sends the user back where they were headed.
- `SessionsController#create` uses `User.authenticate_by(email:, password:)` — constant-time even
  when the email doesn't exist, unlike `find_by(...)&.authenticate` — and is `rate_limit`ed
  (10 attempts / 3 minutes; a no-op in test, which runs on `:null_store`). "Remember me" is just
  cookie persistence: `cookies.signed.permanent` vs a session cookie.
- `PasswordsController` always shows the same flash whether or not the email exists, so it can't
  enumerate accounts. Reset tokens come from `generates_token_for :password_reset, expires_in:
  15.minutes` — no token column, and salted with the password hash so a token also dies the
  moment the password changes.
- `PasswordsMailer#reset` uses `deliver_later`; test env sets `queue_adapter = :test` so specs
  assert with `have_enqueued_mail`.
- Auth pages render through `layouts/auth.html.erb` (centered card, no sidebar) — an
  authenticated-only sidebar on the sign-in page would be backwards.
- `password` validates `length: { minimum: 8 }, allow_nil: true` — `allow_nil` so updating a
  User without touching the password doesn't fail the length check.
- **Deliberately not done yet** (TODO.md → Phase 5): no sign-up/user-management UI —
  `db/seeds.rb` creates one dev user (`admin@jobdeck.test`), others via `rails console` until
  Pundit + an admin role exist. The free-text `assigned_to`/`author`/`uploaded_by` fields are
  **not** yet backed by `user_id`.

## Planned: Authorization & SSO

The intent is to make Jobdeck a real, multi-user product other construction businesses could run,
and a portfolio piece that demonstrates RBAC and SSO done properly.

### Role-based views and permissions

- Roles: **admin**, **project_manager**, **sales**, **viewer** (integer-backed
  enum on User, consistent with the other status enums).
  - `admin` — full access, user management, settings.
  - `project_manager` — full access to customers/leads/quotes/jobs/orders, no user management.
  - `sales` — customers, leads, quotes; read-only on jobs/orders.
  - `viewer` — read-only across the board (e.g. an owner who just wants dashboards).
- Authorization layer via **Pundit** (policy per model) — one policy object per
  model, `authorize` in every controller action, `policy_scope` on every index.
- **Role-based views** — navigation, action buttons (Edit / Delete / "Accept Quote" /
  "Convert to Job"), and whole sections show/hide based on the current user's role.
  Use `policy(record).action?` in views, not ad-hoc role checks.
- Deny-by-default: a missing policy method means no access.

### SSO (Single Sign-On)

- Support **OmniAuth**-based SSO so partner companies can bring their own identity provider.
- Providers: **Google Workspace** (OAuth2) first, then **Microsoft Entra ID**,
  then generic **SAML 2.0** for enterprise customers.
- `Identity` / `Authentication` join model: `user_id`, `provider`, `uid`,
  so one User can link multiple providers and still have a local password fallback.
- Just-in-time provisioning — first SSO login creates the User with a default
  role of `viewer`; an admin promotes them.
- Optional per-deployment config: "SSO only" mode that disables password login.

### Rollout order

1. ~~User model + session-based login/logout + password reset.~~ **Shipped** (see above).
2. Roles enum + Pundit policies + `authorize` / `policy_scope` everywhere.
3. Role-based view gating (nav + buttons + sections).
4. OmniAuth scaffolding + Google SSO.
5. Microsoft + SAML providers, JIT provisioning, SSO-only mode.

## Planned: Design Quality Pass (Phase 7)

Queued **after Phase 5's milestones 2–3** (roles + view gating change the nav and buttons these
reviews would judge). A scored critique/audit/polish pass over the surfaces a portfolio reviewer
sees first, judged against [`DESIGN.md`](DESIGN.md) and [`PRODUCT.md`](PRODUCT.md) rather than
taste. The item list, targets, and exact `/impeccable` commands live in
[`TODO.md`](TODO.md) → "Phase 7 — Design Quality Pass". In short: critique the dashboard, bring
the stock `public/` error pages onto the theme, audit the quote estimation editor, and decide the
unused `accent` token. Any token or component change re-runs `/impeccable document` in the same PR
so DESIGN.md stays in sync with `application.css`.

---

## Design System

The UI has been fully rebuilt on **daisyUI**. Built on `feature/ui-foundation-prep`
(16 chunked steps), then retinted on `feature/navy-blue-theme`; both merged to `main`
via PR #42 (2026-09-18) — the navy + blue palette below is what's actually live, not a
trial. This section is the durable reference; the design intent and full build history
live in `~/.claude/plans/using-the-design-skill-immutable-hippo.md` (original design
plan) and `~/.claude/plans/let-s-tackle-the-ui-ux-fancy-pnueli.md` (chunked execution
plan + what actually shipped at each step) — neither covers the post-merge palette swap
or the two small table polish items below, which happened after that plan finished.

### Theme & rule

- One custom daisyUI theme, `jobdeck` — "navy + blue CTA" — defined entirely in
  `app/assets/tailwind/application.css` via `@plugin "./daisyui-theme.mjs"`. Light only
  for now; every color reference in view code is a semantic token (`bg-base-200`,
  `text-base-content`, `badge-success`, …), never raw hex or Tailwind's default scales,
  so a `jobdeck-dark` theme is a later drop-in with zero view changes.
- **Rule: always use daisyUI's semantic classes, never `amber-*`/`gray-*`/raw hex in a
  view.** (`amber-*` was the pre-redesign accent — if you see it, it's a regression.)
- Font is self-hosted **Inter** (`app/assets/fonts/inter/`, variable weight) — no
  external font requests, works offline on a job site.
- The original redesign shipped an "industrial slate + safety orange" palette first
  (primary `#EA580C`); it was retinted to navy + blue right after, on its own branch,
  precisely so the contrast/badge-variant work below didn't need re-checking per
  resource. The orange values still exist in git history (`cdc4e38` on
  `feature/ui-foundation-prep`) if ever needed again, but nothing on `main` uses them.

| Role | Hex | Used for |
|---|---|---|
| `base-100` / `base-200` / `base-300` | `#FFFFFF` / `#F8FAFC` / `#E2E8F0` | cards & tables / app canvas / hairline borders |
| `base-content` | `#0F172A` | body text (muted text is `text-base-content/70`) |
| `primary` | `#0369A1` | primary actions / CTA — white button text measures 5.93:1 |
| `secondary` | `#334155` | secondary buttons / quiet emphasis |
| `accent` | `#075985` | hover/active state on primary |
| `neutral` | `#0F172A` | sidebar (navy) |
| `info` / `success` / `warning` / `error` | `#1D4ED8` / `#15803D` / `#B45309` / `#B91C1C` | status badges — see `ApplicationHelper::STATUS_VARIANTS` for the status → variant map. `error` darkened from `#DC2626` (PR #54) — the lighter value failed WCAG AA on `badge-soft`/`alert-soft` (4.27:1) |

### Shared components (`app/views/shared/`)

`_page_header` (breadcrumb + H1 + action slot — suppresses the breadcrumb entirely when
its last segment duplicates the title), `_form_container`, `_form_errors`
(`role="alert"`, autofocused, links each error to its field), `_field` (label/input/
select/textarea + hint/error — not used by the 12-column line-item/room editor rows,
those stay hand-written because they're the JS-templated ones), `_card`, `_table`
(optional `footer:` for a real `<tfoot>` totals row; every table renders through this one
partial, so its rows are zebra-striped app-wide via a single CSS rule —
`.table tbody tr:nth-child(even)` in `application.css`, `color-mix()` off `base-content`
rather than daisyUI's own `table-zebra` class so the stripe doesn't reuse `base-200`,
which is already the page canvas color), `_detail_list`, `_stats`, `_badge`,
`_row_actions` (the kebab menu — daisyUI's Popover API, not JS; the trigger button is
centered in its column, not right-aligned), `_empty_state`, `_flash`. Plus
`layouts/_sidebar` and `layouts/_navbar` for the app shell.

Note the two block-rendering partials' calling convention: `render "shared/card", { title:
"X" } do ... end` (bare string + plain hash), **not** `render partial:, locals:` — the
latter doesn't support a block the same way. See `shared/_card.html.erb`'s own comment.

### Helpers (`app/helpers/application_helper.rb`)

`status_badge(record)`, `format_date`, `format_currency`, `format_address`, `btn` (daisyUI
button wrapper), `nav_link`/`nav_section_active?`/`SECTION_CONTROLLERS` (a nested
resource, e.g. a Quote, still highlights its parent Leads/Jobs nav item).

### Required fields (`field_required?` + `aria-required`)

Every `shared/_field` works out on its own whether it's required. It then shows a red `*` in
the label (`aria-hidden`, explained by `_form_container`'s "Fields marked * are required") and
sets `aria-required="true"` on the control.

- **Why a custom helper (`field_required?`), not a per-form flag:** the marker is derived
  from the model's own validations, so it can't drift from what the server actually enforces.
  It returns true for an unconditional `presence` validation, and false for one carrying
  `if`/`unless`/`on`/`allow_nil`/`allow_blank`, since those aren't always required.
  - For a `*_id` foreign key it reads the `belongs_to` reflection's `optional` flag instead,
    because in Rails 8.1 `belongs_to`'s own presence validator carries an internal `if:`.
    So `Lead#customer_id` is required and `Job#lead_id` isn't.
  - A form can still override the result with the partial's `required:` local
    (`required: true` / `false`) when the derivation is wrong for that one form.
- **Why `aria-required`, never the native `required` attribute:** native `required` makes
  the browser block a blank submit and show its own tooltip. The request never reaches the
  server, so `shared/_form_errors` (the focused, linked error summary, PRs #54/#61) never
  renders. PRs #63/#64 shipped native `required` and broke three system specs on `main` that
  way. `aria-required` still tells screen readers the field is required, without triggering
  browser validation.
  - The hand-written Document file input (`documents/_form`) follows the same rule.
  - `spec/views/shared/field_spec.rb` fails if native `required` comes back.

### App shell & JS

- `layouts/application.html.erb`: daisyUI `drawer` — a permanent sidebar rail `>=lg`,
  a toggleable overlay drawer below it, from one markup (`lg:drawer-open`). Skip link,
  `<html lang="en">`, `aria-label` on both nav landmarks.
- `app/javascript/controllers/drawer_controller.js` — a11y layer on top of the
  checkbox-driven drawer (focus management, Escape-to-close, `aria-expanded`); the
  drawer itself needs no JS to open/close.
- `quote_form_controller.js` / `order_form_controller.js` (the estimation tool, dynamic
  room/line-item rows) are unchanged by the redesign — only the row markup's classes
  were reworked to stack on mobile, every `data-*` hook they depend on was preserved.
- `dropdown_controller.js` and `hello_controller.js` were deleted (fully replaced by
  `shared/_row_actions` and dead scaffold, respectively).

### Root / dashboard

`root "dashboard#show"` (was `customers#index`) — `DashboardController` shows leads
needing follow-up (`Lead.needs_follow_up`), active jobs (`Job.active_status`), and
outstanding orders (`Order.outstanding`), each a 5-row preview with a true total count.

### Search & Pagination (Ransack + Pagy)

Wired into the **Customer, Lead, and Job index pages** (Job via PR #56) — `Quote`/`Order` indexes
are still plain unfiltered/unpaginated `render @collection`, and are only listed nested under a
Lead/Job (see TODO.md's "needs a product decision" list for that gap).

- Controller pattern: `@q = Model.ransack(params[:q])` then `@pagy, @records =
  pagy(@q.result(distinct: true))`. Every ransack-able model needs explicit
  `ransackable_attributes`/`ransackable_associations` class methods — Ransack raises
  `Ransack::InvalidSearchError` without them (a deliberate security allow-list, not boilerplate
  you can skip).
- View pattern: `search_form_for @q do |f| ... end`, then `@pagy.series_nav if @pagy.pages > 1`
  below the results.
- **Pagy 43.x is a full rewrite** of the classic docs most tutorials show — there's no
  `Pagy::Backend`/`Pagy::Frontend`/`pagy_nav` helper in this version. `Pagy::Method` is included
  in `ApplicationController`; `pagy(collection)` returns `[pagy_instance, collection]`; the nav
  method (`series_nav`) is called directly on that instance in the view.
- **Real bug found and fixed**: Ransack's `_eq` predicate on an integer-backed `enum` column
  (e.g. `Lead.status`) doesn't know about Rails enums — it naively casts a non-numeric string
  label via `String#to_i` (`"contacted".to_i == 0`), so a `<select>` built from
  `Lead.statuses.keys` silently matched "new" leads regardless of what was picked, with no error.
  Fix: build the `<select>` from `Lead.statuses` **values** (the integers), not the keys — see
  `leads/index.html.erb` and its regression spec in `leads_spec.rb`. Worth checking for the same
  trap on any future enum-column filter.

### Not done yet

- **Dark theme** — the token structure supports it, no `jobdeck-dark` theme exists yet.
- **Ransack/Pagy on Quote/Order indexes** — see "Search & Pagination" above.
- **Role-based nav/action-button gating** — blocked on the auth work (Phase 5) below;
  the shell is built to have `policy(record).action?` checks layered in later.
- **`tax_rate`'s "0.13 for 13%" input format** — flagged as confusing during the redesign
  (got a clarifying hint, not a semantics change) — actually accepting "13" would need a
  `before_validation` normalization and touches both Quote's and Order's show pages.
