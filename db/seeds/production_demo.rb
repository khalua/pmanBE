# Production demo seed — safe to run in any environment
# Usage: rails runner db/seeds/production_demo.rb
#
# Tenants are created with a random unknown password (SecureRandom.hex) —
# they can only gain access via the tenant invitation flow, not by logging in directly.

puts "=== Production Demo Seed ==="

# ─── Clean up existing manager data ─────────────────────────────────────────
existing_manager = User.find_by(email: "manager@example.com")
if existing_manager
  puts "Cleaning up existing data for manager@example.com..."
  property_ids = existing_manager.properties.pluck(:id)
  unit_ids     = Unit.where(property_id: property_ids).pluck(:id)
  tenant_ids   = User.where(unit_id: unit_ids).pluck(:id)

  MaintenanceRequest.where(tenant_id: tenant_ids).destroy_all
  TenantInvitation.where(unit_id: unit_ids).delete_all
  User.where(id: tenant_ids).destroy_all
  Unit.where(id: unit_ids).destroy_all
  existing_manager.properties.destroy_all
  existing_manager.property_manager_vendors.destroy_all
  puts "Cleanup done."
end

# ─── Manager ────────────────────────────────────────────────────────────────
manager = User.find_or_create_by!(email: "manager@example.com") do |u|
  u.name     = "Jane Smith"
  u.password = "password123"
  u.phone    = "555-987-6543"
  u.role     = :property_manager
end
puts "Manager: #{manager.email}"

