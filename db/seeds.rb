# Demo data: a small flooring/tile business mid-season, so every screen has something real to
# show. Dates are relative to the day you seed, so the dashboard always has follow-ups due today
# and overdue, jobs on schedule and running over, and invoices both overdue and not yet due.
#
#   bin/rails db:seed           # first run on an empty database
#   bin/rails db:seed:replant   # wipe the data and reseed, e.g. before a demo so dates are fresh
#
# Users are idempotent (safe to re-run). Business data is only created when there are no
# customers yet, so re-running never duplicates it; replant to refresh it.

# --- Users: one per role, to show what each role can and can't do -----------------------------

# Not "password123": that's on breached-password lists, and Chrome interrupts sign-in with a
# "change your password" warning for it. Production must set its own, never this published one.
demo_password = ENV.fetch("SEED_PASSWORD") do
  raise "Set SEED_PASSWORD to seed users in production" if Rails.env.production?
  "jobdeck-demo"
end

{
  "admin@jobdeck.test"  => :admin,
  "pm@jobdeck.test"     => :project_manager,
  "sales@jobdeck.test"  => :sales,
  "viewer@jobdeck.test" => :viewer
}.each do |email, role|
  User.find_or_create_by!(email: email) do |u|
    u.password = u.password_confirmation = demo_password
    u.role     = role
  end
end

if Customer.exists?
  puts "Customers already exist; skipping demo business data. Run bin/rails db:seed:replant to reseed."
  return
end

today = Date.current

# --- Helpers ------------------------------------------------------------------------------------

# A quote built the way the estimation tool builds one: rooms in, sq ft summed, then a material
# line (with 10% waste) and a labor line priced off that area, plus any extras.
def build_quote(lead, status:, issued:, rooms:, material:, labor_rate:, extras: [], notes: nil)
  area = rooms.sum { |(_, length, width)| length * width }
  material_name, material_rate = material

  Quote.create!(
    lead: lead,
    status: status,
    tax_rate: 0.13,
    issued_date: issued,
    valid_until: issued + 30,
    notes: notes,
    rooms_attributes: rooms.map { |(name, length, width)| { name: name, length: length, width: width } },
    quote_line_items_attributes: [
      { item_type: :material, description: material_name, quantity: (area * 1.1).ceil, unit: "sq ft", unit_price: material_rate },
      { item_type: :labor, description: "Installation labor", quantity: area.ceil, unit: "sq ft", unit_price: labor_rate },
      *extras
    ]
  )
end

# Accepting a quote runs the real conversion (Lead#convert_to_job!): it creates the Job and its
# first Order from the quote's line items. Then set where the job and its order stand today.
def accept_and_schedule(quote, job:, order:)
  quote.update!(status: :accepted)
  converted_job = quote.lead.reload.job
  converted_job.update!(job)
  converted_job.orders.first.update!({ tax_rate: 0.13 }.merge(order))
  converted_job
end

def note(record, body, author:, days_ago:, pinned: false)
  at = days_ago.days.ago
  record.activity_notes.create!(body: body, author: author, pinned: pinned, created_at: at, updated_at: at)
end

# A small one-page PDF with a title line, so Documents have real files to view and download.
def demo_pdf(title)
  text = title.gsub(/[()\\]/) { "\\#{_1}" }
  stream = "BT /F1 18 Tf 72 720 Td (#{text}) Tj ET"
  objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
    "<< /Length #{stream.bytesize} >>\nstream\n#{stream}\nendstream",
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
  ]
  pdf = +"%PDF-1.4\n"
  offsets = objects.each_with_index.map do |body, i|
    offset = pdf.bytesize
    pdf << "#{i + 1} 0 obj\n#{body}\nendobj\n"
    offset
  end
  xref = pdf.bytesize
  pdf << "xref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
  offsets.each { |o| pdf << format("%010d 00000 n \n", o) }
  pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref}\n%%EOF\n"
end

def attach_pdf(record, label:, type:, uploaded_by:, filename:)
  record.documents.create!(
    label: label, document_type: type, uploaded_by: uploaded_by,
    file: { io: StringIO.new(demo_pdf(label)), filename: filename, content_type: "application/pdf" }
  )
end

# --- Customers ----------------------------------------------------------------------------------

