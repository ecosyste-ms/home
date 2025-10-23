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
    quota_reset: 'hourly',
    burst_requests: false,
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
  slug: 'researcher',
  name: 'Researcher',
  price_cents: 10000,
  billing_period: 'month',
  requests_per_hour: 2000,
  description: 'For bulk and volume downloads that don’t depend on the fastest access',
  metadata: {
    tagline: 'For those who require bulk and volume downloads but don’t depend on the fastest access',
    access_type: 'API Key',
    quota_reset: 'daily',
    daily_quota_total: 48_000,
    burst_requests: true,
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
  slug: 'developer',
  name: 'Developer',
  price_cents: 50000,
  billing_period: 'month',
  requests_per_hour: 5000,
  description: 'Fast, responsive, and supported access to our data APIs for your production application',
  metadata: {
    tagline: 'Fast, responsive, and supported access to our data APIs for your production application',
    access_type: 'API Key',
    quota_reset: 'hourly',
    burst_requests: false,
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