# ─── Vendors ────────────────────────────────────────────────────────────────
vendors_data = [
  # Plumbing
  { name: "Quick Fix Plumbing",      cell_phone: "555-201-0001", phone_number: "555-PLB-0001", vendor_type: :plumbing,     rating: 4.8, location: "Downtown",  specialties: ["Emergency repairs", "Pipe fitting", "Drain cleaning"],         contact_name: "Mike Torres",    email: "quickfix@vendors.com" },
  { name: "Pro Pipe Solutions",       cell_phone: "555-201-0002", phone_number: "555-PLB-0002", vendor_type: :plumbing,     rating: 4.6, location: "Midtown",   specialties: ["Water heaters", "Sewer lines", "Leak detection"],              contact_name: "Sarah Plumb",    email: "propipe@vendors.com" },
  { name: "Elite Plumbing Co",        cell_phone: "555-201-0003", phone_number: "555-PLB-0003", vendor_type: :plumbing,     rating: 4.9, location: "Uptown",    specialties: ["Commercial plumbing", "Remodeling", "Backflow prevention"],    contact_name: "Dan Rivers",     email: "eliteplumb@vendors.com" },
  # Appliance
  { name: "AppliancePro Repair",      cell_phone: "555-202-0001", phone_number: "555-APP-0001", vendor_type: :appliance,    rating: 4.7, location: "Downtown",  specialties: ["Refrigerators", "Washers/Dryers", "Dishwashers"],              contact_name: "Linda Fixer",    email: "appliancepro@vendors.com" },
  { name: "Home Appliance Experts",   cell_phone: "555-202-0002", phone_number: "555-APP-0002", vendor_type: :appliance,    rating: 4.5, location: "Midtown",   specialties: ["Ovens", "Microwaves", "HVAC units"],                           contact_name: "Ray Hanson",     email: "homeapp@vendors.com" },
  { name: "Fix-It Appliance Service", cell_phone: "555-202-0003", phone_number: "555-APP-0003", vendor_type: :appliance,    rating: 4.8, location: "Uptown",    specialties: ["All brands", "Same-day service", "Warranty work"],             contact_name: "Carol Fix",      email: "fixit@vendors.com" },
  # Electrical
  { name: "Bright Spark Electric",    cell_phone: "555-203-0001", phone_number: "555-ELC-0001", vendor_type: :electrical,   rating: 4.9, location: "Downtown",  specialties: ["Wiring", "Panel upgrades", "Lighting"],                        contact_name: "James Volt",     email: "brightspark@vendors.com" },
  { name: "PowerUp Electrical",       cell_phone: "555-203-0002", phone_number: "555-ELC-0002", vendor_type: :electrical,   rating: 4.6, location: "Midtown",   specialties: ["Outlets", "Circuit breakers", "EV chargers"],                  contact_name: "Tina Watts",     email: "powerup@vendors.com" },
  { name: "Safe Circuit Electricians",cell_phone: "555-203-0003", phone_number: "555-ELC-0003", vendor_type: :electrical,   rating: 4.7, location: "Uptown",    specialties: ["Code compliance", "Emergency service", "Smart home"],          contact_name: "Greg Ohm",       email: "safecircuit@vendors.com" },
  # HVAC
  { name: "Cool Breeze HVAC",         cell_phone: "555-204-0001", phone_number: "555-HVC-0001", vendor_type: :hvac,         rating: 4.8, location: "Downtown",  specialties: ["AC repair", "Heating systems", "Duct cleaning"],               contact_name: "Brenda Cool",    email: "coolbreeze@vendors.com" },
  { name: "Climate Control Pros",     cell_phone: "555-204-0002", phone_number: "555-HVC-0002", vendor_type: :hvac,         rating: 4.5, location: "Midtown",   specialties: ["Installation", "Maintenance", "Air quality"],                  contact_name: "Tom Climate",    email: "climatecontrol@vendors.com" },
  { name: "All Seasons HVAC",         cell_phone: "555-204-0003", phone_number: "555-HVC-0003", vendor_type: :hvac,         rating: 4.7, location: "Uptown",    specialties: ["Commercial HVAC", "Heat pumps", "Thermostats"],                contact_name: "Wendy Seasons",  email: "allseasons@vendors.com" },
  # General
  { name: "Handy Property Services",  cell_phone: "555-205-0001", phone_number: "555-GEN-0001", vendor_type: :general,      rating: 4.6, location: "Downtown",  specialties: ["Painting", "Drywall", "General repairs"],                      contact_name: "Bob Handy",      email: "handyprop@vendors.com" },
  { name: "AllFix Maintenance",       cell_phone: "555-205-0002", phone_number: "555-GEN-0002", vendor_type: :general,      rating: 4.4, location: "Midtown",   specialties: ["Carpentry", "Plaster", "Door/window repair"],                  contact_name: "Nina Allfix",    email: "allfix@vendors.com" },
  { name: "Property Care Solutions",  cell_phone: "555-205-0003", phone_number: "555-GEN-0003", vendor_type: :general,      rating: 4.7, location: "Uptown",    specialties: ["Turnover prep", "Inspections", "Preventive maintenance"],      contact_name: "Oscar Care",     email: "propertycare@vendors.com" },
  # Roofing
  { name: "Top Roof Contractors",     cell_phone: "555-206-0001", phone_number: "555-ROF-0001", vendor_type: :roofing,      rating: 4.8, location: "Downtown",  specialties: ["Leak repair", "Shingle replacement", "Gutters"],               contact_name: "Pete Roof",      email: "toproof@vendors.com" },
  { name: "Solid Roofing Co",         cell_phone: "555-206-0002", phone_number: "555-ROF-0002", vendor_type: :roofing,      rating: 4.6, location: "Midtown",   specialties: ["Flat roofs", "Inspections", "Storm damage"],                   contact_name: "Alice Solid",    email: "solidroof@vendors.com" },
  { name: "Peak Roofing & Exterior",  cell_phone: "555-206-0003", phone_number: "555-ROF-0003", vendor_type: :roofing,      rating: 4.9, location: "Uptown",    specialties: ["Full replacement", "Siding", "Fascia/soffit"],                 contact_name: "Mark Peak",      email: "peakroof@vendors.com" },
  # Flooring
  { name: "Perfect Floor Installers", cell_phone: "555-207-0001", phone_number: "555-FLR-0001", vendor_type: :flooring,     rating: 4.7, location: "Downtown",  specialties: ["Hardwood", "Tile", "Laminate"],                                contact_name: "Susan Floor",    email: "perfectfloor@vendors.com" },
  { name: "Ground Up Flooring",       cell_phone: "555-207-0002", phone_number: "555-FLR-0002", vendor_type: :flooring,     rating: 4.5, location: "Midtown",   specialties: ["Carpet", "Vinyl", "Repair"],                                   contact_name: "Henry Ground",   email: "groundup@vendors.com" },
  { name: "FloorCraft Pros",          cell_phone: "555-207-0003", phone_number: "555-FLR-0003", vendor_type: :flooring,     rating: 4.8, location: "Uptown",    specialties: ["Commercial flooring", "Refinishing", "Waterproofing"],         contact_name: "Ivy Craft",      email: "floorcraft@vendors.com" },
  # Pest Control
  { name: "BugFree Pest Control",     cell_phone: "555-208-0001", phone_number: "555-PST-0001", vendor_type: :pest_control, rating: 4.8, location: "Downtown",  specialties: ["Roaches", "Ants", "Rodents"],                                  contact_name: "Larry Bug",      email: "bugfree@vendors.com" },
  { name: "Shield Pest Solutions",    cell_phone: "555-208-0002", phone_number: "555-PST-0002", vendor_type: :pest_control, rating: 4.6, location: "Midtown",   specialties: ["Termites", "Bed bugs", "Wildlife"],                            contact_name: "Faye Shield",    email: "shieldpest@vendors.com" },
  { name: "EcoPest Management",       cell_phone: "555-208-0003", phone_number: "555-PST-0003", vendor_type: :pest_control, rating: 4.9, location: "Uptown",    specialties: ["Eco-friendly", "Prevention", "Commercial"],                    contact_name: "Ned Eco",        email: "ecopest@vendors.com" },
]