customer = ->(first, last, email, phone, street, postal, **extra) do
  Customer.create!(
    first_name: first, last_name: last, email: email, phone: phone,
    address_line_1: street, city: "Ottawa", province: "ON", postal_code: postal, **extra
  )
end

sarah  = customer.("Sarah",  "Mitchell", "sarah.mitchell@example.com", "613-555-4411", "14 Maple Grove",    "K1S 2A4")
james  = customer.("James",  "Okafor",   "james.okafor@example.com",   "613-555-7823", "87 Birchwood Ave",  "K2B 6R1")
linda  = customer.("Linda",  "Tran",     "linda.tran@example.com",     "613-555-3390", "202 Elgin St",      "K2P 1L7")
priya  = customer.("Priya",  "Patel",    "priya.patel@example.com",    "613-555-6158", "9 Ridgefield Cres", "K2G 4V9")
marcus = customer.("Marcus", "Delgado",  "m.delgado@example.com",      "613-555-2207", "1550 Carling Ave",  "K1Z 7M4",
                   notes: "Contractor client - buys tile for his own crews.")
tom    = customer.("Tom",    "Kowalski", "tom.kowalski@example.com",   "613-555-8842", "31 Pinecrest Rd",   "K2B 5Y2")
aisha  = customer.("Aisha",  "Bello",    "aisha.bello@example.com",    "613-555-1976", "68 Fairmont Ave",   "K1Y 1X5")
hannah = customer.("Hannah", "Lee",      nil,                          "613-555-5034", "412 Bank St",       "K2P 1Y4")
rachel = customer.("Rachel", "Nguyen",   "rachel.nguyen@example.com",  "613-555-9901", "7 Kingsmere Pl",    "K2K 2T8")
customer.("Greg", "Fournier", "greg.fournier@example.com", "613-555-4470", "25 Riverside Dr", "K1H 7X3",
          status: :inactive, notes: "Moved out of the service area.")

# --- Leads that became jobs ---------------------------------------------------------------------

# Mitchell kitchen: well under way, with its first invoice now overdue and a change order drafted.
lead = Lead.create!(customer: sarah, title: "Kitchen floor and backsplash", job_type: :kitchen, source: :referral,
                    status: :contacted, estimated_value: 6_000, assigned_to: "Carlos V.",
                    description: "Porcelain plank floor through the kitchen and eating area, subway tile backsplash.")
quote = build_quote(lead, status: :sent, issued: today - 40,
                    rooms: [ [ "Kitchen", 16, 12 ], [ "Eating area", 10, 9 ] ],
                    material: [ "Porcelain wood-look plank, 8x48", 6.75 ], labor_rate: 7.50,
                    extras: [ { item_type: :material, description: "White subway tile backsplash, 3x6", quantity: 42, unit: "sq ft", unit_price: 9.50 },
                              { item_type: :labor, description: "Backsplash install", quantity: 42, unit: "sq ft", unit_price: 16.00 } ])
job = accept_and_schedule(quote,
                          job: { status: :active, start_date: today - 12, end_date: today + 9, assigned_to: "Carlos V." },
                          order: { status: :invoiced, issued_date: today - 12, due_date: today - 5, notes: "Deposit and materials." })
job.orders.create!(status: :draft, tax_rate: 0.13, due_date: today + 14, notes: "Customer asked for a tiled niche behind the range.",
                   line_items_attributes: [ { item_type: :labor, description: "Tiled niche, framing and waterproofing", quantity: 1, unit: "each", unit_price: 450 },
                                            { item_type: :material, description: "Schluter edge trim", quantity: 4, unit: "piece", unit_price: 38 } ])
note(lead, "Referred by the Hendersons. Wants it done before the holidays.", author: "Mia R.", days_ago: 45)
note(job, "Cabinets go in Thursday. Backsplash after the counters are templated.", author: "Carlos V.", days_ago: 3, pinned: true)
note(job, "Called about the overdue deposit invoice. Says the cheque is in the mail.", author: "Mia R.", days_ago: 1)
attach_pdf(job, label: "Signed contract - Mitchell kitchen", type: :contract, uploaded_by: "Mia R.", filename: "mitchell-contract.pdf")

