# Accounts System - Unimplemented Features

This document tracks features that still need to be implemented for the accounts system.

## To Be Implemented ⏳

### 1. Stripe Integration (P0 - Critical)

**Payment Processing:**
- Stripe Elements integration for card collection
- Create Stripe Customer on signup
- Create Stripe Subscription when user selects plan
- Sync subscription status from Stripe webhooks
- Handle payment failures and retries
- Invoice payment for NET 30 customers

**Webhooks:**
- Process `customer.subscription.created`
- Process `customer.subscription.updated`
- Process `customer.subscription.deleted`
- Process `invoice.paid`
- Process `invoice.payment_failed`
- Webhook signature verification
- Idempotency handling

**Configuration:**
```ruby
# Add to Gemfile
gem 'stripe'

# Environment variables needed
STRIPE_PUBLISHABLE_KEY=pk_xxx
STRIPE_SECRET_KEY=sk_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

### 2. Additional OAuth Providers (P2 - Medium)

**Google OAuth:**
- Add `omniauth-google-oauth2` gem
- Configure Google provider in OmniAuth initializer
- Update login page to enable Google button
- Create Google OAuth app and get credentials

**Email/Password Authentication:**
- Add password_digest to accounts table
- Implement signup form
- Implement password reset flow
- Email verification

### 3. Token Encryption (P1 - High)

**OAuth Token Security:**
- Enable Rails encryption for `token` and `refresh_token` fields in Identity model
- Generate encryption credentials with `bin/rails db:encryption:init`
- Add to Identity model: `encrypts :token` and `encrypts :refresh_token`
- Store credentials securely (not in git)

**Setup:**
```bash
# Generate encryption credentials
bin/rails db:encryption:init

# This creates config/credentials/production.yml.enc with:
# active_record_encryption:
#   primary_key: <generated>
#   deterministic_key: <generated>
#   key_derivation_salt: <generated>

# For development, add to config/credentials/development.yml.enc or use RAILS_MASTER_KEY env var
```

### 4. APISIX Gateway Integration (P1 - High)

**Sync API Keys to APISIX:**
- Create ApisixClient service
- Sync consumers on account creation
- Sync API keys on creation/revocation
- Update rate limits when plan changes
- Background job for reliability
- Handle sync failures gracefully

**Configuration:**
```ruby
# Environment variables needed
APISIX_ADMIN_URL=https://apisix.ecosyste.ms/apisix/admin
APISIX_ADMIN_KEY=xxx
```

**Rake tasks:**
- `rails apisix:sync_all` - Bulk sync all accounts
- `rails apisix:sync_keys` - Sync all API keys
- `rails apisix:cleanup` - Remove deleted accounts

### 5. Admin Interface Enhancements (P2 - Medium)

**Basic admin interface implemented**, still needed:
- Invoice management controller and views
- API key management views (list all keys across accounts)
- Analytics dashboard with charts (revenue, usage, churn)
- Detailed account activity logs/timeline
- Bulk operations (bulk suspend, bulk email, etc.)
- Export functionality (CSV exports)
- Admin audit trail (track who did what)
- Plan creation/editing forms

### 6. Additional Features (P3 - Low)

**Two-Factor Authentication:**
- TOTP implementation
- Backup codes
- Recovery options

**Team/Organization Accounts:**
- `organizations` table
- `organization_members` join table
- Shared API keys and billing
- Role-based permissions

**Usage Analytics for Users:**
- Show API request history
- Endpoint usage breakdown
- Rate limit visualization
- Export usage data

**Email Notifications:**
- Welcome email
- Payment failed
- Trial ending
- Subscription canceled
- Invoice generated
- API key created

**Security Enhancements:**
- Login history tracking
- Suspicious activity detection
- Account recovery flow
- IP whitelisting for API keys
- Webhook delivery system

## Implementation Priority

1. **P0 (Critical):** Stripe integration for actual payments
2. **P1 (High):** Token encryption setup, APISIX integration for API authentication and rate limiting
3. **P2 (Medium):** Google OAuth, Email/Password auth, Admin interface enhancements (forms, analytics)
4. **P3 (Low):** 2FA, Teams/Organizations, Email notifications, Advanced analytics
