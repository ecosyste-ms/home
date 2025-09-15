# Development

## Setup

First things first, you'll need to fork and clone the repository to your local machine.

`git clone https://github.com/ecosyste-ms/documentation.git`

The project uses ruby on rails which have a number of system dependencies you'll need to install.

- [ruby](https://www.ruby-lang.org/en/documentation/installation/)
- [node.js 16+](https://nodejs.org/en/download/)

You'll also need a running [PostgresQL](https://www.postgresql.org) server.

Once you've got all of those installed, from the root directory of the project run the following commands:

```
bin/setup
rails server
```

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

### Docker

Alternatively you can use the existing docker configuration files to run the app in a container.

Run this command from the root directory of the project to start the service (and PostgreSQL).

`docker-compose up --build`

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

For access the rails console use the following command:

`docker-compose exec app rails console`

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
