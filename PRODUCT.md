# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Project managers and office staff at a small flooring/tile installation business. They log walk-in
and phone inquiries as leads, follow them up, measure rooms and build quotes, run active jobs, and
bill through orders. Work is split between the office (quoting, billing, follow-ups at a desk) and
the job site (adding notes, uploading photos and documents, checking job details on a phone or
tablet).

Planned roles (not built yet): admin, project manager, sales, and a read-only viewer such as an
owner who only wants the dashboard.

## Product Purpose

Jobdeck tracks the whole life of a piece of work for a small construction business: Customer →
Lead → Quote (with room measurements) → Job → Order(s) → Line items, with an activity log and
documents on each stage.

**Current priority: portfolio first.** No live business depends on it yet. It is built to be shown
to reviewers and hiring managers as a realistic, well-made product. The longer-term intent is a
multi-user product other construction businesses could run (roles, SSO). When the two pull apart,
the bar is "would a real contractor trust and use this," shown with production-grade quality.

## Positioning

Most project-management tools are built for software teams. Jobdeck is built around how a
contractor actually talks about and runs work:

- leads that need following up;
- quotes built from real room-by-room measurements;
- jobs with a site address separate from the customer's billing address;
- orders that can lag behind a finished job because payment doesn't match the work schedule.

## Operating Context

- **Office:** estimating with the room calculator (dimensions → sq footage → labor and material
  line items), revising quotes, accepting a quote to convert it into a job, tracking unpaid orders.
- **Job site:** phone or tablet use for activity notes, job-site photos, and PDFs/spreadsheets,
  and for checking job details. Self-hosted fonts were chosen so it works offline on site.
- **Dashboard:** leads needing follow-up, active jobs, and outstanding orders.

## Capabilities and Constraints

- Terminology is deliberate: **Job**, not "Project"; **Order**, not "Invoice"; **ActivityNote**
  (the timeline log) is separate from the free-text `notes` field on Quote/Order.
- Quotes belong to the Lead (before commitment); Orders belong to the Job (after commitment). A
  Lead can have several quotes but only one accepted.
- Customers with job or billing history are archived, never deleted. Financial records are never
  silently destroyed.
- Rails 8 server-rendered app (Turbo/Stimulus), no Node/npm.
- Authentication is built; roles/permissions and SSO are planned (see CLAUDE.md).
- **Undecided:** combined Lead + Customer creation on one form; top-level Quotes/Orders pages;
  what the Customer "Lifetime Value"/"Outstanding" figures should count; `tax_rate` entry format.

## Brand Commitments

- Name: **Jobdeck**.
- Voice: plain trade talk. Contractor terms (job, quote, order, site), short and direct, no
  software jargon.

## Evidence on Hand

- Seed data in `db/seeds.rb` (demo records, one dev user). No real customers, testimonials, usage
  data, or business case studies exist. Do not invent any.

## Product Principles

1. **Speak the trade.** Name things the way a contractor would say them out loud.
2. **Works at the desk and on site.** Every flow that matters on site (notes, photos, job lookup)
   must be usable on a phone; estimating and billing can assume a larger screen but must not break
   on one.
3. **Money and work history are never lost.** Deletes that would erase billing or completed work
   are blocked or turned into archives.
4. **Portfolio-grade, not demo-grade.** Real validation, real error handling, accessible forms;
   nothing that only looks finished.

## Accessibility & Inclusion

WCAG 2.x AA is the working standard: contrast checked for every theme color, keyboard and
screen-reader support (skip link, labeled controls, linked error summaries, `aria-required`
instead of native `required`), and layouts verified from 375px phone width up.
