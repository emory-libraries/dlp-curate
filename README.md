

# DLP-Curate

<table width="100%">
<tr><td>
<img src="app/assets/images/EU_vt_280.png" width="200">
</td><td>
A repository application for digital curators (preservation, rights and metadata management, collection management). Find more about the project on our
<a href="https://wiki.service.emory.edu/display/DLPP"><em>DLP Wiki</em></a>
<br/><br/>

[![CircleCI](https://circleci.com/gh/emory-libraries/dlp-curate.svg?style=svg)](https://circleci.com/gh/emory-libraries/dlp-curate)
[![Test Coverage](https://api.codeclimate.com/v1/badges/93dcdd252e2378e18ecd/test_coverage)](https://codeclimate.com/github/emory-libraries/dlp-curate/test_coverage)
[![User Stories](https://raw.githubusercontent.com/ZenHubIO/support/master/zenhub-badge.png)](https://app.zenhub.com/workspaces/dlp-curate-5bf484ae4b5806bc2bf6875b)

</td></tr>
</table>

## Database Authentication

In a production environment, we will use Shibboleth for authentication. However, in a development environment we will be using a local database.

## Local Development Setup

Our new local development environment now utilizes a docker compose container system to run Fedora 4.7.5, Solr 8.11.1, FITS Servlet 1.6.0, and Redis 6.2 servers. However, the following applications must still be installed on the local machine: Mysql2 (or MariaDB), ImageMagick, and LibreOffice (ffmpeg is still optional, but will most likely be incorporated in later versions). Also note that this version of Curate uses Ruby 3.2.9.

Do the following within the `dlp-curate` directory:

1. Copy and rename `dotenv_development.sample` twice, one named `.env.development` and the other `.env.test`.
2. Within both new `.env` files, assign your username and password to the `DATABASE_USERNAME` and `DATABASE_PASSWORD` variables.
3. `docker compose up` (Errors here usually indicate the ports are already being used somewhere else on your machine.)
4. FIRST TIME ONLY: `bundle exec rake db:create` (Errors usually occur here because of Mysql2/MariaDB user/password issues.)
5. FIRST TIME ONLY (or after a new database migration has been added): `bundle exec rake db:migrate`
6. FIRST TIME ONLY: `bundle exec rake db:seed`
    - This sets up an admin user of `dev-admin` and a normal user named `user3`, both with the password of "123456".
7. FIRST TIME ONLY: `bundle exec rake curate:collections:migration_setup`
    - This creates the default `AdminSet` and `CollectionType`, as well as the "Library" `CollectionType` and the desired `Workflows`.
    - Running this command has no real effect on the "Test" environment--but after this rake task is complete, your local users should be able to create any object.
8. Setup should be complete, which means that `bundle exec rails s` will launch the server access.
9. Access the app through `http://localhost:3000/`.

Refer to the Hyrax local development [guide](https://github.com/samvera/hyrax/blob/hyrax-v5.2.0/documentation/developing-your-hyrax-based-app.md) for more information regarding installation of tools like ImageMagick and LibreOffice.

To run the tests locally, fire off `bundle exec rspec` within the `dlp-curate` directory.

# Deployment

1. Connect to `vpn.emory.edu`
2. Pull the latest version of `main`
3. Stub AWS' environment variables for `Emory Account 70` within the same terminal window. These can be found in the page loaded after logging into [Emory's AWS](https://aws.emory.edu). Directions below:
  a. After logging in, the page should be the `AWS access portal`. A table of multiple accounts should be present (typically three). Expand the `Emory Account 70` option.
  b. Clicking on `Access keys` will open a modal with multiple credential options. Option 1 (`Set AWS environment variables`) is necessary for successful deployment.
  c. Copy the variables in Option 1, paste them into the terminal window that the deployment script will be processed, and press enter.
5. To deploy, run `BRANCH={BRANCH_NAME_OR_TAG} bundle exec cap {ENVIRONMENT} deploy`. To deploy main to the arch environment, for instance, you run `BRANCH=main bundle exec cap arch deploy`.

## Deployment Troubleshooting

If errors occur when running the deployment script, there could be a couple of factors causing them:
- Ensure you are authorized to access the server you are deploying to. You can verify your access by trying to ssh into the server e.g. `ssh deploy@SERVER_IP_ADDRESS`.
- The server IP lookup processing may not be working. In this case, stub the backup environment variables for the desired server in the local `.env.development` file. The list of backup environment variables are below:

```
ARCH_SERVER_IP=
TEST_SERVER_IP=
PROD_SERVER_IP=
```

# Caching manifests with localhost

In a development environment, rake task creates and caches manifests with
`base_url` as `localhost:3000`.

In order to run the rake task locally and see cached manifests properly,
please use port 3000 with localhost.
