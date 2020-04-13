# 3. AWX For Infrastructure Automation

* Status: Accepted
* Date: 2020-04-01

## Context

The Middleware team has strived to practice Infrastructure-As-Code, meaning DLP's AWS account should be reflected entirely within GitHub.
This has mostly been accomplished but Ansible playbooks are currently run in Ansible Core on individual laptops of the Middleware team.
The eventual goal should be GitOps, automated infrastructure changes triggered by a commit.
For that purpose we will need a platform capable of running playbooks automatically.
This platform would need to be able to run the playbooks on demand or scheduled.
RedHat provides two solutions: AWX and Ansible Tower.
AWX is the upline of Ansible Tower, meaning it is a more advanced version that lacks official support.

## Decision

The Middleware team will use AWX to manage DLP's infrastructure automation needs.
A different tool may be used for application automation.

## Consequences

Since AWX runs in Docker, knowledge of Docker images, specifically how to set them up and how to update them, will need to be developed by the Middleware team.
Shibboleth integration will be needed.
Additionally the creation of LDAP groups to manage access to AWX for administrators and developers is required, and LDAP groups require group managers.

## Alternatives

This section briefly outlines the alternatives we could have taken, with PRO's and CON's.

### Use Ansible Tower

* PRO: Officially supported by RedHat
* PRO: Does not require Docker knowledge
* CON: Licensing scheme is inventory based

### Continue Using Ansible Core

* PRO: No changes needed, low overhead
* PRO: Simpler setup for cor-cm
* CON: Increase dependencies on individual computers
* CON: Automation severely limited with Ansible Core

### Use Jenkins and AWX

* PRO: Using Jenkins to orchestrate, AWX to execute is a popular setup
* CON: Increases complexity, AWX can also orchestrate

### Use Capistrano

* PRO: Simpler setup, no additional tool needed
* CON: Would still need to provision a server to automatically run capistrano tasks
* CON: Would require writing a large number of custom capistrano tasks
