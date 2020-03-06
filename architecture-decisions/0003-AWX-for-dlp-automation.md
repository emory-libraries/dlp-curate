# 3. AWX For DLP Automation

* Status: Accepted
* Date: 2020-03-07

## Context

The Middleware team has strived to practice Infrastructure-As-Code, meaning DLP's AWS account should be reflected entirely within github. This has mostly been accomplished but Ansible playbooks are currently ran in Ansible Core on individual laptops of the Middleware team. The eventual goal should be *GitOps*, automated infrastructure changes triggered by a commit. For that purpose we will need a platform capable of running playbooks automatically. This platform would need to be able to run the playbooks on demand or scheduled. RedHat provides two solutions: AWX and Ansible Tower. AWX is the upline of Ansible Tower, meaning it is a more advanced version that lacks official support.

## Decision

AWX is the best choice to manage DLP's automation needs.

## Consequences

Since AWX runs in docker, knowledge of docker images, specifically how to set them up and how to update them, will need to be developed by the Middleware team. Shibboleth integration will be needed. Additionally the creation of LDAP groups to manage access to AWX for administrators and developers is required. LDAP groups require group managers.

## Alternatives

This section briefly outlines the alternatives we could have taken, with PRO's and CON's.

### Use Ansible Tower

* PRO: Officially supported by RedHat
* PRO: Does not require docker knowledge
* CON: Licensing scheme is inventory based

### Continue Using Ansible Core

* PRO: No changes needed, low overhead
* PRO: Simpler setup for cor-cm
* CON: Increase dependencies on individual computers
* CON: Automation severely limited with Ansible Core

### Use Jenkins and AWX

* PRO: Using Jenkins to orchestrate, AWX to execute is a popular setup
* PRO: Jenkins may be a better tool for CloudFormation
* CON: Increases complexity, AWX can also orchestrate
