# Development

## Setup

First things first, you'll need to fork and clone the repository to your local machine.

`git clone https://github.com/ecosyste-ms/documentation.git`

The project uses ruby on rails which have a number of system dependencies you'll need to install.

- [ruby](https://www.ruby-lang.org/en/documentation/installation/)
- [node.js 16+](https://nodejs.org/en/download/)

You'll also need a running [PostgresQL](https://www.postgresql.org) server.

You will then need to set some configuration environment variables. Copy `env.example` to `.env.development` and customise the values to suit your local setup.

Once you've got all of those installed, from the root directory of the project run the following commands:

```
bin/setup
rails server
```

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

### GitHub OAuth Setup

The account system uses GitHub OAuth for authentication. To set this up for local development:

1. Create a new GitHub OAuth App at https://github.com/settings/developers
   - Application name: `Ecosyste.ms (Local)`
   - Homepage URL: `http://localhost:3000`
   - Authorization callback URL: `http://localhost:3000/auth/github/callback`

2. Copy the Client ID and Client Secret

3. Add them to your `.env.development` file:
   ```
   GITHUB_CLIENT_ID=your_client_id_here
   GITHUB_CLIENT_SECRET=your_client_secret_here
   ```

4. Restart your Rails server

You can now access the account system at http://localhost:3000/login

### Docker

Alternatively you can use the existing docker configuration files to run the app in a container.

Run this command from the root directory of the project to start the service (and PostgreSQL).

`docker-compose up --build`

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

For access the rails console use the following command:

`docker-compose exec app rails console`

## Account System

The application includes a complete account management system with the following features:

### Features

- **Authentication**: GitHub OAuth (real), with placeholders for Google OAuth and Email/Password
- **Multi-provider support**: Users can link multiple OAuth providers to one account
- **Subscription plans**: Three tiers (Free, Pro, Enterprise) with different rate limits
- **API Key management**: Create and revoke multiple API keys per account
- **Billing**: Support for both card-based and invoice-based payments (Stripe integration pending)
- **Profile management**: Update account details and manage security settings

### Database Schema

The account system uses the following tables:

- `accounts` - User accounts with Stripe customer data
- `identities` - OAuth provider identities (supports multiple per account)
- `plans` - Subscription plan definitions
- `subscriptions` - Account subscriptions with trial and cancellation support
- `api_keys` - API keys with BCrypt hashing and expiration
- `invoices` - Billing invoices (for both card and invoice payments)

Seed data includes three default plans. Run `rails db:seed` to populate them.

### Current Implementation Status

✅ Fully implemented:
- GitHub OAuth authentication
- Account management UI
- API key creation/revocation
- Database schema and models
- Session-based authentication (cookie-only)
- Stripe payment integration (requires configuration)

⏳ Placeholder/Coming soon:
- Google OAuth
- Email/Password authentication
- Rate limiting (handled by APISIX gateway)

### Stripe Integration

The application includes a complete Stripe integration for subscription billing using Stripe Elements.

#### What's Implemented

**Core Components:**
- **StripeService** (`app/services/stripe_service.rb`) - Handles all Stripe API operations
- **CheckoutController** (`app/controllers/checkout_controller.rb`) - Manages checkout flow
- **Webhooks::StripeController** (`app/controllers/webhooks/stripe_controller.rb`) - Processes Stripe webhook events
- **Checkout View** (`app/views/checkout/new.html.erb`) - Stripe Elements payment form
- **Routes** - Checkout and webhook endpoints configured
- **Tests** - Full test coverage for all components

**Features:**
- Subscription creation with Stripe Elements (card payments only)
- Payment method storage and display
- Webhook handling for subscription lifecycle events
- Invoice tracking and billing history
- 3D Secure (SCA) support

#### Setup Steps

**1. Get Stripe API Keys**

1. Create or log in to your Stripe account at https://dashboard.stripe.com
2. Get your API keys from the Developers > API keys section
3. Add the following environment variables to `.env.development`:

```bash
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

For production, use the live keys in your production environment.

**2. Create Stripe Products and Prices**

For each plan in your database, create corresponding Stripe Products and Prices:

1. Go to Products in your Stripe Dashboard
2. Create a product for each plan
3. Add a recurring price to each product
4. Copy the Price ID (starts with `price_`)
5. Update your Plan records in Rails console:

```ruby
# Example - update with your actual Stripe Price IDs
Plan.find_by(slug: 'free')&.update(stripe_price_id: nil) # Free plans don't need a price ID
Plan.find_by(slug: 'developer')&.update(stripe_price_id: 'price_YOUR_DEVELOPER_PRICE_ID')
Plan.find_by(slug: 'business')&.update(stripe_price_id: 'price_YOUR_BUSINESS_PRICE_ID')
```

**3. Configure Webhooks**

1. Go to Developers > Webhooks in Stripe Dashboard
2. Click "Add endpoint"
3. Enter your webhook URL:
   - Development: Use Stripe CLI or a service like ngrok
   - Production: `https://yourdomain.com/webhooks/stripe`
4. Select the following events to listen for:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `invoice.finalized`
5. Copy the webhook signing secret and add it to your environment:

```bash
STRIPE_WEBHOOK_SECRET=whsec_...
```

**4. Test with Stripe CLI (Development)**

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to your local server
stripe listen --forward-to localhost:3000/webhooks/stripe

# This will give you a webhook secret starting with whsec_
# Add it to your .env.development file
```

**5. Test Card Numbers**

Use these test cards in development:

- **Success**: `4242 4242 4242 4242`
- **3D Secure**: `4000 0027 6000 3184`
- **Decline**: `4000 0000 0000 0002`
- Any future expiry date, any CVC, any postal code

Full list: https://stripe.com/docs/testing

#### How It Works

**Checkout Flow:**

1. User selects a plan on `/account/plan`
2. Clicks "Choose plan" → redirects to `/checkout/:plan_id`
3. Enters payment details (Stripe Elements handles card input securely)
4. Submits form → creates PaymentMethod via Stripe.js
5. Frontend sends PaymentMethod ID to backend
6. Backend creates Subscription via StripeService
7. Handles 3D Secure if required
8. Redirects to billing page on success

**Webhook Flow:**

1. Stripe sends webhook events to `/webhooks/stripe`
2. Signature is verified using webhook secret
3. Events are processed:
   - Subscription events update local Subscription records
   - Invoice events create/update local Invoice records
4. Changes sync automatically (no manual updates needed)

#### Environment Variables Required

```bash
# Stripe API Keys
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Stripe Webhook Secret
STRIPE_WEBHOOK_SECRET=whsec_...
```

#### API Version

Using Stripe API version: **2025-10-29.clover**

#### Security Notes

- Webhook signature verification is enabled
- CSRF protection skipped for webhooks (required by Stripe)
- Authentication skipped for webhooks (Stripe validates via signature)
- Payment card data never touches your servers (Stripe Elements handles it)
- All Stripe API calls are server-side only

#### Additional Resources

- Stripe Documentation: https://stripe.com/docs
- Stripe Elements Guide: https://stripe.com/docs/payments/elements
- Testing Guide: https://stripe.com/docs/testing

## Tests

The applications tests can be found in [test](test) and use the testing framework [minitest](https://github.com/minitest/minitest).

You can run all the tests with:

`rails test`


## Adding a service

The services listed on the homepage are defined in [app/controllers/documentation_controller.rb](app/controllers/documentation_controller.rb), to add a new service append something like the following:

```ruby
{
  name: 'Packages',
  url: 'https://packages.ecosyste.ms',
  description: 'An open API service providing package, version and dependency metadata of many open source software ecosystems and registries.',
  icon: 'box-seam',
  repo: 'packages'
},
```

Note: The icon should be a name of an icon from the [bootstrap icon set](https://icons.getbootstrap.com/) (~v1.8) and the repo must exist within the [Ecosystems](https://github.com/ecosyste-ms) GitHub organization.

## Deployment

A container-based deployment is highly recommended, we use [dokku.com](https://dokku.com/).
