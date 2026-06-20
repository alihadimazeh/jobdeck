# Project: Construction PM App

A simple project management web app for a small construction business (flooring/tile installer). General project managers use this to track customers, sales leads, active jobs, and billing.

## Tech Stack

- **Ruby on Rails 8**
- **PostgreSQL**
- **Tailwind CSS** (via `tailwindcss-rails`) — chosen intentionally over Bulma for learning purposes
- **Active Storage** for file uploads (PDFs, Excel sheets, images)
- **Pagy** for pagination
- **Ransack** for search/filtering
- Turbo + Stimulus (Rails defaults, no separate frontend framework)

## Domain Overview

The business workflow is:

```
Customer → Lead → Job → Order(s) → LineItems
```

A **Customer** walks in or calls. A **Lead** is logged for them describing what they're interested in. If the lead materializes, it converts into a **Job** (the actual work being done). A Job can have one or more **Orders** (e.g. a materials order, a labor order), and each Order is made up of **LineItems** (the billing breakdown).

At any point, **Notes** and **Documents** (PDFs, Excel sheets, photos) can be attached to a Lead, Job, or Order via polymorphic associations.

### Naming note
"Job" is used instead of "Project" — it matches how contractors actually talk ("I've got 3 jobs this week"). "Order" is kept as-is rather than renamed to "Invoice."

## Models

### Customer
The root entity. Every Lead, Job, and Order belongs to a Customer — this reference is **never nullable**.

```ruby
# customers table
first_name        string, null: false
last_name         string, null: false
email             string
phone             string
address_line1     string
address_line2     string
city              string
state             string
zip               string
status            string, null: false, default: "active"
notes             text
```

Relationships:
```ruby
has_many :leads
has_many :jobs
has_many :orders
```

---

### Lead
Represents a sales inquiry — interest that hasn't been committed to yet. Tracks pipeline status and converts into a Job when it materializes (the Lead is NOT deleted on conversion — it remains historical record of how the Job originated).

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
has_one    :job
has_many   :notes,     as: :notable
has_many   :documents, as: :documentable
```

Key behavior: `convert_to_job!` — creates a Job from this Lead's data, links `lead_id` on the new Job, and flips this Lead's status to `"converted"`.

---

### Job
The actual work being performed (formerly "Project"). Belongs to a Customer. `lead_id` is **nullable** — some jobs are created directly without ever being tracked as a lead (e.g. repeat customers).

```ruby
# jobs table
customer_id       references, null: false, foreign_key: true
lead_id           references, null: true,  foreign_key: true
title             string, null: false
status            string, null: false, default: "active"
                  # active | on_hold | completed | cancelled
job_type          string
                  # tile | flooring | materials | mixed
start_date        date
end_date          date
description       text
address_line1     string
city              string
state             string
zip               string
```

Relationships:
```ruby
belongs_to :customer
belongs_to :lead, optional: true
has_many   :orders
has_many   :notes,     as: :notable
has_many   :documents, as: :documentable
```

Note: job-site address fields are separate from the customer's address since the work location may differ from the customer's home/billing address.

---

### Order
The financial/transactional side of a Job (invoice / work order). Always tied to a Job (**not nullable**) and a Customer (**not nullable**, for billing). `lead_id` is nullable and kept purely for reporting/traceability convenience.

```ruby
# orders table
job_id            references, null: false, foreign_key: true
customer_id       references, null: false, foreign_key: true
lead_id           references, null: true,  foreign_key: true
status            string, null: false, default: "draft"
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
has_many   :line_items
has_many   :notes,     as: :notable
has_many   :documents, as: :documentable
```

Key behavior:
- `order_number` auto-generated on create (format: `ORD-<year>-<sequential>`)
- `subtotal`/`total` calculated from sum of `line_items` before save
- Order status is independent from Job status (a Job can be "completed" while its Order is still "invoiced")

---

### LineItem
Individual billable rows on an Order (materials, labor, other charges). Managed via nested attributes on the Order form (add/remove rows dynamically).

```ruby
# line_items table
order_id          references, null: false, foreign_key: true
item_type         string, null: false
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

### Note (polymorphic)
Free-text notes attachable to a Lead, Job, or Order. One model/controller/view reused across all three via `notable_type` / `notable_id`.

```ruby
# notes table
notable_type      string, null: false   # "Lead" | "Job" | "Order"
notable_id        integer, null: false
body              text, null: false
author            string
pinned            boolean, null: false, default: false
```

Relationships:
```ruby
belongs_to :notable, polymorphic: true
```

---

### Document (polymorphic + Active Storage)
File uploads (PDFs, Excel sheets, images) attachable to a Lead, Job, or Order. Same polymorphic pattern as Note.

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
```

Validations: restrict accepted content types to PDF, XLS/XLSX, JPEG, PNG. Max file size 50MB.

---

## Migration Order

Migrations must run in this order due to foreign key dependencies:

1. `create_customers` — no dependencies
2. `create_leads` — depends on customers
3. `create_jobs` — depends on customers, leads
4. `create_orders` — depends on customers, leads, jobs
5. `create_line_items` — depends on orders
6. `create_notes` — polymorphic, no FK constraints
7. `create_documents` — polymorphic, no FK constraints
8. `rails active_storage:install` — generates Active Storage tables separately

## Foreign Key Nullability Rules

| Reference | Nullable? | Reasoning |
|---|---|---|
| `customer_id` (Lead, Job, Order) | No | Everything traces back to a customer |
| `lead_id` (Job, Order) | Yes | Jobs/Orders can be created without a tracked Lead |
| `job_id` (Order) | No | An Order always needs Job context |

## UX / Workflow Notes

- **Lead + Customer creation should happen together** on one form (inline customer fields + lead fields), since requiring a separate customer-creation step first adds friction during a quick walk-in or phone inquiry. Allow searching for an existing customer to avoid duplicates.
- **Lead → Job conversion** is a single action (e.g. a "Convert to Job" button on the Lead show page) that creates the Job and updates the Lead's status, without deleting the Lead.
- **Notes and Documents** should use shared partials/components since the UI is identical across Lead, Job, and Order — only the polymorphic association target changes.
- Dashboard should surface: leads needing follow-up, active jobs, and unpaid/outstanding orders.

## Status Enums Reference

```ruby
Lead.status:  new | contacted | quoted | converted | lost
Job.status:   active | on_hold | completed | cancelled
Order.status: draft | confirmed | invoiced | paid | cancelled
```

## Job Types / Source Reference

```ruby
job_type: tile | flooring | materials | mixed
source:   walk_in | phone | referral | website | other
```
