# DLP-Curate

<table width="100%">
<tr><td>
<img src="app/assets/images/EU_vt_280.png" width="200">
</td><td>
A repository application for digital curators (preservation, rights and metadata management, collection management). Find more about the project on our
<a href="https://wiki.service.emory.edu/display/DLPP"><em>DLP Wiki</em></a>
<br/><br/>

[![CircleCI](https://circleci.com/gh/emory-libraries/dlp-curate.svg?style=svg)](https://circleci.com/gh/emory-libraries/dlp-curate)
[![Coverage Status](https://coveralls.io/repos/github/emory-libraries/dlp-curate/badge.svg?branch=master)](https://coveralls.io/github/emory-libraries/dlp-curate?branch=master)
[![User Stories](https://raw.githubusercontent.com/ZenHubIO/support/master/zenhub-badge.png)](https://app.zenhub.com/workspaces/dlp-curate-5bf484ae4b5806bc2bf6875b)

</td></tr>
</table>

# Database Authentication

In a production environment, we will use Shibboleth for authentication. However, in a development environment we will be using a local database.

In order to set up your dev environment for database authentication, you will need to set the following environment variable:

`export DATABASE_AUTH=true`

# Testing and CI

Run the test suite with `bin/rails ci`

For our CI we are using CircleCI that we adopted from hyrax project: [Hyrax CircleCI Config](https://github.com/samvera/hyrax/blob/master/.circleci/config.yml)

# Caching manifests with localhost

In a development environment, rake task creates and caches manifests with
`base_url` as `localhost:3000`.

In order to run the rake task locally and see cached manifests properly,
please use port 3000 with localhost.
