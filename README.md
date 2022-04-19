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

# Database Authentication

In a production environment, we will use Shibboleth for authentication. However, in a development environment we will be using a local database.

In order to set up your dev environment for database authentication, you will need to set the following environment variable:

`export DATABASE_AUTH=true`

# Local Development Setup

Run each of the following commands in a separate tab within the `dlp-curate` directory:

1. Setup local Solr instance by running command `solr_wrapper`
2. Setup local Fedora instance by running command `fcrepo_wrapper`
3. Setup local app server by running command `rails server`
4. Access the app through `http://localhost:3000/`

Refer to the Hyrax local development [guide](https://github.com/samvera/hyrax/blob/main/documentation/developing-your-hyrax-based-app.md) for more information regarding installing additional tools like Fits and ImageMagick, which are needed to enable file uploads.

# Testing and CI

To run the tests locally, run each of the following commands in a separate tab within the `dlp-curate` directory:

1. Setup local Solr testing instance by running command `solr_wrapper --config config/solr_wrapper_test.yml`
2. Setup local Fedora testing instance by running command `fcrepo_wrapper --config config/fcrepo_wrapper_test.yml`
3. Run `rspec` and verify that all tests pass


A second option, which has not been working consistently for local testing, is running the test suite with `bin/rails ci`.

For our CI we are using CircleCI that we adopted from hyrax project: [Hyrax CircleCI Config](https://github.com/samvera/hyrax/blob/master/.circleci/config.yml)

# Caching manifests with localhost

In a development environment, rake task creates and caches manifests with
`base_url` as `localhost:3000`.

In order to run the rake task locally and see cached manifests properly,
please use port 3000 with localhost.
