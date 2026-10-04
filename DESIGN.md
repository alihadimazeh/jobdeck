---
name: Jobdeck
description: Plainspoken job tracking for a flooring and tile installer, from first call to final invoice.
colors:
  job-blue: "#0369A1"
  job-blue-content: "#FFFFFF"
  slate-steel: "#334155"
  slate-steel-content: "#FFFFFF"
  deep-harbor: "#075985"
  night-navy: "#0F172A"
  rail-mist: "#CBD5E1"
  clipboard-white: "#FFFFFF"
  site-canvas: "#F8FAFC"
  chalk-line: "#E2E8F0"
  ink: "#0F172A"
  status-info: "#1D4ED8"
  status-success: "#15803D"
  status-warning: "#B45309"
  status-error: "#B91C1C"
typography:
  headline:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 600
    lineHeight: "1.75rem"
  figure:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 800
    lineHeight: "2rem"
  title:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 600
    lineHeight: "1.25rem"
  body:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: "1.25rem"
  label:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: "1rem"
    letterSpacing: "0.025em"
  caption:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 400
    lineHeight: "1rem"
rounded:
  tile: "0.25rem"
  field: "0.375rem"
  box: "0.5rem"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  2xl: "32px"
  3xl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.job-blue}"
    textColor: "{colors.job-blue-content}"
    rounded: "{rounded.field}"
    padding: "0 16px"
    height: "44px"
    typography: "{typography.title}"
  button-secondary:
    backgroundColor: "{colors.slate-steel}"
    textColor: "{colors.slate-steel-content}"
    rounded: "{rounded.field}"
    padding: "0 16px"
    height: "44px"
  button-ghost:
    textColor: "{colors.ink}"
    rounded: "{rounded.field}"
    padding: "0 16px"
    height: "44px"
  input:
    backgroundColor: "{colors.clipboard-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.field}"
    padding: "0 12px"
    height: "40px"
    typography: "{typography.body}"
  card:
    backgroundColor: "{colors.clipboard-white}"
    rounded: "{rounded.box}"
    padding: "24px"
  badge-status:
    rounded: "{rounded.field}"
    height: "24px"
    typography: "{typography.body}"
  nav-rail:
    backgroundColor: "{colors.night-navy}"
    textColor: "{colors.rail-mist}"
    width: "224px"
  nav-link-active:
    textColor: "{colors.job-blue-content}"
    rounded: "{rounded.field}"
    padding: "8px 12px"
---

# Design System: Jobdeck

## Overview

**Creative North Star: "The Site Clipboard"**

Jobdeck should feel like the clipboard a good site lead carries: sturdy, plainspoken, and
trusted. Everything is in its place and nothing is decorative, so a project manager can read it
at a glance, whether at the office desk or in a half-finished kitchen with a phone in one hand.
The system is a single daisyUI theme, `jobdeck`, on Tailwind v4. Every color a view uses is a
semantic token, never a raw value, so a future dark theme can drop in without touching views.

The look is a dark navy rail holding white pages on a cool off-white canvas. One blue marks
"the thing to do next." Status is the only other place color appears, through soft tinted badges.
Density is office-software compact (14px body text, 12px labels), but every control keeps a
44px tap height, so the compactness never costs the person on site.

It is deliberately flat. Depth comes from tone (canvas → white surface → navy rail) and 1px
hairline borders. Only things that float above the page cast a shadow.

**Key Characteristics:**
- Navy rail, white pages, off-white canvas: three tones carry the whole structure.
- One blue action color; status colors appear only as soft badges and alerts.
- Inter throughout, self-hosted so the app works offline on site.
- Flat surfaces with 1px hairlines; shadow only on floating layers.
- 44px minimum touch target on every button and menu item, including small ones.
- Small uppercase labels over plain values for anything read like a form or record.

## Colors

A cool slate-and-navy base with one confident blue for action and four dark, AA-safe status
colors.

### Primary
- **Job Blue** (`job-blue`): primary actions and CTAs (New Lead, Save, Accept Quote), the focus
  ring on every control, the active nav item's tint, and the logo tiles. White text on it
  measures 5.93:1.

### Secondary
- **Slate Steel** (`slate-steel`): secondary buttons where a second action needs real weight
  without competing with Job Blue. Currently used only by the estimation tool's "Calculate"
  button on the Quote form.

### Tertiary
- **Deep Harbor** (`deep-harbor`): defined as the theme's `accent`, intended for hover/active on primary. **No view uses it today.** Button hover
  comes from daisyUI darkening the button's own color by 7% black. Treat it as reserved.

### Neutral
- **Night Navy** (`night-navy`): the sidebar rail (`neutral`). Its text is **Rail Mist**
  (`rail-mist`), with inactive links at 70% opacity.
- **Clipboard White** (`clipboard-white`, `base-100`): cards, tables, inputs, menus, the mobile
  top bar.
- **Site Canvas** (`site-canvas`, `base-200`): the app background behind every page, and the
  auth screens.
- **Chalk Line** (`chalk-line`, `base-300`): 1px hairline borders and dividers: card headers,
  table edges, editor row separators, stat groups.
