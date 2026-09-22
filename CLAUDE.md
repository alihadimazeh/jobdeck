# Project: Construction PM App

A simple project management web app for a small construction business (flooring/tile installer). General project managers use this to track customers, sales leads, quotes, active jobs, and billing.

## Tech Stack

- **Ruby on Rails 8**
- **PostgreSQL**
- **Tailwind CSS v4** (via `tailwindcss-rails`, CSS-first config, standalone CLI — no
  Node/npm anywhere in this stack)
- **daisyUI** — Tailwind plugin, vendored as standalone `.mjs` files
  (`app/assets/tailwind/daisyui.mjs`, `daisyui-theme.mjs`) rather than an npm package.
  The component/theme layer for the whole UI. See "## Design System" below.
- **Inter** — self-hosted variable font (`app/assets/fonts/inter/`), no external font
  requests.
- **Active Storage** for file uploads (PDFs, Excel sheets, images) — used by `Document`
- **Pagy** for pagination — wired into the Customer and Lead index pages so far
  (`Job`/`Quote`/`Order` indexes don't have it yet). See "Search & Pagination" under
  "## Design System" below for the real (43.x) API, which is a full rewrite of Pagy's
  classic `Backend`/`Frontend` docs.
- **Ransack** for search/filtering — same two index pages, same caveat. Every searched
  model needs explicit `ransackable_attributes`/`ransackable_associations` class methods
  (a security allow-list) — see `Customer`/`Lead`.
- Turbo + Stimulus (Rails defaults, no separate frontend framework)
- **RSpec** (`rspec-rails`, `factory_bot_rails`) — the test framework for the model layer.
  See "## Testing" below.

## Testing

**RSpec** is the test framework going forward, set up alongside the old Minitest suite
(`test/` is left as-is — mostly unedited scaffold stubs plus generated controller CRUD
tests — rather than migrated; new coverage goes in `spec/`, not `test/`).

**Policy: all new test files go in `spec/` (RSpec), never `test/` (Minitest), unless
explicitly stated otherwise.** Any functionality that needs coverage — models, controllers,
requests, or otherwise — gets an RSpec spec. The existing Minitest suite under `test/` is
left in place as-is and still runs (`bin/rails test`), but it is not where new tests go.

- `bundle exec rspec` runs the RSpec suite; `bin/rails test` still runs the old Minitest one.
- `spec/factories/` (FactoryBot) — one factory per model (`customer`, `lead`, `job`, `quote`,
  `order`, `room`, `quote_line_item`, `line_item`). `FactoryBot::Syntax::Methods` is included
  globally (`spec/rails_helper.rb`), so specs use `create`/`build` directly.
  `spec/support/concerns/billable_line_item.rb` holds one shared example group
  ("a billable line item") exercised against both `LineItem` and `QuoteLineItem`, so the
  `BillableLineItem` concern's contract is tested once and both models are checked against
  the same expectations rather than duplicating the spec.
- Every model has its own spec (`spec/models/`): `Customer`, `Lead`, `Job`, `Quote`, `Room`,
  `Order`, `LineItem`, `QuoteLineItem`. Covers what the Model Review cleanup above touched —
  `Lead#convert_to_job!` (happy path + the idempotency guard), `Quote#only_one_accepted_quote_per_lead`,
  the `after_save` → `convert_to_job!` trigger (including the reject-then-accept-a-different-quote
  regression case), the `dependent: :restrict_with_error` deletion-semantics chain on
  `Customer`/`Job`/`Lead` (including a regression test for the nested-cascade bug), the
  `assign_customer_from_lead`/`assign_customer_from_job` auto-set callbacks, `order_number`/
  `quote_number` generation, `recalculate_totals`, `total_area`, and enum value/ordering
  regression checks on `Lead`/`Job`/`Quote`/`Order` (guards against another integer-backed enum
  reorder mistake like the `Lead.source` one).
- Every controller has a request spec (`spec/requests/`): `Customers`, `Leads`, `Jobs`, `Orders`,
  `Quotes`, `ActivityNotes`, `Documents` — full CRUD per controller plus `QuotesController#accept`
  (happy path, the `only_one_accepted_quote_per_lead` alert, and the re-conversion-guard alert).
  Writing these turned up a real gap, since fixed — `Customer` had no model-level validations at
  all, so blank required fields were silently accepted instead of hitting the controller's 422
  path; see TODO.md → Bugs for the fix.
- `ActivityNote`/`Document` also have model specs and a small system-spec pair
  (`spec/system/*_ui_spec.rb`) alongside their request specs, plus a `spec/factories/documents.rb`
  that attaches a real fixture file (`spec/fixtures/files/sample.pdf`).
- **267 examples, 0 failures** (`bundle exec rspec`, excluding `spec/system/**`). System specs
  (Capybara/Selenium) don't run in this sandbox — no real browser is available here
  (`Selenium::WebDriver::Error::WebDriverError`), a pre-existing environment limitation, not a
  regression; they're written and expected to pass wherever a browser driver is available.

## Domain Overview

The business workflow is:

```
Customer → Lead → Quote (with Room measurements) → Job → Order(s) → LineItems
```

A **Customer** walks in or calls. A **Lead** is logged for them describing what they're interested in. One or more **Quotes** are created for the lead — each includes room measurements (the estimation tool calculates sq footage and multiplies by labor/material rates to produce line items). If the customer accepts the quote, it converts into a **Job** and the quote's line items are seeded into the first **Order**. A Job can have additional Orders (e.g. change orders, materials orders), and each Order is made up of **LineItems**.

At any point, **ActivityNotes** (a running log/timeline entry) and **Documents** (PDFs, Excel
sheets, photos) can be attached to a Lead, Job, or Order via polymorphic associations. These are
deliberately separate from the free-text `notes` column that already exists on `Quote`/`Order` —
see "### ActivityNote (polymorphic)" below for why it isn't just called `Note`.

### Naming notes
- "Job" is used instead of "Project" — it matches how contractors actually talk ("I've got 3 jobs this week").
- "Order" is kept as-is rather than renamed to "Invoice."
- "Quote" lives on the Lead (pre-commitment). Orders live on the Job (post-commitment). They are intentionally separate models with different lifecycles.

---

## Models

### Customer
The root entity. Every Lead, Job, Quote, and Order belongs to a Customer — this reference is **never nullable**.

```ruby
# customers table
first_name        string, null: false
last_name         string, null: false
email             string
phone             string, null: false
address_line_1    string
address_line_2    string
city              string
province          string
postal_code       string
status            string, null: false, default: "active"
notes             text
```

Relationships:
```ruby
has_many :jobs,   dependent: :restrict_with_error
has_many :orders, dependent: :restrict_with_error
has_many :leads,  dependent: :destroy
has_many :quotes  # through leads, but direct FK for convenience — dependent: :destroy
has_many :activity_notes, as: :notable, dependent: :destroy
```

`activity_notes` was added deliberately ahead of `Document`/views for it — Customer doesn't have
a `documents` association yet, and the Customer show page doesn't render the ActivityNote section
partial yet either. Wiring that up (association exists, UI doesn't) is open work, not a bug.

---

### Lead
Represents a sales inquiry — interest that hasn't been committed to yet. Tracks pipeline status and converts into a Job when the quote is accepted (the Lead is NOT deleted on conversion — it remains historical record).

```ruby
# leads table
customer_id       references, null: false, foreign_key: true
title             string, null: false
status            string, null: false, default: "new"
                  # new | contacted | quoted | converted | lost
job_type          string
                  # tile | flooring | materials | mixed
source            string
                  # walk_in | phone | referral | website | other
estimated_value   decimal(10,2)
assigned_to       string
follow_up_date    date
description       text
```

Relationships:
```ruby
belongs_to :customer
has_many :orders, dependent: :restrict_with_error
has_one  :job,    dependent: :nullify
has_many :quotes, dependent: :destroy
has_many :activity_notes, as: :notable, dependent: :destroy
has_many :documents,      as: :documentable, dependent: :destroy
```

A Lead can have multiple Quotes (e.g. a revised estimate, or separate quotes for tile vs. flooring). At most one of them should be in the `accepted` state.

Key behavior: `convert_to_job!` — takes the accepted Quote, creates a Job from this Lead's data, links `lead_id` on the new Job, creates a first Order seeded from that Quote's line items, and flips this Lead's status to `"converted"`.

---

### Quote
A formal price estimate presented to the customer before they commit. Belongs to a Lead (and denormalized Customer for convenience). Contains room measurements that drive the estimation tool, and line items that are the output of that tool. Quotes are pre-commitment — they do not require a Job.

```ruby
# quotes table
lead_id           references, null: false, foreign_key: true
customer_id       references, null: false, foreign_key: true
status            string, null: false, default: "draft"
                  # draft | sent | accepted | rejected | expired
quote_number      string, unique
                  # auto-generated, e.g. QUO-2024-0001
subtotal          decimal(10,2), default: 0
tax_rate          decimal(5,4),  default: 0
total             decimal(10,2), default: 0
issued_date       date
valid_until       date
notes             text
```

Relationships:
```ruby
belongs_to :lead
belongs_to :customer
has_many   :rooms
has_many   :quote_line_items
```

Key behavior:
- `quote_number` auto-generated on create (format: `QUO-<year>-<sequential>`)
- `status` is an integer-backed enum (`draft: 0, sent: 1, accepted: 2, rejected: 3, expired: 4`), consistent with how `Job.status` and `Lead.status` are stored
- `subtotal`/`total` recalculated from `quote_line_items` before save
- Accepts nested attributes for `rooms` and `quote_line_items` (`allow_destroy: true, reject_if: :all_blank`) — the Quote form creates/updates the quote plus its rooms and line items in a single submit
- `total_area` sums `rooms.area`, treating any unsaved/blank room (`area` is `nil` until its own `before_save` runs) as `0`
- When status flips to `accepted`, `convert_to_job!` is triggered on the Lead

---

### Room
A room with dimensions, nested under a Quote. Powers the estimation tool — the sq footage from all rooms is summed and used to calculate labor and material line items.

```ruby
# rooms table
quote_id          references, null: false, foreign_key: true
name              string, null: false   # Kitchen, Master Bath, Hallway, etc.
length            decimal(8,2), null: false
width             decimal(8,2), null: false
area              decimal(10,2)         # calculated: length × width
notes             string                # optional per-room note (e.g. "irregular shape")
```

Relationships:
```ruby
belongs_to :quote
```

Key behavior: `area = length * width`, calculated before save.

---

### QuoteLineItem
Individual line items on a Quote. Separate from Order's LineItem — Quotes are pre-commitment and have a different lifecycle. Populated by the estimation tool (labor and material rows from room sq footage) but fully editable before sending.

```ruby
# quote_line_items table
quote_id          references, null: false, foreign_key: true
item_type         integer, null: false
                  # material | labor | other
description       string, null: false
quantity          decimal(10,2), default: 1
unit              string
                  # sqft | ea | hr | etc.
unit_price        decimal(10,2), default: 0
total             decimal(10,2), default: 0
```

Relationships:
```ruby
belongs_to :quote
```

Key behavior: `total = quantity * unit_price`, calculated before save.

---

### Job
The actual work being performed. Belongs to a Customer. `lead_id` is **nullable** — some jobs are created directly without a tracked lead (e.g. repeat customers who don't go through the quote flow).

```ruby
# jobs table
customer_id       references, null: false, foreign_key: true
lead_id           references, null: true,  foreign_key: true
title             string, null: false
status            integer, null: false, default: "active"
                  # active | on_hold | completed | cancelled
job_type          integer
                  # tile | flooring | materials | kitchen | mixed
estimated_value   decimal(10,2)
assigned_to       string
start_date        date
end_date          date
description       text
address_line_1    string
address_line_2    string
city              string
province          string
postal_code       string
```

Relationships:
```ruby
belongs_to :customer
belongs_to :lead, optional: true
has_many   :orders, dependent: :restrict_with_error
has_many   :activity_notes, as: :notable, dependent: :destroy
has_many   :documents,      as: :documentable, dependent: :destroy
```

Note: job-site address fields are separate from the customer's address since the work location may differ from the customer's home/billing address.

---

### Order
The financial/transactional side of a Job (invoice / work order). Always tied to a Job (**not nullable**) and a Customer (**not nullable**, for billing). `lead_id` is nullable and kept purely for reporting/traceability convenience. The first Order on a Job is seeded from the accepted Quote's line items.

```ruby
# orders table
job_id            references, null: false, foreign_key: true
customer_id       references, null: false, foreign_key: true
lead_id           references, null: true,  foreign_key: true
status            integer, null: false, default: "draft"
                  # draft | confirmed | invoiced | paid | cancelled
order_number      string, unique
                  # auto-generated, e.g. ORD-2024-0001
subtotal          decimal(10,2), default: 0
tax_rate          decimal(5,4),  default: 0
total             decimal(10,2), default: 0
issued_date       date
due_date          date
notes             text
```

Relationships:
```ruby
belongs_to :job
belongs_to :customer
belongs_to :lead, optional: true
has_many   :line_items, dependent: :destroy, inverse_of: :order
has_many   :activity_notes, as: :notable, dependent: :destroy
has_many   :documents,      as: :documentable, dependent: :destroy
```

Key behavior:
- `order_number` auto-generated on create (format: `ORD-<year>-<sequential>`)
- `subtotal`/`total` calculated from sum of `line_items` before save
- Order status is independent from Job status (a Job can be "completed" while its Order is still "invoiced")

---

### LineItem
Individual billable rows on an Order (materials, labor, other charges). Managed via nested attributes on the Order form (add/remove rows dynamically). Separate from QuoteLineItem — kept distinct to allow independent editing after commitment.

```ruby
# line_items table
order_id          references, null: false, foreign_key: true
item_type         integer, null: false
                  # material | labor | other
description       string, null: false
quantity          decimal(10,2), default: 1
unit              string
                  # sqft | ea | hr | etc.
unit_price        decimal(10,2), default: 0
total             decimal(10,2), default: 0
```

Relationships:
```ruby
belongs_to :order
```

Key behavior: `total = quantity * unit_price`, calculated before save.

---

### ActivityNote (polymorphic)
A running log/timeline entry attachable to a Lead, Job, or Order. One model/controller/view
reused across all three via `notable_type` / `notable_id`. **Named `ActivityNote`, not `Note`**,
specifically to avoid colliding with the pre-existing free-text `notes` column on `Quote` and
`Order` — those stay as-is (a single free-text field on the record itself), this is a separate
one-to-many log. Rendered via `activity_notes/_section.html.erb`, included on `leads/show`,
`jobs/show`, `orders/show` (not yet on `customers/show` — see the Customer model section above).

```ruby
# activity_notes table
notable_type      string, null: false   # "Lead" | "Job" | "Order" (also "Customer" at the model
notable_id        integer, null: false  # level, but no view renders it there yet)
body              text, null: false
author            string
pinned            boolean, null: false, default: false
```

Relationships:
```ruby
belongs_to :notable, polymorphic: true
```

Validations: `body` presence.

Built as a Turbo Frame per row (`turbo_frame_tag activity_note`) so inline edit/delete don't
reload the page; the row's own delete link needs `data-turbo-frame="_top"` to escape its own
frame on destroy (see `shared/_row_actions.html.erb`'s optional `turbo_frame:` local).

---

### Document (polymorphic + Active Storage)
File uploads (PDFs, Excel sheets, images) attachable to a Lead, Job, or Order. Same polymorphic
pattern as ActivityNote — rendered via `documents/_section.html.erb` on the same three show
pages (also not yet on Customer's).

```ruby
# documents table
documentable_type  string, null: false  # "Lead" | "Job" | "Order"
documentable_id    integer, null: false
label              string
document_type      string
                   # estimate | invoice | plan | contract | photo | other
uploaded_by        string
description        text
```

Relationships:
```ruby
belongs_to :documentable, polymorphic: true
has_one_attached :file
enum :document_type, { estimate: "estimate", invoice: "invoice", plan: "plan",
                        contract: "contract", photo: "photo", other: "other" }, suffix: true
```

Validations (`acceptable_file`, a single custom validation): `file` must be attached; its
`content_type` must be one of `Document::ACCEPTED_TYPES` (PDF, XLS/XLSX, JPEG, PNG); its
`blob.byte_size` must be ≤ `Document::MAX_SIZE` (50MB).

**Gotcha found while testing this**: Active Storage doesn't trust the `content_type:` a form (or
a test) declares on upload — it re-sniffs the actual file bytes via Marcel and overwrites it. A
test that reuses a real PDF fixture but *claims* a different content type still gets correctly
re-identified as `application/pdf`, so exercising the "rejected content type" validation path
needs a file whose *bytes* are actually a non-accepted type (see `document_spec.rb`).

PDF documents get an inline "View" link (`rails_blob_path(disposition: "inline")`, opens in a
new tab); every other type gets "Download" (`disposition: "attachment"`). Photo-type (JPEG/PNG)
documents don't get an inline preview yet even though the browser could render them — open item,
see TODO.md → "UI/UX Audit findings (2026-09-21)".

---

## Migration Order

Migrations must run in this order due to foreign key dependencies:

1. `create_customers` — no dependencies
2. `create_leads` — depends on customers
3. `create_quotes` — depends on leads, customers
4. `create_rooms` — depends on quotes
5. `create_quote_line_items` — depends on quotes
6. `create_jobs` — depends on customers, leads
7. `create_orders` — depends on customers, leads, jobs
8. `create_line_items` — depends on orders
9. `create_activity_notes` — polymorphic, no FK constraints
10. `create_documents` — polymorphic, no FK constraints
11. `rails active_storage:install` — generates Active Storage tables separately

## Foreign Key Nullability Rules

| Reference | Nullable? | Reasoning |
|---|---|---|
| `customer_id` (Lead, Quote, Job, Order) | No | Everything traces back to a customer |
| `lead_id` (Quote) | No | A Quote always belongs to a Lead |
| `lead_id` (Job, Order) | Yes | Jobs/Orders can be created without a tracked Lead |
| `job_id` (Order) | No | An Order always needs Job context |
| `quote_id` (Room, QuoteLineItem) | No | Rooms and quote line items always need a Quote |

## Deletion Semantics (`dependent:` conventions)

Three `dependent:` strategies are used across the model layer, chosen by what the
child record actually represents — not chosen ad hoc per association:

- **`dependent: :destroy`** — the child has no independent value outside its parent;
  deleting the parent should clean it up. Used for `Customer → leads`, `Customer →
  quotes`, `Lead → quotes`, `Quote → rooms`/`quote_line_items`, `Order → line_items`.
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
excluded from default views via `Customer.visible`, but never deleted — see `Customer.status`
in "Status Enums Reference" below.

## UX / Workflow Notes

- **Lead + Customer creation should happen together** on one form, since requiring a separate customer-creation step first adds friction during a quick walk-in or phone inquiry.
- **Quotes live on the Lead show page** — there's a "Create Quote" button that opens the quote form, and the page lists all of the lead's quotes. A lead can have several (revisions, or split scopes), but only one can be `accepted`.
- **Estimation tool on the Quote form** — a Stimulus-powered room calculator where you enter room name + dimensions. It sums sq footage across all rooms and auto-populates labor and material line items (based on rates you enter). Line items remain fully editable after the tool runs.
- **Quote → Job conversion** is triggered from the Quote show page ("Accept Quote" button). This calls `convert_to_job!` on the Lead, which creates the Job, creates the first Order seeded from the Quote's line items, and sets the Lead status to `converted`.
- **ActivityNotes and Documents** use shared partials (`activity_notes/_section.html.erb`,
  `documents/_section.html.erb`) since the UI is identical across Lead, Job, and Order — only
  the polymorphic association target (`notable:`/`documentable:`) changes. Built and live on
  those three show pages; not yet on Customer's (see Customer/ActivityNote model sections above).
- Dashboard should surface: leads needing follow-up, active jobs, and unpaid/outstanding orders.

## Status Enums Reference

```ruby
Customer.status:    active | inactive | archived
Lead.status:        new | contacted | quoted | converted | lost
Quote.status:       draft | sent | accepted | rejected | expired
Job.status:         active | on_hold | completed | cancelled
Order.status:       draft | confirmed | invoiced | paid | cancelled
```

`Customer.status` is string-backed (not integer, unlike the others) and mixes two different
concepts: `active`/`inactive` is a manual, staff-chosen label with no behavioral effect;
`archived` is a system-driven state set only via `Customer#archive!` (never manually selectable
in the form) when a delete is blocked by history. `Customer.visible` (`where.not(status:
:archived)`) is the default scope for customer-facing views — see "Deletion Semantics" above.

## Job Types / Source Reference

```ruby
job_type: tile | flooring | materials | kitchen | mixed
source:   walk_in | phone | referral | website | other
```

---

## Planned: Authentication, Users & Authorization

These are upcoming goals, not yet built. The intent is to make Jobdeck a
real, multi-user product other construction businesses could actually run —
and a portfolio piece that demonstrates auth, RBAC, and SSO done properly.

### Users with login (session-based)

- Add a **User** model with email + password (bcrypt via `has_secure_password`,
  or Rails 8's built-in authentication generator).
- **Session-based** auth (not token/JWT) — server-side sessions, `SessionsController`
  with `new` / `create` / `destroy`, signed cookie holding the session id.
- Sign-in / sign-out flow, password reset via emailed token, "remember me".
- `current_user` helper + `require_authentication` before_action; unauthenticated
  requests redirect to the login page.
- Every write action attributes the actor — replace the free-text `assigned_to`,
  `author`, `uploaded_by` string fields with (or back them with) a real
  `user_id` reference over time.

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

1. User model + session-based login/logout + password reset.
2. Roles enum + Pundit policies + `authorize` / `policy_scope` everywhere.
3. Role-based view gating (nav + buttons + sections).
4. OmniAuth scaffolding + Google SSO.
5. Microsoft + SAML providers, JIT provisioning, SSO-only mode.

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

Wired into the **Customer and Lead index pages only** — `Job`/`Quote`/`Order` indexes are still
plain unfiltered/unpaginated `render @collection` (see TODO.md for that gap).

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
- **ActivityNote/Document UI on Customer's show page** — the `activity_notes` association exists
  on `Customer` but no view renders it there yet; `Customer` has no `documents` association at
  all yet either.
- **Ransack/Pagy on Job/Quote/Order indexes** — see "Search & Pagination" above.
- **Role-based nav/action-button gating** — blocked on the auth work (Phase 5) below;
  the shell is built to have `policy(record).action?` checks layered in later.
- **`tax_rate`'s "0.13 for 13%" input format** — flagged as confusing during the redesign
  (got a clarifying hint, not a semantics change) — actually accepting "13" would need a
  `before_validation` normalization and touches both Quote's and Order's show pages.