vendors = vendors_data.map do |data|
  Vendor.find_or_create_by!(name: data[:name]) do |v|
    v.cell_phone    = data[:cell_phone]
    v.phone_number  = data[:phone_number]
    v.vendor_type   = data[:vendor_type]
    v.rating        = data[:rating]
    v.is_available  = true
    v.location      = data[:location]
    v.specialties   = data[:specialties]
    v.contact_name  = data[:contact_name]
    v.email         = data[:email]
  end
end

# Link all vendors to the manager
vendors.each do |vendor|
  PropertyManagerVendor.find_or_create_by!(user: manager, vendor: vendor) do |pmv|
    pmv.is_active = true
  end
end
puts "Vendors: #{vendors.length} created/found, all linked to manager"

# ─── Properties ─────────────────────────────────────────────────────────────
properties_data = [
  { name: "Sunset Towers",       address: "100 Sunset Blvd, Los Angeles, CA 90001",     type: :building, floors: 8,  units_per_floor: 6 },  # 48 units
  { name: "Maple Grove Apts",    address: "250 Maple Ave, Los Angeles, CA 90002",        type: :building, floors: 6,  units_per_floor: 6 },  # 36 units
  { name: "Harbor View Complex", address: "1 Harbor Dr, Los Angeles, CA 90003",          type: :building, floors: 5,  units_per_floor: 4 },  # 20 units
  { name: "Elmwood Houses",      address: "900 Elmwood St, Los Angeles, CA 90004",       type: :house,    floors: 1,  units_per_floor: 4 },  # 4 units (4 standalone houses)
  { name: "The Palms",           address: "4400 Palm Canyon Rd, Los Angeles, CA 90005",  type: :building, floors: 4,  units_per_floor: 6 },  # 24 units
]
# Total: 132 units → 100 tenants → ~32 vacant units

# Build enough units to cover 100 tenants.
# We'll accumulate all units across properties, then assign tenants round-robin.
all_units = []

properties_data.each do |pd|
  property = Property.find_or_create_by!(name: pd[:name]) do |p|
    p.address         = pd[:address]
    p.property_type   = pd[:type]
    p.property_manager = manager
  end

  total_floors = pd[:floors]
  uph          = pd[:units_per_floor]

  total_floors.times do |floor_idx|
    floor_num = floor_idx + 1
    uph.times do |unit_idx|
      letter = ("A".."Z").to_a[unit_idx]
      identifier = "#{floor_num}#{letter}"
      unit = Unit.find_or_create_by!(property: property, identifier: identifier) do |u|
        u.floor = floor_num
      end
      all_units << unit
    end
  end
end

puts "Properties: #{properties_data.length}, Units: #{all_units.length}"

# ─── Tenants ────────────────────────────────────────────────────────────────
# Tenants are seeded with a random unknown password. They cannot log in directly;
# access is granted only via the manager's tenant invitation flow (email link).
FIRST_NAMES = %w[
  James Mary Robert Patricia John Jennifer Michael Linda William Barbara
  David Elizabeth Richard Susan Joseph Jessica Thomas Sarah Charles Karen
  Christopher Lisa Daniel Nancy Matthew Betty Anthony Margaret Mark Sandra
  Donald Ashley Steven Dorothy Paul Kimberly Andrew Emily Joshua Donna
  Kenneth Michelle Kevin Carol Brian Amanda George Melissa Edward Deborah
  Ronald Stephanie Timothy Rebecca Jason Sharon Jeffrey Laura Ryan Cynthia
  Jacob Kathleen Gary Amy Nicholas Angela Eric Shirley Jonathan Anna
  Stephen Virginia Larry Brenda Justin Pamela Scott Emma Brandon Grace
  Benjamin Judith Samuel Hannah Frank Virginia Raymond Diane Alexander Christina
].freeze

