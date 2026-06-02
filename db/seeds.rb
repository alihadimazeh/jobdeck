# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Customers
customers = [
  { name: "Sarah Mitchell",  email: "sarah.mitchell@gmail.com",  phone: "555-201-4411", address: "14 Maple Grove, Austin TX 78701" },
  { name: "James Okafor",    email: "james.okafor@hotmail.com",  phone: "555-302-7823", address: "87 Birchwood Ave, Austin TX 78702" },
  { name: "Linda Tran",      email: "linda.tran@outlook.com",    phone: "555-410-3356", address: "203 Cedar Ridge, Austin TX 78703" },
  { name: "Marcus Delgado",  email: "m.delgado@yahoo.com",       phone: "555-519-6678", address: "9 Sunflower Ln, Austin TX 78704"  },
  { name: "Rachel Nguyen",   email: "rachel.nguyen@gmail.com",   phone: "555-623-9901", address: nil                                },
].map { |attrs| Customer.find_or_create_by!(email: attrs[:email]) { |c| c.assign_attributes(attrs) } }

sarah, james, linda, marcus, rachel = customers

# Leads
lead_sarah = Lead.find_or_create_by!(customer: sarah, title: "Kitchen Renovation Quote") do |l|
  l.description    = "Full kitchen remodel including cabinets, countertops, and tile backsplash."
  l.job_type       = :kitchen
  l.source         = :referral
  l.status         = :converted
  l.estimated_value = 18_500.00
  l.assigned_to    = "Carlos V."
end

lead_james = Lead.find_or_create_by!(customer: james, title: "Master Bath Floor Tiling") do |l|
  l.description    = "Replace existing vinyl with 12x24 porcelain tile in master bathroom."
  l.job_type       = :tile
  l.source         = :walk_in
  l.status         = :quoted
  l.estimated_value = 3_200.00
  l.assigned_to    = "Mia R."
end

lead_linda = Lead.find_or_create_by!(customer: linda, title: "Hardwood Flooring — Living Room") do |l|
  l.description    = "Install 800 sq ft of engineered hardwood throughout living and dining area."
  l.job_type       = :flooring
  l.source         = :referral
  l.status         = :contacted
  l.estimated_value = 9_800.00
  l.assigned_to    = "Carlos V."
end

lead_marcus = Lead.find_or_create_by!(customer: marcus, title: "Materials Supply — Tile Order") do |l|
  l.description    = "Bulk tile material order for contractor client, ~600 sq ft."
  l.job_type       = :materials
  l.source         = :other
  l.status         = :new
  l.estimated_value = 2_100.00
  l.assigned_to    = nil
end

lead_rachel = Lead.find_or_create_by!(customer: rachel, title: "Mixed Renovation — Bathroom & Kitchen") do |l|
  l.description    = "Scope TBD — customer walked in requesting estimates for both kitchen and two bathrooms."
  l.job_type       = :mixed
  l.source         = :walk_in
  l.status         = :lost
  l.estimated_value = 22_000.00
  l.assigned_to    = "Mia R."
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
  j.source          = "referral"
end

Job.find_or_create_by!(lead: lead_james) do |j|
  j.customer        = james
  j.title           = "Master Bath Tile — Okafor Residence"
  j.description     = "12x24 porcelain tile installation. Materials confirmed, scheduling pending."
  j.job_type        = :tile
  j.status          = :on_hold
  j.estimated_value = 3_200.00
  j.assigned_to     = "Mia R."
  j.source          = "walk_in"
end