# Okafor bath: should have finished two days ago (subfloor surprise), invoice not due yet.
lead = Lead.create!(customer: james, title: "Master bath floor tile", job_type: :tile, source: :walk_in,
                    status: :contacted, estimated_value: 2_500, assigned_to: "Dev P.",
                    description: "Replace vinyl with 12x24 porcelain, heated floor mat.")
quote = build_quote(lead, status: :sent, issued: today - 30,
                    rooms: [ [ "Master bath", 11, 8 ], [ "Water closet", 5, 4 ] ],
                    material: [ "Porcelain tile, 12x24 matte grey", 5.25 ], labor_rate: 9.00,
                    extras: [ { item_type: :material, description: "Electric heated floor mat kit", quantity: 1, unit: "kit", unit_price: 640 } ])
job = accept_and_schedule(quote,
                          job: { status: :active, start_date: today - 9, end_date: today - 2, assigned_to: "Dev P." },
                          order: { status: :invoiced, issued_date: today - 9, due_date: today + 6 })
note(job, "Found soft subfloor under the toilet. Replacing a 4x4 section, adds two days.", author: "Dev P.", days_ago: 4, pinned: true)

# Tran hardwood: finished last month and paid. A happy past customer.
lead = Lead.create!(customer: linda, title: "Engineered hardwood, living and dining", job_type: :flooring, source: :website,
                    status: :contacted, estimated_value: 8_200, assigned_to: "Carlos V.")
quote = build_quote(lead, status: :sent, issued: today - 70,
                    rooms: [ [ "Living room", 20, 16 ], [ "Dining room", 14, 12 ], [ "Hallway", 18, 4 ] ],
                    material: [ "Engineered white oak, 7in wide plank", 7.90 ], labor_rate: 4.25)
accept_and_schedule(quote,
                    job: { status: :completed, start_date: today - 45, end_date: today - 38, assigned_to: "Carlos V." },
                    order: { status: :paid, issued_date: today - 38, due_date: today - 23 })

# Patel basement: starts next week, order agreed but not billed yet.
lead = Lead.create!(customer: priya, title: "Basement luxury vinyl plank", job_type: :flooring, source: :phone,
                    status: :contacted, estimated_value: 5_100, assigned_to: "Dev P.")
quote = build_quote(lead, status: :sent, issued: today - 14,
                    rooms: [ [ "Rec room", 24, 18 ], [ "Office", 12, 10 ] ],
                    material: [ "Waterproof LVP, 7x48 rigid core", 4.10 ], labor_rate: 2.75,
                    extras: [ { item_type: :material, description: "Underlayment with vapour barrier", quantity: 6, unit: "roll", unit_price: 85 } ])
accept_and_schedule(quote,
                    job: { status: :active, start_date: today + 4, end_date: today + 7, assigned_to: "Dev P." },
                    order: { status: :confirmed, due_date: today + 21 })
attach_pdf(lead, label: "Basement floor plan", type: :plan, uploaded_by: "Dev P.", filename: "patel-basement-plan.pdf")

# Delgado materials order: the client cancelled after ordering, so the job and order are cancelled.
lead = Lead.create!(customer: marcus, title: "Tile supply for a condo reno", job_type: :materials, source: :other,
                    status: :contacted, estimated_value: 2_700)
quote = build_quote(lead, status: :sent, issued: today - 25,
                    rooms: [ [ "Unit 4B, floors", 30, 20 ] ],
                    material: [ "Porcelain tile, 24x24 beige", 3.60 ], labor_rate: 0)
job = accept_and_schedule(quote,
                          job: { status: :cancelled, assigned_to: "Mia R." },
                          order: { status: :cancelled })
note(job, "Client's condo board pulled the permit. Cancelled before delivery, no restocking fee.", author: "Mia R.", days_ago: 6)

# Repeat customer, no lead or quote: James called back about his front entry.
job = Job.create!(customer: james, title: "Front entry tile repair", job_type: :tile, status: :on_hold,
                  assigned_to: "Dev P.", estimated_value: 650, address_line_1: james.address_line_1,
                  city: "Ottawa", province: "ON", postal_code: james.postal_code,
                  description: "Three cracked tiles by the door. Waiting on a matching dye lot.")
job.orders.create!(status: :draft, tax_rate: 0.13,
                   line_items_attributes: [ { item_type: :labor, description: "Remove and replace cracked tiles", quantity: 3, unit: "each", unit_price: 95 },
                                            { item_type: :material, description: "Matching tile, special order", quantity: 1, unit: "box", unit_price: 120 } ])

