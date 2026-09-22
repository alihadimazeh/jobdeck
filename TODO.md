# Jobdeck — Task Tracker

## Phase 1 — Core Models & Schema
- [x] Fix schema drift in customers migration
- [x] Fix schema drift in leads migration
- [x] Fix schema drift in jobs migration
- [x] Fix Job model (`optional: true` on `belongs_to :lead`)
- [x] Add `suffix: true` to `job_type` enums on Lead and Job
- [x] Create Quote migration + model
- [x] Create Room migration + model (nested under Quote)
- [x] Create QuoteLineItem migration + model (nested under Quote)
- [x] Create Order migration + model
- [x] Create LineItem migration + model (nested under Order)

## Phase 2 — Controllers
- [x] Customers controller
- [x] Leads controller
- [x] Jobs controller
- [x] Quotes controller (including nested Rooms + QuoteLineItems logic)
- [x] Orders controller (including nested LineItems logic)

## Phase 3 — Views
- [x] Customer views
- [x] Lead views
- [x] Job views
- [x] Quote views (with estimation tool + dynamic room/line item rows)
- [x] Order views (with dynamic LineItem rows)

## Phase 4 — Features & Polish
- [x] Estimation tool — Stimulus-powered room calculator on the Quote form
      (enter room dimensions → calculates sq footage → populates labor + material line items)
- [x] Lead → Job conversion (`convert_to_job!` on Lead model)
      — creates Job, seeds first Order from accepted Quote line items
      — "Accept Quote" button on Quote show page triggers this
