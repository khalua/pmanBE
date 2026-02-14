puts "Seeding database..."

# Users
tenant = User.find_or_create_by!(email: "tenant@example.com") do |u|
  u.name = "John Doe"
  u.password = "password123"
  u.phone = "555-123-4567"
  u.address = "123 Main St, Apt 4B, City, State 12345"
  u.role = :tenant
end

manager = User.find_or_create_by!(email: "manager@example.com") do |u|
  u.name = "Jane Smith"
  u.password = "password123"
  u.phone = "555-987-6543"
  u.role = :property_manager
end

# Vendors (matching iOS app sample data)
vendors_data = [
  { name: "Quick Fix Plumbing", phone_number: "555-PLB-0001", vendor_type: :plumbing, rating: 4.8, location: "Downtown", specialties: ["Emergency repairs", "Pipe fitting", "Drain cleaning"] },
  { name: "Pro Pipe Solutions", phone_number: "555-PLB-0002", vendor_type: :plumbing, rating: 4.6, location: "Midtown", specialties: ["Water heaters", "Sewer lines", "Leak detection"] },
  { name: "Elite Plumbing Co", phone_number: "555-PLB-0003", vendor_type: :plumbing, rating: 4.9, location: "Uptown", specialties: ["Commercial plumbing", "Remodeling", "Backflow prevention"] },

  { name: "AppliancePro Repair", phone_number: "555-APP-0001", vendor_type: :appliance, rating: 4.7, location: "Downtown", specialties: ["Refrigerators", "Washers/Dryers", "Dishwashers"] },
  { name: "Home Appliance Experts", phone_number: "555-APP-0002", vendor_type: :appliance, rating: 4.5, location: "Midtown", specialties: ["Ovens", "Microwaves", "HVAC units"] },
  { name: "Fix-It Appliance Service", phone_number: "555-APP-0003", vendor_type: :appliance, rating: 4.8, location: "Uptown", specialties: ["All brands", "Same-day service", "Warranty work"] },

  { name: "Bright Spark Electric", phone_number: "555-ELC-0001", vendor_type: :electrical, rating: 4.9, location: "Downtown", specialties: ["Wiring", "Panel upgrades", "Lighting"] },
  { name: "PowerUp Electrical", phone_number: "555-ELC-0002", vendor_type: :electrical, rating: 4.6, location: "Midtown", specialties: ["Outlets", "Circuit breakers", "EV chargers"] },
  { name: "Safe Circuit Electricians", phone_number: "555-ELC-0003", vendor_type: :electrical, rating: 4.7, location: "Uptown", specialties: ["Code compliance", "Emergency service", "Smart home"] },

  { name: "Cool Breeze HVAC", phone_number: "555-HVC-0001", vendor_type: :hvac, rating: 4.8, location: "Downtown", specialties: ["AC repair", "Heating systems", "Duct cleaning"] },
  { name: "Climate Control Pros", phone_number: "555-HVC-0002", vendor_type: :hvac, rating: 4.5, location: "Midtown", specialties: ["Installation", "Maintenance", "Air quality"] },
  { name: "All Seasons HVAC", phone_number: "555-HVC-0003", vendor_type: :hvac, rating: 4.7, location: "Uptown", specialties: ["Commercial HVAC", "Heat pumps", "Thermostats"] },

  { name: "Handy Property Services", phone_number: "555-GEN-0001", vendor_type: :general, rating: 4.6, location: "Downtown", specialties: ["Painting", "Drywall", "General repairs"] },
  { name: "AllFix Maintenance", phone_number: "555-GEN-0002", vendor_type: :general, rating: 4.4, location: "Midtown", specialties: ["Carpentry", "Plaster", "Door/window repair"] },
  { name: "Property Care Solutions", phone_number: "555-GEN-0003", vendor_type: :general, rating: 4.7, location: "Uptown", specialties: ["Turnover prep", "Inspections", "Preventive maintenance"] },

  { name: "Top Roof Contractors", phone_number: "555-ROF-0001", vendor_type: :roofing, rating: 4.8, location: "Downtown", specialties: ["Leak repair", "Shingle replacement", "Gutters"] },
  { name: "Solid Roofing Co", phone_number: "555-ROF-0002", vendor_type: :roofing, rating: 4.6, location: "Midtown", specialties: ["Flat roofs", "Inspections", "Storm damage"] },
  { name: "Peak Roofing & Exterior", phone_number: "555-ROF-0003", vendor_type: :roofing, rating: 4.9, location: "Uptown", specialties: ["Full replacement", "Siding", "Fascia/soffit"] },

  { name: "Perfect Floor Installers", phone_number: "555-FLR-0001", vendor_type: :flooring, rating: 4.7, location: "Downtown", specialties: ["Hardwood", "Tile", "Laminate"] },
  { name: "Ground Up Flooring", phone_number: "555-FLR-0002", vendor_type: :flooring, rating: 4.5, location: "Midtown", specialties: ["Carpet", "Vinyl", "Repair"] },
  { name: "FloorCraft Pros", phone_number: "555-FLR-0003", vendor_type: :flooring, rating: 4.8, location: "Uptown", specialties: ["Commercial flooring", "Refinishing", "Waterproofing"] },

  { name: "BugFree Pest Control", phone_number: "555-PST-0001", vendor_type: :pest_control, rating: 4.8, location: "Downtown", specialties: ["Roaches", "Ants", "Rodents"] },
  { name: "Shield Pest Solutions", phone_number: "555-PST-0002", vendor_type: :pest_control, rating: 4.6, location: "Midtown", specialties: ["Termites", "Bed bugs", "Wildlife"] },
  { name: "EcoPest Management", phone_number: "555-PST-0003", vendor_type: :pest_control, rating: 4.9, location: "Uptown", specialties: ["Eco-friendly", "Prevention", "Commercial"] }
]

vendors_data.each do |data|
  Vendor.find_or_create_by!(name: data[:name]) do |v|
    v.phone_number = data[:phone_number]
    v.vendor_type = data[:vendor_type]
    v.rating = data[:rating]
    v.is_available = true
    v.location = data[:location]
    v.specialties = data[:specialties]
  end
end

# Sample maintenance request
MaintenanceRequest.find_or_create_by!(tenant: tenant, issue_type: "Leaking kitchen faucet") do |r|
  r.location = "Kitchen"
  r.severity = :moderate
  r.status = :submitted
  r.conversation_summary = "Tenant reports a steady drip from the kitchen faucet. Started 2 days ago and is getting worse."
  r.allows_direct_contact = true
end

puts "Seeded #{User.count} users, #{Vendor.count} vendors, #{MaintenanceRequest.count} maintenance requests"