- **Ink** (`ink`, `base-content`): all body text. Muted text is Ink at 70% opacity, never a
  separate gray.

### Status
Each status enum maps to a variant through `ApplicationHelper::STATUS_VARIANTS`:
- **Info Blue** (`status-info`): contacted, sent, completed, confirmed.
- **Field Green** (`status-success`): converted, accepted, active, paid.
- **Caution Amber** (`status-warning`): quoted, expired, on hold, invoiced.
- **Stop Red** (`status-error`): lost, rejected, cancelled, archived; also form errors, the
  required-field asterisk, and destructive menu items. Darkened from `#DC2626` because the
  lighter red failed WCAG AA on soft badges (4.27:1).
- Neutral states (new, draft, inactive) use the plain neutral badge.

### Named Rules
**The Token-Only Rule.** Views use daisyUI semantic classes (`bg-base-200`, `text-primary`,
`badge-success`), never hex values or Tailwind's default scales (`gray-*`, `amber-*`). The
only exceptions are files outside the Tailwind pipeline (the mailer layout and the PWA
manifest), which hardcode the hex values and must be updated by hand.

**The One Blue Rule.** Job Blue means "act here." A screen has one primary button; other
actions are ghost or secondary buttons, or live in the row kebab menu.

**The Status Is Soft Rule.** Status color appears only as a soft-tinted badge or alert (8% tint
background, full-strength text), never as a solid fill or colored row.

## Typography

**Display Font:** none; there is no display tier.
**Body Font:** Inter (variable, 100–900, self-hosted), with `ui-sans-serif, system-ui` fallback.

**Character:** One workhorse sans at small sizes. Hierarchy comes from weight and the uppercase
label style, not from big type. It reads like a well-kept form.

### Hierarchy
- **Headline** (600, 1.25rem / 1.75rem): the single H1 per page in `shared/_page_header`.
- **Figure** (800, 1.5rem / 2rem): stat values on the dashboard and show pages (`shared/_stats`).
- **Title** (600, 0.875rem / 1.25rem): card headings and form section legends. Form legends
  are uppercase with wide tracking.
- **Body** (400, 0.875rem / 1.25rem): table cells, values, notes, buttons.
- **Label** (600, 0.75rem, uppercase, 0.025em tracking, Ink at 70%): detail-list terms, table
  column headers in the room/line-item editors, field captions on record views.
- **Caption** (400, 0.75rem, Ink at 70%): form hints, the "Fields marked * are required" note,
  breadcrumbs, the signed-in email in the rail.

### Named Rules
**The No Shouting Rule.** Nothing is larger than the page headline except a stat figure. Emphasis
comes from weight (600) and placement, not from size.

**The Label-Over-Value Rule.** Read-only records show a small uppercase label above a plain body
value (`shared/_detail_list`). An empty value shows an em dash (—), never a blank.

## Layout

- **App shell:** a 224px navy rail on the left, permanently open from the `lg` breakpoint
  (1024px). Below `lg` it becomes an overlay drawer, opened from a hamburger in a white top bar.
  It is one piece of markup, not two copies. Only `<main>` scrolls; the rail stays pinned full
  height.
- **Page padding:** 16px on phones, 32px from `sm` (640px) up.
- **Page header:** optional breadcrumb, then the H1 with its action buttons right-aligned on the
  same row, and 24px below before content.
- **Forms:** centered in a 672px column (`max-w-2xl`), or 768px (`max-w-3xl`) for the wide
  Quote/Order editors, with fields stacked at 16px gaps.
- **Record views:** detail lists in two columns from `sm`, single column below, with 48px between
  columns and 16px between rows.
- **Editor rows:** the room and line-item editors use a 12-column grid at `sm` and above, and
  stack into labeled single-column cards on phones.
- **Rhythm:** 8, 12 and 16px gaps inside components; 24px around sections.
- **Verified widths:** 375, 768, 1024 and 1440px.

## Elevation & Depth

Flat by default. Depth comes from three tones (Site Canvas → Clipboard White → Night Navy) and
1px Chalk Line borders. daisyUI's `--depth` is 0 and `--noise` is 0, so buttons and inputs have
no bevel, gradient, or inner shadow.