- [x] Notes (polymorphic, shared partial across Lead/Job/Order)
      — done as **`ActivityNote`**, not `Note` — renamed specifically to avoid colliding
      with the pre-existing free-text `notes` column on `Quote`/`Order` (see CLAUDE.md →
      "ActivityNote (polymorphic)"). Turbo-Frame-per-row for inline edit/delete without a
      page reload. Full 14-milestone plan executed at `~/.claude/plans/sleepy-cuddling-tome.md`,
      one branch/PR per milestone (PRs #43–#51). Live on Lead/Job/Order show pages; **not**
      yet on Customer's, even though `Customer.activity_notes` exists as an association
      (added ahead of its view — see CLAUDE.md's Customer section).
- [x] Documents (polymorphic + Active Storage)
      — done: `Document` model, `documents_controller.rb`, `documents/_section.html.erb`
      shared partial, same three show pages as ActivityNote. PDF gets an inline "View" link,
      everything else "Download". Found two real bugs along the way (see Bugs below): a
      validation gap that let a Document save with no file attached, and a test-writing
      gotcha where Active Storage re-sniffs file content-type via Marcel regardless of what's
      declared on upload.
- [x] Dashboard (follow-up leads, active jobs, unpaid orders)
      — done as Step 14 of the UI/UX overhaul (branch `feature/ui-foundation-prep`):
      `DashboardController#show` + `root "dashboard#show"`, 5-row previews with true
      counts via `Lead.needs_follow_up`/`Job.active_status`/`Order.outstanding`.
- [x] Search/filtering (Ransack) — wired to the **Customer and Lead index pages**
      (`Job`/`Quote`/`Order` indexes still don't have it — worth its own follow-up, Job's
      index is the highest priority since it's the one unscoped top-level list). Every
      searched model needs explicit `ransackable_attributes`/`ransackable_associations`
      (security allow-list) — see `Customer`/`Lead`. Found a real bug: Ransack's `_eq`
      predicate on an integer-backed enum column doesn't know about Rails enums — it
      silently casts a non-numeric string label via `#to_i` instead of raising (see Bugs
      below). Full plan at `~/.claude/plans/sleepy-cuddling-tome.md`, Milestones 12–13.
- [x] Pagination (Pagy) — wired alongside Ransack on the same two index pages, same
      "not on Job/Quote/Order yet" caveat. Confirmed Pagy 43.x is a full rewrite of the
      classic `Backend`/`Frontend` API — no more `Pagy::Frontend`/`pagy_nav`; nav methods
      (`series_nav`) live directly on the `Pagy` instance `#pagy` returns
      (`@pagy.series_nav` in the view). See CLAUDE.md → "Search & Pagination" for the
      real API and the same plan file, Milestones 0 and 12–13.

### Phase 4 — Bugs found while building ActivityNote/Documents/Search+Pagination (2026-09-21)

- [x] **`has_many#build` pollutes the parent association's cache.** The first cut of
      `activity_notes/_section.html.erb` used `notable.activity_notes.build` to get a blank
      record for the "add a note" form — this silently populated `notable.activity_notes`'s
      *cached* target with the unsaved record, so a later `.any?` check on that same
      association in the same request wrongly returned `true`, breaking the empty-state UI.
      Fixed by using `ActivityNote.new(notable: notable)` instead (plain `.new`, not
      `.build` through the association) — applied proactively to `documents/_section.html.erb`
      too once the pattern was known.
- [x] **`Document` allowed saving with no file attached.** The original `acceptable_file`
      custom validation returned early when `file.attached?` was false, silently allowing an
      empty Document to save. Fixed by adding `errors.add(:file, "must be attached")` before
      the early return.
- [x] **Active Storage re-sniffs `content_type` via Marcel, ignoring what's declared on
      upload.** A spec reusing the real `sample.pdf` fixture but claiming a different
      `content_type:`/`filename:` kept getting correctly re-identified as a genuine PDF,
      making the "rejected content type" validation spec pass for the wrong reason (nothing
      was actually being rejected). Fixed by attaching a `StringIO` with real non-PDF magic
      bytes (`"MZ\x90\x00..."`, sniffed as `application/x-dosexec`) instead of reusing a
      real-PDF fixture under a fake declared type.
- [x] **Ransack's `_eq` predicate doesn't understand Rails enums.** The Lead index's status
      filter `<select>` was first built from `Lead.statuses.keys` (the string labels, e.g.
      `"contacted"`) — Ransack casts a non-numeric string via `String#to_i`
      (`"contacted".to_i == 0`), so the filter silently matched "new" leads regardless of
      which status was actually picked, with no error raised. Confirmed via
      `Lead.ransack(status_eq: "contacted").result.to_sql` showing `status = 0`. Fixed by
      building the `<select>` from `Lead.statuses` **values** (the integers) instead of the
      keys, with a regression spec (`leads_spec.rb`, "filters by status using the enum's
      integer value, not its label") guarding against it reappearing. Worth checking for the
      same trap on any future enum-column filter (see CLAUDE.md → "Search & Pagination").

## Testing

- [x] Add `rspec-rails` (+ `factory_bot_rails`) and set up `spec/` — no real test coverage
      exists right now. `test/models/*_test.rb` are unedited Minitest scaffold stubs
      (e.g. `lead_test.rb`, `customer_test.rb`), and there's no `quote_test.rb` at all
      despite `Quote` holding the app's core business logic. See CLAUDE.md → "## Testing".
      — done: both gems added (`group :development, :test` in `Gemfile`), `rails generate
      rspec:install` run (`.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb`).
      `rails_helper.rb`: enabled `config.infer_spec_type_from_file_location!`, added
      `config.include FactoryBot::Syntax::Methods`, uncommented the `spec/support/**/*.rb`
      autoload line. Old `test/` suite left in place (not migrated) — `bin/rails test` and
      `bundle exec rspec` both run, independently, green.
- [x] Write specs for the model logic that currently has zero coverage:
      - `Lead#convert_to_job!` happy path + the new idempotency guard (raises if `job.present?`)
      - `Quote#only_one_accepted_quote_per_lead` validation
      - `Quote`'s `after_save` → `convert_to_job!` trigger
      - `dependent: :restrict_with_error` chain (`Customer`/`Job`/`Lead` blocking delete when
        jobs/orders exist)
      - Enum values/ordering on `Lead`, `Job`, `Quote` (guards against another integer-backed
        enum reorder mistake like the `Lead.source` one)
      — done: `spec/models/{customer,lead,job,quote,room,order,line_item,quote_line_item}_spec.rb`
      (every model now has its own spec file), plus `spec/factories/*.rb` (one per model) and
      `spec/support/shared_examples/billable_line_item.rb` (one shared example group covering the
      `BillableLineItem` concern, run against both `LineItem` and `QuoteLineItem` instead of
      duplicating the spec). Every item on the list above is covered, including regression specs
      for both bugs found/fixed this session (the idempotency guard, and the nested-cascade
      `restrict_with_error` ordering fix — the exact reject-then-accept-a-different-quote sequence
      and the converted-Lead-blocks-Customer-destroy-cleanly case are both now automated).
- [x] Add request specs for every controller (`spec/requests/{customers,leads,jobs,orders,quotes}_spec.rb`)
      — full CRUD per controller (index/show/new/create/edit/update/destroy), plus
      `QuotesController#accept` (happy path, the `only_one_accepted_quote_per_lead` validation
      alert, and the re-conversion-guard alert — same three cases as the model-level specs, now
      also verified through the actual HTTP/flash layer). Found and documented a real gap while
      writing these: `Customer` has zero model-level validations (see new Bugs entry below) — the
      customer request specs document that actual behavior rather than asserting a validation
      that doesn't exist.
      — **122 examples, 0 failures** (`bundle exec rspec`). `bin/rails test` still green
      separately (14 runs, 0 failures). Not yet covered: system/feature-level specs (JS-driven
      estimation tool, nested room/line-item row add/remove).

## Follow-up PRs (deliberately kept out of current work)

- [x] Try a "navy + blue CTA" color scheme for the daisyUI `jobdeck` theme, as an
      alternative to the original "industrial slate + safety orange." Done on
      `feature/navy-blue-theme` (branched after the full redesign finished, so none of the
      contrast/badge-variant work had to be re-checked — only the 4 brand tokens changed,
      not base/status colors): primary `#0369A1`, secondary `#334155`, accent `#075985`,
      neutral `#0F172A`. Merged to `main` via PR #42 (2026-09-18) — this is now the live
      palette, not a trial. The original orange values are still in git history
      (`cdc4e38` on `feature/ui-foundation-prep`) if ever wanted back.
- [x] Zebra-striped table rows — `.table tbody tr:nth-child(even)` in `application.css`,
      `color-mix()` off `base-content`/`base-100` rather than daisyUI's own `table-zebra`
      class (which would've reused `base-200`, already the page canvas color, making the
      stripe nearly invisible). Merged to `main` alongside the color scheme.
- [x] Row-actions kebab button centered in its table column instead of right-aligned —
      one-line change to `shared/_row_actions`, merged to `main` alongside the above.

- [x] Customer soft-delete via `status` enum (`active | archived`) — back the existing
      unenforced `Customer.status` column with a real enum, add an `archive!` action/button
      replacing "Delete" as the primary path for customers with Job/Order history, and scope
      default index/dashboard views to exclude archived customers. `destroy` stays available
      underneath (guarded by the `restrict_with_error` chain above) for customers with no
      history at all. Touches UI, so scoped as its own PR rather than folded into the Model
      Review cleanup. Overlaps `Customer.status` item under Consistency/robustness below.
      — done (branch `feature/customer-archive`): PR #39 had already extended `Customer.status`
      to a real enum, but as `active | inactive` — a pre-existing *manual* "is this customer
      relationship active" toggle, a different concept from "this delete got redirected into an
      archive." Rather than overload `inactive` with both meanings, extended to a third state:
      `enum :status, { active: "active", inactive: "inactive", archived: "archived" }` (string-backed,
      no migration) + `Customer#archive!` (`update!(status: "archived")`).
      `CustomersController#destroy` now tries `@customer.destroy` first; if that comes back `false`
      (blocked by the `restrict_with_error` chain — the only way it can fail, since Job/Order
      `customer_id` is always set directly and NOT NULL, so there's no way for a blocking record to
      exist without also tripping Customer's own `jobs`/`orders` check), it calls `archive!` instead
      and shows a distinct flash notice, rather than duplicating the "does this have history" check
      in the view as a second button. Added `Customer.visible` scope (`where.not(status: :archived)`)
      and used it in `CustomersController#index`. Badge logic in `_customer.html.erb`/`show.html.erb`
      updated to a three-way color mapping (archived gets a distinct red-ish badge, not the same
      gray as inactive). The status `<select>` in `_form.html.erb` deliberately still only offers
      Active/Inactive — `archived` is only ever reached via the delete-fallback, never manually
      chosen. Fixed a Minitest regression this surfaced: `customer_test.rb`'s "rejects values outside
      the enum" test used `"archived"` as its example of an invalid value, which broke once archived
      became real — swapped to `"bogus"` and added a dedicated "status accepts archived" test.
      Explicitly out of scope (per the discussion before starting): restore/unarchive, anonymization
      (archiving keeps all PII, doesn't address genuine data-removal requests), and dashboard scoping
      (no dashboard exists yet — Phase 4). 129 RSpec examples, 19 Minitest runs, 0 failures.
- [x] Add a Delete/Archive button to the Customer **show** page — it currently only has "Edit"
      (`customers/show.html.erb:41`). The only existing entry point to `CustomersController#destroy`
      (and therefore the archive fallback above) is the kebab dropdown on the **index** row
      (`_customer.html.erb`); there's no way to delete/archive a customer from their own show page.
      Every other model's show page has a Delete link next to Edit (see UI/UX audit item U6 below
      for the styling gap on *those*) — Customer's show page is missing the entry point entirely.
      — fixed: added the same `link_to "Edit"` + `button_to "Delete"` pair used on every other
      show page (`jobs/show.html.erb` etc.) — same styling, same `turbo_confirm` pattern, wrapped
      in the same `flex items-center gap-3 ml-6 flex-shrink-0` div. Button label/confirm text stays
      "Delete" (matches the index dropdown's existing wording) — the archive-vs-destroy outcome is
      decided server-side and communicated via the flash message after, not the button itself.
      Added a request spec asserting Edit/Delete both render on the show page. 130 RSpec examples,
      19 Minitest runs, 0 failures.

## Model Review — Associations & Definitions

### Bugs
- [x] `Lead.source` enum order is wrong — spec is `walk_in | phone | referral | website | other`,
      code has `referral: 1, phone: 2` (swapped). Integer-backed, so existing rows are mislabeled.
      — fixed to `walk_in: 0, phone: 1, referral: 2, website: 3, other: 4`. Note: `seeds.rb` sets
      `source` symbolically so it's unaffected; `test/fixtures/leads.yml` has a raw `source: 1`
      whose meaning silently shifted (referral → phone) but nothing asserts on it, so no test broke.
      A real production table would need a data migration alongside a reorder like this, not just
      the hash edit.
- [x] `Customer` can't be destroyed when it has jobs — `has_many :jobs` has no `dependent:` and the
      FK has no `ON DELETE`, so `customer.destroy` raises `ActiveRecord::InvalidForeignKey`.
      Add `dependent: :restrict_with_error` (matches `Job#orders` / `Lead#orders`).
      — fixed: `has_many :jobs, dependent: :restrict_with_error`, ordered *before* `:orders` in the
      model (every Order requires a Job, so checking jobs first always produces the right error
      message; checking orders first could under-report). Verified: `customer.destroy` on a customer
      with a Job returns `false` with `"Cannot delete record because dependent jobs exist"`, no raised
      exception, nothing destroyed.
- [x] `Lead has_many :quotes` is intended (a lead can have multiple quotes). Add a guard so at most
      one quote per lead is in the `accepted` state.
      — done via `Quote#only_one_accepted_quote_per_lead` validation. Known gap tracked separately
      below (`convert_to_job!` has no idempotency check).
- [x] `convert_to_job!` has no idempotency check — accepting a second Quote on a Lead that
      already converted silently creates a duplicate Job instead of raising/blocking. Sequence:
      Quote A accepted → Job created, Lead flips to `converted` (`lead.rb:13-31`, triggered by
      `quote.rb:19`) → Quote A later rejected — the un-accept isn't guarded, because
      `only_one_accepted_quote_per_lead` only runs `if: :accepted_status?` (`quote.rb:14`), so
      moving *away* from `accepted` never gets checked → Quote B accepted on the same Lead: the
      one-accepted-quote guard passes because Quote A is no longer `accepted`
      (`quote.rb:27-31`), so the `after_save` fires again and calls `lead.convert_to_job!(quote_b)`.
      Inside, `create_job!` (`lead.rb:15`) is the `has_one :job` builder — since
      `Lead has_one :job, dependent: :nullify` (`lead.rb:9`), creating the new Job doesn't raise,
      it just nullifies `lead_id` on the *original* Job (silently orphaning it and its
      Orders/LineItems from the Lead) and builds a second Job+Order for Quote B. No exception,
      no validation error — just a silently duplicated/orphaned financial record.
      — fixed: `convert_to_job!` now raises immediately if `job.present?`
      (`lead.rb:14`, `raise "This lead has already been converted to a job" if job.present?`),
      before the `transaction do` block. Since this raises inside Quote's `after_save`, it
      propagates out of `quote.update!`'s own transaction and rolls the whole save back — the
      re-accept attempt on Quote B is fully undone (status reverts, no Job/Order created), not
      just partially. `QuotesController#accept`'s existing generic `rescue => e` already turns
      this into a flash alert instead of a 500. Verified via `bin/rails runner`: after the
      reject-then-accept-a-different-quote sequence, `quote_b.status` stays `draft`, exactly one
      Job exists for the Lead, and `lead.job` still points at the original Job.
- [x] `restrict_with_error` several levels deep in a `dependent: :destroy` cascade doesn't
      surface an error or roll back cleanly. Found while writing up the deletion-semantics
      doc below. Repro: a `Customer` with a converted `Lead` — i.e. any normal Lead→Job
      conversion, not a rare setup, since `convert_to_job!` always sets `lead:` on the seeded
      Order (`lead.rb:21-23`), giving that Order both `job_id` and `lead_id`. Calling
      `customer.destroy` traces as: `Customer`'s `leads, dependent: :destroy` cascade
      (`customer.rb:2`) reaches into `Lead#destroy`, which runs *its own* before_destroy chain
      in order — `job, dependent: :nullify` (`lead.rb:9`, fires: `UPDATE jobs SET lead_id = NULL`),
      `quotes, dependent: :destroy` (`lead.rb:10`, fires: quotes actually deleted), then
      `orders, dependent: :restrict_with_error` (`lead.rb:11`) finds the Order and aborts.
      `Customer`'s *own* `jobs`/`orders` restrict checks (`customer.rb:4-5`) never even run —
      confirmed via SQL log, no `Job`/`Order` query for the customer-level check ever fires.
      Cause: `restrict_with_error`'s `throw(:abort)` only halts the callback chain it's declared
      in (Lead's); Lead's own `with_transaction_returning_status` then raises
      `ActiveRecord::Rollback` — a real exception, not a `throw` — which propagates past
      Customer's `run_callbacks(:destroy)` (that only catches `throw(:abort)`) and is caught much
      higher up, inside *Customer's* `with_transaction_returning_status`. Net result:
      `customer.destroy` returns `false`, but `customer.errors` is completely empty (no message
      to show a user), and — since none of `Lead.transaction`/`Customer.transaction` ever opened
      a real savepoint (no `requires_new: true` anywhere in this chain) — the `Job.lead_id = NULL`
      update and the Quote deletions from earlier in Lead's callback chain are **not undone**.
      — fixed by reordering, no new code: `Customer`'s `jobs`/`orders` (restrict_with_error) now
      declared *before* `leads`/`quotes` (destroy) (`customer.rb`), and `Lead`'s `orders`
      (restrict_with_error) now declared before `job` (nullify)/`quotes` (destroy) (`lead.rb`).
      Works because `Job`/`Order` both have a direct, `NOT NULL` `customer_id` (Order's is now
      auto-set — see the auto-set-`customer_id` item above), so `customer.jobs`/`customer.orders`
      already see everything regardless of Lead involvement; checking them before the `leads`
      cascade starts means a blocked delete is caught before any partial mutation can happen, and
      the error lands on the right record. The `Lead` reorder is defense-in-depth for `Lead#destroy`
      called directly (not just via Customer). Verified via `bin/rails runner` with SQL logging on
      all three cases: Customer-with-converted-Lead (now `false` + `"Cannot delete record because
      dependent jobs exist"`, nothing mutated), plain `Lead#destroy` with an Order (still blocks,
      Job/Quote left untouched), and the original Customer-with-direct-Job-only case (unchanged).
      Full test suite still green. See CLAUDE.md → "Deletion Semantics" for the updated rule.
- [x] `Customer` has **zero model-level validations** — `first_name`, `last_name`, and `phone` are
      all `NOT NULL` at the DB level (`db/schema.rb`) but nothing in `app/models/customer.rb`
      validates their presence. Found while writing request specs: `Customer.new(first_name: "",
      last_name: "", phone: "").valid?` returns `true` (blank string satisfies the DB's NOT NULL
      constraint, which only rejects actual `NULL`). Consequence: `CustomersController#create`/
      `#update`'s `unprocessable_content` re-render branch was unreachable for blank required
      fields — the form just silently saved them blank instead of showing a validation error.
      — fixed (branch `fix/customer-validations`): added
      `validates :first_name, :last_name, :phone, presence: true` to `customer.rb`, alongside the
      existing `validates :status, presence: true`. Updated the two `spec/requests/customers_spec.rb`
      specs that were documenting the gap to now assert the real `unprocessable_content` behavior
      instead, and added a `validations` describe block to `spec/models/customer_spec.rb`.
      Verified via `bin/rails runner` and the full suite: blank required fields now correctly fail
      validation. 124 RSpec examples / 18 Minitest runs, 0 failures.

### Missing vs spec
- [x] `Customer has_many :orders` — omitted from the model even though `orders.customer_id` is `NOT NULL`.
      — added as `dependent: :restrict_with_error`, matching `:jobs` (see Bugs above).
- [x] Polymorphic `has_many :activity_notes, as: :notable` / `has_many :documents, as:
      :documentable` on Lead / Job / Order — done alongside the Phase 4 items above.
- [x] `Quote` → on status flip to `accepted`, trigger `convert_to_job!` on the Lead
      — `after_save { lead.convert_to_job!(self) if saved_change_to_status?(to: "accepted") }`

### Consistency / robustness
- [x] Document the intended deletion semantics — `dependent:` is currently ad hoc
      (destroy vs nullify vs restrict_with_error) with no stated rule.
      — documented in CLAUDE.md → "Deletion Semantics (`dependent:` conventions)": destroy for
      detail records with no independent value, restrict_with_error for not-nullable financial
      data, nullify for independently-meaningful records with a nullable FK. While writing this
      up, found and logged a real bug in how `restrict_with_error` behaves several levels deep in
      a cascade — see new Bugs entry above.
- [x] Auto-set denormalized `customer_id` — `before_validation { self.customer_id ||= lead&.customer_id }`
      on `Quote`, and `||= job&.customer_id` on `Order`, so it's not the controller's job every time.
      — fixed: added `assign_customer_from_lead`/`assign_customer_from_job` `before_validation`
      callbacks on `Quote`/`Order` (`quote.rb`, `order.rb`). Removed the now-redundant explicit
      `@quote.customer = @lead.customer` / `@order.customer = @job.customer` lines from
      `QuotesController#create` / `OrdersController#create`. `Lead#convert_to_job!` already passes
      `customer:` explicitly when creating the seed Order — that still works unchanged since the
      callback only fills it in with `||=`. Verified via `bin/rails runner`: creating a Quote/Order
      with no `customer` given picks up the right `customer_id` from `lead`/`job`. Full test suite
      still green (14 runs, 0 failures).
- [x] `Lead` has no validations — add `validates :title, presence: true` (column is `NOT NULL`; `Job` has it).
- [x] `Customer.status` has no enum or validation.
      — fixed (`customer.rb`, branch `fix/customer-status-enum`): `enum :status, { active: "active",
      inactive: "inactive" }, suffix: true` + `validates :status, presence: true`. Deliberately kept
      **string-backed** (no migration) — the column already stores `"active"`/`"inactive"` and every
      other read/write path (form select, seeds, fixtures) already only ever writes those two values,
      so this is a pure model-layer tightening: invalid values now raise `ArgumentError` on assignment
      instead of being silently accepted, and `active_status?`/`inactive_status?`/`Customer.active_status`
      etc. are available like the other enums. Deliberately did **not** touch storage format or add an
      `archived` state — that's the separate, UI-touching "Customer soft-delete" Follow-up PR above;
      this fix and that one don't conflict (the future migration can still repoint the enum's integer
      or string values however it wants). Verified via `bin/rails runner` (default value, predicates,
      invalid-value raise, scope) and a real `test/models/customer_test.rb` (was an empty stub) — 4 new
      tests, full Minitest suite still green (18 runs, 0 failures).
      Also found: `CLAUDE.md` committed on this branch/`main` predates the Quote/Room/Order model work
      entirely (last touched by `22359a5`, before PRs #35–#37) — the richer CLAUDE.md content (Quote/Room,
      Deletion Semantics, RSpec/Testing sections) everyone's been reading has only ever existed as
      **uncommitted** working-tree changes, never part of a commit. Not touched here (out of scope,
      and didn't want to layer a doc edit on a stale base) — flagged to the user; worth its own commit.
- [x] Stale checkbox: the nested-cascade `restrict_with_error` bug above was already fixed (verified
      `customer.rb`/`lead.rb` declare `restrict_with_error` associations before `destroy`/`nullify`
      ones, exactly as the resolution note under it describes) and merged via PR #37 — checkbox just
      never got ticked. No code change, tracker correction only.
- [x] Add `suffix: true` to `Lead.source` enum (inconsistent with `status` / `job_type`).
      — fixed (`lead.rb`); predicates are now `walk_in_source?` / `phone_source?` / etc.
      Checked first that nothing in the app called the old bare predicates/scopes
      (`grep` came back empty), so this is a non-breaking rename.
- [x] Add explicit `inverse_of` on nested-attributes assocs
      (`Quote → rooms / quote_line_items`, `Order → line_items`).
      — added on both sides: `Quote#rooms`/`#quote_line_items` ↔ `Room`/`QuoteLineItem#quote`,
      `Order#line_items` ↔ `LineItem#order`. Verified via `bin/rails runner` that the
      reflections report the inverse correctly; full test suite still green (14 runs, 0 failures).
- [x] Extract shared `calculate_total` / validations from `LineItem` + `QuoteLineItem` into a concern.
      — fixed: added `app/models/concerns/billable_line_item.rb` (`BillableLineItem`, an
      `ActiveSupport::Concern`) carrying the `item_type` enum, all four validations, the
      `before_save :calculate_total` callback, and the `calculate_total` method itself — the parts
      that were byte-for-byte identical between the two models. `LineItem`/`QuoteLineItem` now each
      just `include BillableLineItem` plus their own distinct `belongs_to` (`order`/`quote`). Models
      intentionally stay separate (different lifecycles per CLAUDE.md) — only the duplicated
      behavior moved. Verified via `bin/rails runner`: enum predicates, the total calculation, and
      validations all still behave identically on both models; full test suite still green.
- [x] Update CLAUDE.md: `LineItem.item_type` / `QuoteLineItem.item_type` are both integer enums now,
      not string/integer as documented.
      — fixed: `QuoteLineItem` was already documented correctly (`integer`); `LineItem`'s schema
      block said `item_type string, null: false`, which didn't match either the actual schema
      (`db/schema.rb` has `t.integer "item_type"`) or the model (`enum :item_type` via the new
      `BillableLineItem` concern). Corrected to `integer`.

## Phase 5 — Authentication, Users & Authorization

> **Goal:** make Jobdeck a real, multi-user product other construction
> businesses could run, and a portfolio piece demonstrating auth / RBAC / SSO.
> See CLAUDE.md → "Planned: Authentication, Users & Authorization".

### Users + session-based login
- [x] `User` model — email + `has_secure_password` (or Rails 8 auth generator)
- [x] Session-based auth — `SessionsController` (`new` / `create` / `destroy`), signed cookie
- [x] Sign-in / sign-out UI
- [x] Password reset via emailed token
- [x] "Remember me"
- [x] `current_user` helper + `require_authentication` before_action (redirect to login)
      — done as `app/controllers/concerns/authentication.rb`, included in
      `ApplicationController` (branch `feature/user-auth-sessions`). Every controller now
      requires a signed-in session by default; a controller opts out per-action with
      `allow_unauthenticated_access only: [...]`. Full flow (sign in, wrong password, sign out,
      request-a-reset, follow the token, set a new password, sign in with it) verified against a
      real running server via curl, not just the test suite. See CLAUDE.md → "## Authentication
      (Phase 5, milestone 1 — shipped)" for the full design writeup. 298 RSpec examples / 19
      Minitest runs, 0 failures (both suites updated to sign in first — see CLAUDE.md →
      "## Testing"). No sign-up/user-management UI yet: `db/seeds.rb` creates one dev user
      (`admin@jobdeck.test` / `password123`), anyone else is made via `User.create!` until
      Pundit + an admin role exist (next item below).
- [ ] Migrate `assigned_to` / `author` / `uploaded_by` free-text fields to `user_id` references
      — **deliberately deferred**, not part of the milestone-1 PR above: touches several
      models' forms/views (Lead, Job, ActivityNote, Document) and is really milestone-2-shaped
      work (attributing actions to a real user only means something once roles/Pundit exist to
      say who's allowed to act as whom) — its own follow-up PR.

#### Bug found while shipping the above (2026-09-21)
- [ ] **`CustomersController`/`LeadsController#index` pagination relies on unspecified row
      order.** `@q.result(distinct: true)` has no explicit `.order`, so which records land on
      page 1 vs page 2 depends on whatever order Postgres's query planner happens to return for
      `SELECT DISTINCT` — not guaranteed to match id/insertion order, and confirmed to actually
      vary (reproduced on `main`, unrelated to this branch, via
      `bundle exec rspec --seed 3`: `customers_spec.rb`/`leads_spec.rb`'s pagination tests fail
      once enough other specs have run first that the records involved land on high ids). Not
      fixed here (out of scope for the auth PR that found it) — fix is a one-line
      `.order(:id)` (or a real sort column) added to both controllers' `index` actions.

### Role-based views and permissions
- [ ] `role` enum on User — `admin | project_manager | sales | viewer` (integer-backed)
- [ ] Add Pundit — one policy per model
- [ ] `authorize` in every controller action, `policy_scope` on every index
- [ ] Role-based view gating — nav, action buttons (Edit/Delete/Accept Quote/Convert), sections
      via `policy(record).action?` (no ad-hoc role checks in views)
- [ ] Deny-by-default (missing policy method ⇒ no access)

### SSO
- [ ] Add OmniAuth scaffolding
- [ ] `Identity` join model — `user_id`, `provider`, `uid` (multiple providers per user)
- [ ] Google Workspace (OAuth2) provider
- [ ] Microsoft Entra ID provider
- [ ] Generic SAML 2.0 provider
- [ ] Just-in-time provisioning — first SSO login creates User as `viewer`, admin promotes
- [ ] Optional "SSO only" mode (disables password login per deployment)

## Phase 6 — UI Revamp

> **Goal:** replace the default scaffold styling with a cohesive, polished UI
> before showing Jobdeck as a real product / portfolio piece.
> Shipped and merged to `main` via PR #42 (2026-09-18, `feature/navy-blue-theme`, which
> carried all of `feature/ui-foundation-prep`'s 16-step execution plan at
> `~/.claude/plans/let-s-tackle-the-ui-ux-fancy-pnueli.md`). See CLAUDE.md → "Design
> System" for what's actually live now.

- [x] Establish a Tailwind design system — layout, spacing, typography, color tokens
      (daisyUI `jobdeck` theme — navy + blue CTA, self-hosted Inter; retinted from the
      original "industrial slate + safety orange" post-launch, see Follow-up PRs below)
- [x] App shell — persistent nav / sidebar, page headers, breadcrumbs, flash/toast styling
      (daisyUI `drawer`, `shared/_page_header`, `shared/_flash`)
- [x] Reusable partials/components — tables, forms, buttons, badges, cards, empty states
      (`app/views/shared/*`)
- [x] Shared Notes / Documents UI styling — built as `ActivityNote`/`Document` in Phase 4
      (PRs #43–#51), well after this redesign shipped. Stale checkbox correction only.
- [x] Polished dashboard layout (follow-up leads, active jobs, unpaid orders) — Step 14
- [x] Responsive / mobile-friendly layouts — verified at 375/768/1024/1440px throughout
- [ ] Wire role-based nav + action buttons into the revamped UI — **not started**, blocked on
      Phase 5 (no User/role model yet)

### UI/UX Audit findings (2026-09-03) — addressed 2026-09-18

> Full walk-through of the layout, every index/show/form, partials, helpers and
> Stimulus controllers, done before the redesign started. All items below were re-checked
> against the finished `feature/ui-foundation-prep` branch (real browser measurements +
> compiled-CSS contrast math, not just a code read) rather than assumed fixed because a
> related file changed.

#### Critical — Accessibility
- [x] A1 — `lang="en"` added to `<html>` (`layouts/application.html.erb`)
- [x] A2 — kebab/remove-row buttons now have `aria-label` + `aria-haspopup`/`aria-expanded`
      via `shared/_row_actions` (daisyUI Popover API — no custom JS needed for the ARIA state)
- [x] A3 — decorative `<svg>`s carry `aria-hidden="true" focusable="false"` (`_flash`,
      `_row_actions`, `_navbar`, `_empty_state` icon slot)
- [x] A4 — muted text now `text-base-content/70` on the theme's `base-100`/`base-200`
      surfaces — measured 6.5:1 / 6.61:1 via alpha-blend contrast math, both pass AA
- [x] A5 — `shared/_form_errors` wraps the summary in `role="alert" tabindex="-1"` with an
      `autofocus` Stimulus controller moving focus there on failed submit
- [x] A6 — resolved by deleting `dropdown_controller.js` entirely (Step 13) rather than
      patching its ARIA — replaced with daisyUI's native Popover API (`popovertarget`/
      `anchor-name`), which gets focus/Escape/positioning for free from the browser and
      renders in the top layer so it can't clip or go stale on scroll
- [x] A7 — `aria-label="Primary"` on the sidebar `<nav>`, `aria-label="Breadcrumb"` on the
      page-header `<nav>`, skip-to-content link added to the shell
- [x] A8 — focus ring is `outline: 2px solid var(--color-primary)`. Measured 3.56:1 against
      white under the original orange palette (`#EA580C`) — clears the 3:1 non-text-UI
      minimum but not the stricter 4.5:1 text threshold, which is why button *text* needed
      its own fix (below). Since retinted to navy + blue (`#0369A1`): now 5.93:1, clearing
      both thresholds with room to spare — re-verified after the palette swap, not just
      assumed carried over

#### High — Mobile / responsive (app is effectively desktop-only)
- [x] R1 — sidebar is now a daisyUI `drawer` (`lg:drawer-open` permanent on desktop,
      collapsible overlay + hamburger below that) — Step 6/7
- [x] R2 — every table wrapped in `overflow-x-auto` via `shared/_table`
- [x] R3 — `shared/_stats`/`_detail_list` grids use responsive breakpoints
- [x] R4 — quote/order line-item and room editors reworked to stack on mobile — Steps 11-12,
      verified with a real click-through of the estimation tool at 375px, zero JS changes
- [x] R5 — standardized via `shared/_form_container` (`width: :md/:lg`)

#### Medium — Consistency & DRY
- [x] C1 — inputs now daisyUI `input`/`select`/`textarea` classes via `shared/_field`
- [x] C2 — collapsed to one `status_badge` helper + `STATUS_VARIANTS` hash + `shared/_badge`;
      label casing unified across all 5 resources
- [x] C3 — collapsed to `render "shared/row_actions", ...`
- [x] C4 — collapsed to `shared/_form_errors`
- [x] C5 — collapsed to `shared/_table` (`columns:`/`footer:` locals)
- [x] C6 — brand colors are now daisyUI theme tokens (`--color-primary`, `--color-neutral`,
      etc.) in `app/assets/tailwind/application.css` — zero raw hex/`amber-*` left in views
      (confirmed via a final grep sweep, Step 16)
- [x] C7 — collapsed to `format_date` helper

#### Medium — UX / IA
- [x] U1 — dashboard built (`DashboardController#show`, `root "dashboard#show"`) — Step 14
- [ ] U2 — pagination/search (Pagy/Ransack) — **not part of this redesign**, still not in the
      Gemfile, remains open under Phase 4
- [x] U3 — primary action now lives in the `page_header` row beside the `<h1>`
      (`action:`/`actions:` locals)
- [x] U4 — `page_header` suppresses the breadcrumb's last crumb when it duplicates the title
- [x] U5 — nested pages (quote/order) now correctly highlight their parent nav section —
      fixed in Step 4 as a side effect of building `nav_section_active?`
- [x] U6 — show-page Delete now goes through the same `shared/_row_actions` pattern used on
      index rows (44px target, styled destructive action, no more bare text link)
- [x] U7 — `turbo_submits_with: "Saving…"` added to all 5 resource forms
- [x] U8 — touch targets fixed to a real 44px floor everywhere, including a gap the initial
      restyle itself introduced and only the Step 16 sweep caught: `.btn-sm` (kebab trigger,
      remove-row buttons) was still 36px and the row-actions popover's menu links were 33px.
      Fixed in `application.css` (`.btn-sm` → 2.75rem, `.menu li > a/button` → 2.75rem) and
      re-measured via a real headless-browser check — all 44px now
- [ ] U9 — `tax_rate` percent-entry semantics — **not changed**, out of scope for a visual
      redesign, remains open
- [ ] U10 — Customer index status filter — **not part of this redesign**, remains open (see
      the "Customer soft-delete" item above)

#### Low — polish
- [x] Removed `hello_controller.js` (Step 1)
- [x] `prefers-reduced-motion` guard added (Step 3) and verified at runtime via Chrome
      DevTools Protocol emulation (Step 16) — transition genuinely drops to `none` under
      `reduce`, confirmed it's `opacity, visibility` otherwise so the media query is doing
      real work, not just present in source
- [x] Empty states now support an icon + message + optional CTA (`shared/_empty_state`)

#### Found fresh during the Step 16 final sweep (not in the original 2026-09-03 audit)
- [x] `btn-primary`'s white-on-`#EA580C` text measured 3.56:1 — below the 4.5:1 AA minimum
      for normal text (the outline/focus-ring case above passes because 3:1 is the non-text
      threshold; button *text* needs the stricter one). Fixed at the time by changing
      `--color-primary-content` to a dark navy (`#0F172A`, 5.02:1) rather than touching the
      brand orange itself. Checked every other daisyUI `-content` pairing by the same method
      — all already passed (5.02–14.63:1). **Superseded** by the navy + blue retint below —
      white-on-`#0369A1` measures 5.93:1 on its own, so `--color-primary-content` is back to
      plain white; this fix's own workaround no longer applies, but the check that caught it
      is still why every `-content` pairing was re-verified after the palette swap instead of
      assumed fine.

## Known bugs / Nice-to-haves (found 2026-09-21)

- [x] **Bug:** sidebar doesn't extend to the bottom of the page — scrolling down a long page,
      the sidebar ends before the bottom of the screen instead of staying full height
      alongside the content.
      — fixed (branch `fix/sidebar-full-height`): confirmed via a headless-Chrome measurement
      (`document.body.scrollHeight` was 753px against a 257px viewport, with `<body>` as
      `document.scrollingElement` — the whole page was scrolling, not `#main`) that the real
      cause was the classic flex/grid `min-height: auto` trap, not the `h-full`/`overflow-auto`
      setup itself: `.drawer` (daisyUI, `display: grid`) sized its row track to its tallest
      grid item's *content* height instead of its own `h-full`, because `.drawer-content` (the
      grid item) had no `min-height: 0` to override the default `min-height: auto` floor — and
      even after fixing that layer, `#main` (`flex-1 overflow-auto`, a flex item of
      `.drawer-content`) had the identical problem one level down, growing to its content's
      full height instead of being clamped to the space left after the navbar/header, so
      `overflow-auto` never had anything to actually scroll. Fixed by adding `min-h-0` to
      *both* `.drawer-content` and `#main` in `layouts/application.html.erb` (2-line diff).
      Re-verified after the fix: `body.scrollHeight` now equals `innerHeight` exactly (no
      page-level scroll at all), `#main` scrolls its own overflow internally, and the sidebar's
      `getBoundingClientRect()` stays pinned at `top:0 / bottom:<viewport height>` before *and*
      after scrolling — checked at a forced-short 1400×400 viewport (to guarantee overflow),
      plus normal desktop (1440×900) and mobile (375×700) sizes, on `/customers`, `/` (dashboard,
      which does scroll internally — `mainScrollHeight` 779 > `mainClientHeight` 724, working as
      intended), and `/leads`, with no regression to the mobile overlay drawer's show/hide
      behavior. `bin/rails test` (19 runs) and `bundle exec rspec` (299 examples) both green.

- [ ] **Nice to have:** front-end phone number format validation on the Customer form
      (`app/views/customers/_form.html.erb:10`, `shared/_field`).
      - **Current state:** the field already renders as `as: :phone` → `type="tel"`
        (`form.phone_field`), but `type="tel"` has no built-in format checking in any browser
        — right now literally any string passes client-side.
      - **How to do it:** pass an HTML5 `pattern` (+ `inputmode: "tel"`) through `_field`'s
        existing `options: {}` local, e.g. `options: { pattern: "[0-9+\\-\\s()]{7,}",
        inputmode: "tel", title: "Enter a valid phone number" }` — native browser validation,
        blocks submit and shows the browser's own inline error, no JS needed. If something
        stricter is wanted (reject letters, enforce a specific format) a small Stimulus
        controller (e.g. `phone_field_controller.js`, following the existing
        `autofocus_controller.js` pattern used by `shared/_form_errors`) validating on
        `input`/`blur` would be the next step up. Either way this should stay a soft
        client-side convenience — the real guard stays server-side (see below).

- [ ] **Nice to have:** proper email format validation, both ends, on the Customer form.
      - **Current state:** the field already renders as `as: :email` → `type="email"`
        (`app/views/customers/_form.html.erb:11`), so it already gets *some* free browser
        format checking on submit — but HTML5's built-in email pattern is very permissive
        (e.g. `a@b` passes), and there's no matching check server-side at all — `customer.rb`
        only has `validates :phone, presence: true` etc., nothing on `email`'s format.
      - **How to do it:** add `validates :email, format: { with: URI::MailTo::EMAIL_REGEXP },
        allow_blank: true` to `customer.rb` (`email` isn't a required field, so
        `allow_blank:` keeps it optional while still rejecting a malformed value if one is
        entered) — `URI::MailTo::EMAIL_REGEXP` ships with Ruby's stdlib, no gem needed. This
        is the higher-value half of the two, since the client-side HTML5 check is trivially
        bypassed (devtools, curl, disabled JS) and only the server-side validation is a real
        guarantee.

## UI/UX Audit findings (2026-09-21)

> Full read-through audit of every view, shared partial, helper, and Stimulus controller,
> done post-Phase-4 (ActivityNote/Documents/Search+Pagination all just shipped). Grounded
> against the `ui-ux-pro-max` skill's UX guideline database, not just opinion — computed
> contrast ratios against the actual documented palette rather than assumed. Overall verdict:
> the daisyUI semantic-token rule has zero exceptions anywhere in `app/views` (confirmed by
> grep), and the shared partial library is used consistently everywhere it should be — this
> is fix-up work on an otherwise solid design system, not a rescue job.

#### Critical
- [x] **Search inputs have no accessible label** — `customers/index.html.erb:9-11` and
      `leads/index.html.erb:9-16` both use `f.search_field` with only a `placeholder:`, no
      `<label>`/`aria-label`. Placeholder text disappears once typed, leaving screen reader
      users with no accessible name for the field. Every other input in the app (via
      `shared/_field`) gets this right — isolated miss in the two hand-rolled search forms.
      — fixed (PR #54): added an `sr-only` `f.label` alongside each search field.
- [x] **`populateLineItems` silently destroys line items with no confirmation** —
      `app/javascript/controllers/quote_form_controller.js:53-67` marks every existing line
      item `_destroy=1` and hides it *before* checking whether either rate field has a value.
      Leaving both Labor/Material Rate blank wipes every manually-entered line item with zero
      warning and no undo. Every record-level delete elsewhere in the app uses a specific
      `turbo_confirm` message — this JS action is the one silent exception.
      — fixed (PR #54): added a guard (`if (laborRate <= 0 && materialRate <= 0) return`)
      before any existing row gets marked for destruction.
- [x] **Error-variant badges/alerts fall just under WCAG AA contrast** — `--color-error:
      #DC2626` on daisyUI's `badge-soft`/`alert-soft` background computes to **4.27:1**,
      under the 4.5:1 AA minimum for normal text (every other status color clears it:
      warning/success 4.51:1, info 5.92:1, neutral 15.17:1). Hits `shared/_badge.html.erb`
      (Quote "rejected", Lead "lost", Job/Order "cancelled", Customer "archived") and
      `shared/_form_errors.html.erb`/`_flash.html.erb`'s `alert-error alert-soft` — exactly
      when a user is reading a validation error.
      — fixed (PR #54): darkened `--color-error` to `#B91C1C` (computed: 4.27:1 → 5.66:1 on
      the badge-soft/alert-soft background; white-on-solid-error only improved, 6.47:1).
      CLAUDE.md's Design System palette table still says `#DC2626` — needs a one-line update
      next time it's touched.

#### Consistency
- [ ] Job/Quote/Order indexes don't have the Ransack+Pagy pattern Customer/Lead just got
      (tracked above under Phase 4 → Search/filtering and Pagination).
- [ ] `layouts/mailer.html.erb:18,23` and `pwa/manifest.json.erb:20` still hardcode the
      pre-retint "industrial slate + safety orange" palette (`#1E293B`/`#EA580C`) — neither
      file goes through the Tailwind pipeline, so the navy+blue retint (PR #42) never
      touched them.
- [ ] `documents_controller.rb#create`'s failure path does a flat
      `redirect_to ..., alert: errors.to_sentence` instead of re-rendering
      `documents/_form` through `shared/_form_errors` like every other model — file-upload
      validation errors don't get the field-level, focus-managed treatment everything else
      gets.
- [ ] CLAUDE.md's UX section states "Lead + Customer creation should happen together on one
      form" as current fact — `leads/_form.html.erb` only offers a `customer_id` select of
      existing customers, no inline-create path exists. Either build it or correct the doc.
- [ ] `application_helper.rb:72`'s `nav_link` uses raw `text-white` instead of a semantic
      token — contrast is fine (15.83:1), pure discipline nit against the app's own "no raw
      Tailwind colors in views" rule.
- [ ] Photo-type Documents (JPEG/PNG) never get an inline preview — only PDFs get "View";
      `photo` is a named `document_type` for a real use case (job-site photos).

#### Polish / verify only
- [ ] Firefox lacks CSS anchor positioning, so `shared/_row_actions`' popover falls back to
      centering in the viewport instead of tethering to its trigger button — functionally
      fine (daisyUI's own documented fallback), worth a manual look since it could read as a
      bug to a first-time user.
- [ ] `tax_rate`'s "0.13 for 13%" input format — already tracked above, still open.

#### What's working well (worth preserving, not touching)
Zero raw Tailwind/hex colors in any view file; 44px touch targets enforced globally via one
CSS rule (verified with a real headless-browser pass, per its code comment); `shared/_form_errors`
is close to a textbook accessible error-summary implementation; `shared/_field` wires
`aria-invalid`/`aria-describedby` correctly everywhere; consistent `turbo_submits_with` loading
feedback on every form; specific contextual `turbo_confirm` text on every destructive action
except the one JS miss above; `drawer_controller.js`'s careful transition-timing fallback; the
room/line-item editor rows genuinely stack on mobile, not just shrink; `status_badge`/
`STATUS_VARIANTS` centralizes every model's status→color mapping with zero hand-rolled badges
anywhere; zebra striping as one shared, theme-agnostic CSS rule.

## Housekeeping
- [x] Update CLAUDE.md to reflect schema decisions
- [x] Fix customer fixtures
- [x] Fix seeds.rb
- [x] Remove `.idea/jobdeck.iml` from git tracking
- [x] Fix Order/LineItem test fixtures (were still the blank generator stubs, breaking `db:test:prepare`)
- [x] Guard against orphaning Orders on delete — `dependent: :restrict_with_error` on `Job#orders` and `Lead#orders`
