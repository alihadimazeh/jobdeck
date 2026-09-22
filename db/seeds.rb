# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Users — no role yet (Phase 5's "Role-based views and permissions" sub-phase hasn't landed),
# just enough to sign in locally until real user management exists.
User.find_or_create_by!(email: "admin@jobdeck.test") do |u|
  u.password              = "password123"
  u.password_confirmation = "password123"
end

# Customers
sarah = Customer.find_or_create_by!(email: "sarah.mitchell@gmail.com") do |c|
  c.first_name    = "Sarah"
  c.last_name     = "Mitchell"
  c.phone         = "555-201-4411"
  c.address_line_1 = "14 Maple Grove"
  c.city          = "Ottawa"
  c.province      = "ON"
  c.postal_code   = "K1A 0A1"
end

james = Customer.find_or_create_by!(email: "james.okafor@hotmail.com") do |c|
  c.first_name    = "James"
  c.last_name     = "Okafor"
  c.phone         = "555-302-7823"
  c.address_line_1 = "87 Birchwood Ave"
  c.city          = "Ottawa"
  c.province      = "ON"
  c.postal_code   = "K1B 0B2"
end

linda = Customer.find_or_create_by!(email: "linda.tran@outlook.com") do |c|
  c.first_name    = "Linda"
  c.last_name     = "Tran"
  c.phone         = "555-410-3356"
  c.address_line_1 = "203 Cedar Ridge"
  c.city          = "Ottawa"
  c.province      = "ON"
  c.postal_code   = "K1C 0C3"
end

marcus = Customer.find_or_create_by!(email: "m.delgado@yahoo.com") do |c|
  c.first_name    = "Marcus"
  c.last_name     = "Delgado"
  c.phone         = "555-519-6678"
  c.address_line_1 = "9 Sunflower Ln"
  c.city          = "Ottawa"
  c.province      = "ON"
  c.postal_code   = "K1D 0D4"
end

rachel = Customer.find_or_create_by!(email: "rachel.nguyen@gmail.com") do |c|
  c.first_name    = "Rachel"
  c.last_name     = "Nguyen"
  c.phone         = "555-623-9901"
end

# Leads
lead_sarah = Lead.find_or_create_by!(customer: sarah, title: "Kitchen Renovation Quote") do |l|
  l.description     = "Full kitchen remodel including cabinets, countertops, and tile backsplash."
  l.job_type        = :kitchen
  l.source          = :referral
  l.status          = :converted
  l.estimated_value = 18_500.00
  l.assigned_to     = "Carlos V."
end

lead_james = Lead.find_or_create_by!(customer: james, title: "Master Bath Floor Tiling") do |l|
  l.description     = "Replace existing vinyl with 12x24 porcelain tile in master bathroom."
  l.job_type        = :tile
  l.source          = :walk_in
  l.status          = :quoted
  l.estimated_value = 3_200.00
  l.assigned_to     = "Mia R."
end

lead_linda = Lead.find_or_create_by!(customer: linda, title: "Hardwood Flooring — Living Room") do |l|
  l.description     = "Install 800 sq ft of engineered hardwood throughout living and dining area."
  l.job_type        = :flooring
  l.source          = :referral
  l.status          = :contacted
  l.estimated_value = 9_800.00
  l.assigned_to     = "Carlos V."
end

lead_marcus = Lead.find_or_create_by!(customer: marcus, title: "Materials Supply — Tile Order") do |l|
  l.description     = "Bulk tile material order for contractor client, ~600 sq ft."
  l.job_type        = :materials
  l.source          = :other
  l.status          = :new
  l.estimated_value = 2_100.00
end

lead_rachel = Lead.find_or_create_by!(customer: rachel, title: "Mixed Renovation — Bathroom & Kitchen") do |l|
  l.description     = "Scope TBD — customer walked in requesting estimates for both kitchen and two bathrooms."
  l.job_type        = :mixed
  l.source          = :walk_in
  l.status          = :lost
  l.estimated_value = 22_000.00
  l.assigned_to     = "Mia R."
end

# Jobs (only for converted or active leads)
Job.find_or_create_by!(lead: lead_sarah) do |j|
  j.customer        = sarah
  j.title           = "Kitchen Renovation — Mitchell Residence"
  j.description     = "Full kitchen remodel. Demo starts week of June 2. Tile backsplash, new cabinets, quartz countertops."
  j.job_type        = :kitchen
  j.status          = :active
  j.estimated_value = 18_500.00
  j.assigned_to     = "Carlos V."
  j.start_date      = Date.new(2026, 6, 2)
end

Job.find_or_create_by!(lead: lead_james) do |j|
  j.customer        = james
  j.title           = "Master Bath Tile — Okafor Residence"
  j.description     = "12x24 porcelain tile installation. Materials confirmed, scheduling pending."
  j.job_type        = :tile
  j.status          = :on_hold
  j.estimated_value = 3_200.00
  j.assigned_to     = "Mia R."
end
