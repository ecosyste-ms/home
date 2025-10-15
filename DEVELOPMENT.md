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

⏳ Placeholder/Coming soon:
- Stripe payment integration
- Google OAuth
- Email/Password authentication
- Actual payment processing
- Rate limiting (handled by APISIX gateway)

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
