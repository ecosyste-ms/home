# db/seeds.rb
puts "Resetting and creating plans…"

# ⚠️ Dev-only: clear out all existing plans
Plan.delete_all

# Helper: update existing or create new
def upsert_plan(slug:, **attrs)
  Plan.find_or_initialize_by(slug: slug).tap do |p|
    p.assign_attributes(attrs)
    p.save!
  end
end

upsert_plan(
  slug: 'free',
  name: 'Free',
  display_name: 'Free',
  price_cents: 0,
  billing_period: 'month',
  requests_per_hour: 300,
  description: 'For small-scale projects and hobbyists looking to add ecosystems data to their project',
  metadata: {
    tagline: 'For small-scale projects and hobbyists looking to add ecosystems data to their project',
    access_type: 'Common or polite pools',
    priority: 'Standard',
    support_level: 'Community',
    sla_level: 'None',
    license_name: 'CC BY-SA 4.0',
    dashboard_access: false
  },
  features: ['Access to all APIs'],
  position: 1, public: true, visible: true, active: true
)

upsert_plan(
  slug: 'develop',
  name: 'Develop',
  price_cents: 20000,
  billing_period: 'month',
  requests_per_hour: 1000,
  description: 'For larger scale experiments and prototype services',
  metadata: {
    tagline: 'For larger scale experiments and prototype services',
    access_type: 'API Key',
    priority: 'Standard',
    support_level: 'Community',
    sla_level: 'Standard',
    license_name: 'CC BY-SA 4.0',
    dashboard_access: true
  },
  features: [],
  position: 2, public: true, visible: true, active: true
)

upsert_plan(
  slug: 'scale',
  name: 'Scale',
  price_cents: 100000,
  billing_period: 'month',
  requests_per_hour: 5000,
  description: 'For production applications and services',
  metadata: {
    tagline: 'For production applications and services',
    access_type: 'API Key',
    priority: 'High priority',
    support_level: 'Priority',
    sla_level: 'Commercial',
    license_name: 'CC BY-SA 4.0',
    dashboard_access: true
  },
  features: [],
  position: 3, public: true, visible: true, active: true
)

puts "Plans ready: #{Plan.count}"