### Shadow Vocabulary
- **Float** (`box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)`,
  Tailwind's `shadow`): flash toasts and the row-actions popover menu. Nothing else.

### Named Rules
**The Only-Floats-Cast-Shadows Rule.** A shadow means "this is above the page and will go away"
(a toast, a popover). Cards, tables, the rail and the top bar never get one; they separate by
tone and hairline.

## Shapes

Gently rounded and consistent. Controls (buttons, inputs, selects, badges) use a 6px radius.
Containers (cards, alerts, menus) use 8px. The only smaller radius is the 4px corner on the
logo's four tiles. Every border is 1px. There are no pills, circles (other than icon dots), or
cut corners.

The logo is a 2×2 grid of small tiles: two full-strength Job Blue, two at 50%, set on the
diagonal. It is the system's one bit of trade identity.

## Components

### Buttons
Sturdy and plain: large enough for a gloved thumb, with no ornament.
- **Shape:** gently rounded (6px), 1px border in the button's own color.
- **Size:** 44px minimum height on every size, including `btn-sm`. Small buttons keep their
  smaller padding and type, not a smaller tap target.
- **Primary:** Job Blue with white text, 16px horizontal padding, 14px semibold. Built through
  the `btn` helper.
- **Hover:** the button's own color darkened by 7% black (daisyUI default), on hover-capable
  devices only.
- **Focus:** 2px Job Blue outline at a 2px offset on every focusable control.
- **Ghost:** no fill or border until hovered. Used for secondary page actions, empty-state CTAs,
  icon buttons, and the rail's Sign out.
- **Secondary:** Slate Steel with white text, for a heavy second action (rare).
- **Icon-only:** square ghost buttons with a 16–20px stroke icon and an `aria-label`.

### Status badges
- **Style:** soft variant: 8% tint of the status color over white, full-strength status color
  text, a 10% tint border, 6px radius, never wrapping.
- **Mapping:** one central status → variant map; views call `status_badge(record)`, never pick
  a color themselves.

### Cards / Containers
- **Corner style:** 8px.
- **Background:** Clipboard White on Site Canvas.
- **Shadow strategy:** none (see Elevation).
- **Border:** 1px Chalk Line. A titled card has a header strip (24px × 16px padding, 14px
  semibold title, optional actions on the right) above a 1px divider.
- **Internal padding:** 24px, or unpadded when the card wraps a full-bleed table.

### Tables
- One shared partial for every table. Rows are zebra-striped: every even row is a 6% mix of
  Ink into white, deliberately not the canvas color, so stripes read as part of the table.
- Each row's actions sit in a centered kebab (⋮) button that opens a popover menu (Edit, then
  Delete in Stop Red). Totals go in a real `<tfoot>`.

### Inputs / Fields
- **Style:** white field, 1px border of Ink at 20%, 6px radius, 40px tall, 12px horizontal
  padding, 14px text.
- **Focus:** 2px Job Blue outline at a 2px offset.
- **Required:** a Stop Red asterisk after the label (hidden from screen readers) plus
  `aria-required`. Never the native `required` attribute, which would block the server's error
  summary.
- **Error:** a 12px Stop Red message under the field, linked by `aria-describedby`, and a
  focused, linked error summary at the top of the form.
- **Hint:** a 12px caption under the field in Ink at 70%.
- **Labels:** every control has an accessible name. Placeholders never stand in for a label.

### Navigation
- **Rail:** Night Navy, 224px wide: the logo and wordmark at the top, four links (Dashboard,
  Customers, Leads, Jobs), and the signed-in email plus Sign out at the bottom above a faint
  divider.
- **Links:** 14px medium, 8px × 12px padding, 6px radius. Inactive links are Rail Mist at 70%;
  hover brightens the text and adds a 5% light wash. The active link gets a 15% Job Blue wash,
  full-white text, and `aria-current="page"`. A nested page (a Quote, an Order) lights up its
  parent section.
- **Mobile:** a white top bar with a hamburger and the wordmark; the rail slides in as an
  overlay with focus management and Escape to close.

### Flash toasts
Top-right, soft success or error alert with a dismiss button. Errors carry `role="alert"`; the
container is `aria-live="polite"`. Toasts are one of only two things that cast a shadow.

### Empty states
Centered, 40px of vertical padding: a medium-weight line saying what's missing, an optional
muted sentence, and an optional ghost-button CTA. Inside a table, it fills a full-width row.

### Estimation editor (signature)
The Quote form's room calculator. Each room is a row (name, length, width, live area in sq ft,
notes, remove) on a 12-column grid with uppercase column labels. It collapses on phones to
stacked, labeled fields separated by hairlines. Adding a row moves focus into it; removing one
moves focus to a neighbor. Line items below follow the same row pattern.

## Do's and Don'ts

### Do:
- **Do** use semantic daisyUI classes for every color (`bg-base-100`, `text-base-content/70`,
  `badge-warning`).
- **Do** keep one Job Blue primary button per screen; put other actions in ghost buttons or the
  row kebab menu.
- **Do** render status through `status_badge`, so every status has one color everywhere.
- **Do** keep every interactive element at a 44px minimum height.
- **Do** separate surfaces with tone and 1px Chalk Line borders.
- **Do** use the shared partials (`_page_header`, `_card`, `_table`, `_field`, `_detail_list`,
  `_empty_state`, `_row_actions`) instead of hand-rolling their markup.
- **Do** show an em dash (—) for empty values and money as formatted currency.
- **Do** check layouts at 375px; the on-site phone is a primary device.

### Don't:
- **Don't** use raw hex or Tailwind default color scales in a view. Seeing `amber-*` or the old
  orange `#EA580C` means a regression.
- **Don't** add shadows to cards, tables, the rail, or the top bar; shadows are for toasts and
  popovers only.
- **Don't** use status colors for anything but status, errors, and destructive actions.
- **Don't** add web fonts or any external font request; Inter is self-hosted for offline use.
- **Don't** use the native `required` attribute on form fields.
- **Don't** size type above the page headline (1.25rem) except stat figures.
- **Don't** use placeholders as labels.
