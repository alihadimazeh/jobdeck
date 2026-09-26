# Project: Construction PM App

A simple project management web app for a small construction business (flooring/tile installer). General project managers use this to track customers, sales leads, quotes, active jobs, and billing.

## Stack notes

Rails 8 + PostgreSQL + Turbo/Stimulus; the Gemfile has the rest. What the Gemfile doesn't show:

- **No Node/npm anywhere.** Tailwind CSS v4 runs through `tailwindcss-rails`'s standalone CLI
  (CSS-first config). **daisyUI is vendored** as standalone `.mjs` files
  (`app/assets/tailwind/daisyui.mjs`, `daisyui-theme.mjs`), not an npm package.
- Design-system rules live in `app/views/CLAUDE.md`; testing details in `spec/CLAUDE.md`.

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

---

## Search & Pagination (Ransack + Pagy)

On the Customer, Lead, and Job index pages. Quotes and Orders have no top-level index (they're
listed nested under a Lead/Job); whether to add one is an open product question.

- Controller pattern: `@q = Model.ransack(params[:q])` then
  `@pagy, @records = pagy(@q.result(distinct: true).order(:id))`. **The `.order(:id)` is
  required** — without it Postgres can return `SELECT DISTINCT` rows in hash order and records
  jump between pages.
- Every ransack-able model needs explicit `ransackable_attributes`/`ransackable_associations`.
  Ransack raises `Ransack::InvalidSearchError` without them — it's a security allow-list.
- **Pagy 43.x is a full rewrite** of the classic docs: there's no `Pagy::Backend`/`Pagy::Frontend`/
  `pagy_nav`. `Pagy::Method` is included in `ApplicationController`, `pagy(collection)` returns
  `[pagy, records]`, and the view calls `@pagy.series_nav if @pagy.pages > 1`.
- **Ransack's `_eq` on an integer-backed enum doesn't know about Rails enums.** It casts a string
  label with `to_i` (`"contacted".to_i == 0`), silently matching the wrong rows with no error.
  Build enum filter `<select>`s from `Model.statuses` **values** (the integers), not the keys —
  see `leads/index.html.erb` and its regression spec.

## Not done yet

- **Dark theme** — the token structure supports it; no `jobdeck-dark` theme exists yet.
- **Quote/Order search + pagination** — needs a product decision first (no top-level lists).
- **Job index status filter label** — the `status_eq` select has no label.
- **Role-based nav/action-button gating** — blocked on Phase 5 milestones 2–3.
- **`tax_rate`'s "0.13 for 13%" input format** — confusing (got a clarifying hint only);
  accepting "13" needs a `before_validation` normalization on Quote and Order.
