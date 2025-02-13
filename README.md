[![Maintainability](https://api.codeclimate.com/v1/badges/bd4ed58b6b08523b837a/maintainability)](https://codeclimate.com/github/TallerWebSolutions/flow_climate/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/bd4ed58b6b08523b837a/test_coverage)](https://codeclimate.com/github/TallerWebSolutions/flow_climate/test_coverage)
![FlowClimateBuild](https://github.com/TallerWebSolutions/flow_climate/workflows/FlowClimateBuild/badge.svg)
[![sponsored by Taller](https://raw.githubusercontent.com/TallerWebSolutions/tallerwebsolutions.github.io/master/sponsored-by-taller.png)](https://taller.net.br/en/)

# Flow Climate

Bringing the management to the next level.

Have the ultimate management tools in your hands!

## Using:

- Sendgrid to send emails
- Rollbar to monitor production errors
- RSpec as test framework
- Fabrication as factory for specs
- Faker to generate fake data

## How to build the environment

- Install PostgreSQL v. 13.3
- Install ImageMagick `brew install imagemagick` or `apt install imagemagick`
- Configure pgsql
  - Start postgresql
    - Example on macOS (brew instalation): `pg_ctl -D /usr/local/var/postgres start`
  - psql postgres
  - run `CREATE USER postgres SUPERUSER;`
  - run `CREATE DATABASE postgres WITH OWNER postgres;`
  - run `\password postgres` and define _postgres_ as user password;
- Check `config/database.yml` for further information
- You may need to install the `lipq-dev` on Linux environments
  - `sudo apt install postgresql libpq-dev`
- Install rvm or rbenv - the main development team is using _rvm_
- If you choose rvm then - Install the correct version (the examples will use the ruby-3.1.3)
  - `rvm install ruby-3.1.3`
    - Create the gemset to the project under the correct version
  - In the project folder run:
  - `rvm use 3.1.3@flow_climate --create`
  - `gem install bundler`
  - `bundle install`
  - copy the application.yml.example to application.yml
- In the project folder run:

  - `rake db:create`
  - `rake db:migrate`
  - `RAILS_ENV=test rake db:migrate`

- CI/CD: Github actions

  - Check [Github Actions](https://github.com/TallerWebSolutions/flow_climate/tree/develop/.github/workflows)

- The build relies on `rspec` and `rubocop` success
- In the project folder you should be able to run and check the output of:

  - `rspec`
  - `rubocop -A`

- Run console: `rails c`
- Run server: `rails s`

\*\* Local debugging for Visual Studio Code
[See this article](https://rahul-arora.medium.com/debugging-ruby-on-rails-server-in-vs-code-819b45113e78)

## Storybook

Always check storybook before creating new components for the spa.

```
cd app/spa
npm run storybook
```

## Troubleshoot

fe_sendauth: no password supplied

When syncing production database this error may occur. Check the following:
- /var/lib/pgsql/data/pg_hba.conf (may be another path in your OS) is set to use md5 in local and  127.0.0.1/32 
- You have a postgres user with the same name as your OS user and all privileges.
- You have a password file in your home directory. https://www.postgresql.org/docs/current/libpq-pgpass.html