# --- Leads still in the pipeline ----------------------------------------------------------------

# Kowalski: a revised quote is out after the first one expired. Follow up today.
lead = Lead.create!(customer: tom, title: "Main bath tile, floor and shower walls", job_type: :tile, source: :referral,
                    status: :quoted, estimated_value: 4_500, assigned_to: "Mia R.", follow_up_date: today,
                    description: "Gut the main bath. Floor tile and full-height shower surround.")
build_quote(lead, status: :expired, issued: today - 50,
            rooms: [ [ "Bathroom floor", 9, 7 ], [ "Shower walls", 15, 8 ] ],
            material: [ "Ceramic tile, 12x12", 4.20 ], labor_rate: 11.00,
            notes: "First pass, before the customer picked a tile.")
build_quote(lead, status: :sent, issued: today - 6,
            rooms: [ [ "Bathroom floor", 9, 7 ], [ "Shower walls", 15, 8 ] ],
            material: [ "Marble-look porcelain, 12x24", 7.40 ], labor_rate: 11.00,
            extras: [ { item_type: :material, description: "Shower waterproofing membrane kit", quantity: 1, unit: "kit", unit_price: 380 } ],
            notes: "Revised with the porcelain the customer chose in the showroom.")
note(lead, "Liked the marble-look porcelain. Comparing us with one other quote.", author: "Mia R.", days_ago: 5)

# Bello: measured last week, quote still a draft. Follow up today.
lead = Lead.create!(customer: aisha, title: "Kitchen backsplash", job_type: :kitchen, source: :website,
                    status: :contacted, estimated_value: 1_500, assigned_to: "Carlos V.", follow_up_date: today)
build_quote(lead, status: :draft, issued: today,
            rooms: [ [ "Backsplash, sink wall", 12, 1.5 ], [ "Backsplash, range wall", 8, 2.5 ] ],
            material: [ "Zellige-style ceramic, 4x4", 18.00 ], labor_rate: 16.00)
note(lead, "Measured on site. Wants a handmade look; showed her zellige samples.", author: "Carlos V.", days_ago: 7)

# Lee: came in through the website, nobody has called back. Overdue.
Lead.create!(customer: hannah, title: "Hallway and stairs, hardwood refinish", job_type: :flooring, source: :website,
             status: :new, estimated_value: 2_600, follow_up_date: today - 3,
             description: "Web form: wants the oak stairs and upstairs hall refinished, darker stain.")

# Okafor again: a second project, follow-up booked for next week (not on today's dashboard).
Lead.create!(customer: james, title: "Laundry room tile", job_type: :tile, source: :phone,
             status: :new, estimated_value: 1_400, assigned_to: "Dev P.", follow_up_date: today + 5)

# Delgado again: a big one, overdue for a call back.
lead = Lead.create!(customer: marcus, title: "Tile supply, 12-unit townhouse build", job_type: :materials, source: :phone,
                    status: :contacted, estimated_value: 24_000, assigned_to: "Mia R.", follow_up_date: today - 8)
note(lead, "Needs pricing on 12 units by end of month. Waiting on his drawings.", author: "Mia R.", days_ago: 10)

# Nguyen: lost on price.
lead = Lead.create!(customer: rachel, title: "Bathroom and kitchen floors", job_type: :mixed, source: :walk_in,
                    status: :lost, estimated_value: 4_300, assigned_to: "Mia R.")
build_quote(lead, status: :rejected, issued: today - 35,
            rooms: [ [ "Kitchen", 14, 12 ], [ "Main bath", 8, 6 ], [ "Ensuite", 7, 6 ] ],
            material: [ "Porcelain tile, 12x24", 5.25 ], labor_rate: 9.00)
note(lead, "Went with a cheaper installer. Asked us to keep her on file for the basement next year.", author: "Mia R.", days_ago: 20)

puts "Seeded #{Customer.count} customers, #{Lead.count} leads, #{Quote.count} quotes, " \
     "#{Job.count} jobs, #{Order.count} orders."
# Never echo a production password into deploy logs.
puts "Sign in as admin@jobdeck.test / #{demo_password}" unless Rails.env.production?