LAST_NAMES = %w[
  Smith Johnson Williams Brown Jones Garcia Miller Davis Wilson Anderson
  Taylor Thomas Hernandez Moore Martin Jackson Thompson White Lopez Lee
  Gonzalez Harris Clark Lewis Robinson Walker Perez Hall Young Allen
  Sanchez Wright King Scott Green Baker Adams Nelson Hill Ramirez
  Campbell Mitchell Roberts Carter Phillips Evans Turner Torres Parker
  Collins Edwards Stewart Flores Morris Nguyen Murphy Rivera Cook Rogers
  Morgan Peterson Cooper Reed Bailey Bell Gomez Kelly Howard Ward Cox
].freeze

STREETS = [
  "Oak St", "Maple Ave", "Cedar Rd", "Pine Ln", "Elm Dr",
  "Washington Blvd", "Park Ave", "Lake Rd", "River Dr", "Hill St"
].freeze

CITIES = [
  "Los Angeles, CA", "Pasadena, CA", "Burbank, CA",
  "Glendale, CA", "Santa Monica, CA"
].freeze

def create_tenant(email:, name:, phone_base:, mobile_base:, idx:, unit:)
  return if User.exists?(email: email)

  User.create!(
    name:          name,
    email:         email,
    password:      SecureRandom.hex(32),
    cell_phone:    mobile_base,
    address:       "#{idx + 100} #{STREETS[idx % STREETS.length]}, #{CITIES[idx % CITIES.length]}",
    role:          :tenant,
    unit:          unit,
    phone_verified: false,
    move_in_date:  rand(1..36).months.ago.to_date
  )
end

created_tenants = 0
tenant_seq      = 0  # global counter for unique emails/phones

# Shuffle so tenants are spread across all properties, not packed into the first ones
units_to_fill = all_units.shuffle(random: Random.new(42))  # fixed seed = reproducible

units_to_fill.first(100).each_with_index do |unit, unit_idx|
  # Primary tenant
  idx   = tenant_seq
  first = FIRST_NAMES[idx % FIRST_NAMES.length]
  last  = LAST_NAMES[(idx * 7) % LAST_NAMES.length]

  t = create_tenant(
    email:       "tenant#{idx + 1}@demo.pman",
    name:        "#{first} #{last}",
    phone_base:  format("555-%03d-%04d", 1, idx + 1),
    mobile_base: format("555-%03d-%04d", 51, idx + 1),
    idx:         idx,
    unit:        unit
  )
  created_tenants += 1 if t
  tenant_seq += 1

  # Every 5th unit gets a roommate (second tenant)
  if (unit_idx + 1) % 5 == 0
    idx2   = tenant_seq + 500  # offset to keep emails unique
    first2 = FIRST_NAMES[(idx2 * 3) % FIRST_NAMES.length]
    last2  = LAST_NAMES[(idx2 * 11) % LAST_NAMES.length]

    t2 = create_tenant(
      email:       "tenant#{idx2 + 1}@demo.pman",
      name:        "#{first2} #{last2}",
      phone_base:  format("555-%03d-%04d", 2, idx2 + 1),
      mobile_base: format("555-%03d-%04d", 52, idx2 + 1),
      idx:         idx2,
      unit:        unit
    )
    created_tenants += 1 if t2
    tenant_seq += 1
  end
end

puts "Tenants created: #{created_tenants} (#{User.tenant.count} total tenants in DB)"

puts "=== Done ==="
puts ""
puts "Summary:"
puts "  Manager:    manager@example.com / password123"
puts "  Properties: #{Property.where(property_manager: manager).count}"
puts "  Units:      #{Unit.joins(:property).where(properties: { property_manager: manager }).count}"
puts "  Tenants:    #{User.tenant.count} (password unknown — invite-only access)"
puts "  Vendors:    #{Vendor.count} (#{Vendor.group(:vendor_type).count.map { |k, v| "#{v} #{k}" }.join(", ")})"
puts "  Requests:   0 (clean slate)"
