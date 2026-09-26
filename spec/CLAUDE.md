# Testing notes (loads when working under `spec/`)

**Policy: all new test files go in `spec/` (RSpec), never `test/` (Minitest), unless explicitly
stated otherwise.** `test/` is the old Minitest suite (mostly scaffold stubs plus generated
controller CRUD tests). It still runs (`bin/rails test`) and is kept passing, but new coverage
never goes there.

- `FactoryBot::Syntax::Methods` is included globally, so specs call `create`/`build` directly.
- `spec/support/concerns/billable_line_item.rb` is one shared example group ("a billable line
  item") run against both `LineItem` and `QuoteLineItem`, so the `BillableLineItem` concern's
  contract is tested once, not duplicated.
- Enum specs on `Lead`/`Job`/`Quote`/`Order` pin the integer values on purpose: they guard
  against another integer-backed enum reorder like the old `Lead.source` one, which silently
  changes the meaning of existing rows.
- Exercising `Document`'s "rejected content type" path needs a file whose *bytes* are a
  non-accepted type. Active Storage re-sniffs content with Marcel and ignores the declared
  `content_type:`, so a real PDF fixture labelled as something else still passes (see
  `document_spec.rb`).

## Authentication in specs

Every controller requires a signed-in user.

- **Request specs:** `spec/support/authentication.rb` signs in a throwaway `create(:user)` via a
  global `before(:each, type: :request)` hook. Opt out with `skip_authentication: true` metadata
  (used by `sessions_spec.rb`/`passwords_spec.rb`, which test the unauthenticated paths).
- **System specs:** `spec/support/system_authentication.rb` defines `sign_in_as(user)`, which
  drives the real sign-in form (a raw POST can't put a cookie into the browser session). Two
  constraints, both found the hard way:
  - The call lives **inside `spec/rails_helper.rb`'s `before(:each, type: :system)` hook, right
    after `driven_by`**, not in a separate hook. Support files are required before that hook is
    registered, so any support-file hook (even `append_before`) runs *first*, and `driven_by`
    then resets the session and drops the cookie.
  - After `click_button "Sign in"` the helper waits on `have_current_path(root_path)`. The form
    submits via Turbo (a fetch, not a navigation), so `click_button` returns before the redirect
    finishes; without the wait the next `visit` can race the cookie.
- **Minitest:** a `test/fixtures/users.yml` fixture plus an `ActionDispatch::IntegrationTest`
  `setup` block in `test/test_helper.rb`.

## Running system specs locally

This machine has no `google-chrome`/`chromium` on `PATH`, so plain `bundle exec rspec` fails every
system spec with "cannot find Chrome binary". That's an environment gap, not a code bug (CI has
Chrome). Point Selenium at a Chromium-based binary via the `SE_CHROME_BINARY` hook in
`rails_helper.rb`, **and pin a ChromeDriver of the same major version** via `SE_CHROMEDRIVER`
(read by selenium-webdriver itself).

Pinning is required: Selenium Manager downloads the driver for the *latest* stable Chrome, not
for the binary you point it at, so once Chrome stable moves ahead of Brave's Chromium the session
fails with "This version of ChromeDriver only supports Chrome version N" (happened 2026-09-24:
driver 154, Brave on 153). Working combination:

```
SE_CHROME_BINARY=/usr/bin/brave-browser \
SE_CHROMEDRIVER=~/.cache/selenium/chromedriver/linux64/153.0.8010.52/chromedriver \
bundle exec rspec
```

Check `brave-browser --version` and `ls ~/.cache/selenium/chromedriver/linux64/` after a Brave
update. A Chrome for Testing binary from `~/.cache/selenium/chrome/linux64/<ver>/chrome` with its
same-version driver also works. Run long suites under `timeout`: with a mismatched driver one run
kept going for over two hours without ever reaching the app.

## Pagination-order flake (fixed, PR #56)

The "paginates when there are more records than one page" specs used to fail under some `--seed`
values: Postgres plans a bare `SELECT DISTINCT` as a `HashAggregate`, whose output order depends
on hash buckets, not ids. Every index now appends `.order(:id)`. Any new paginated
`distinct: true` query needs an explicit order too.
