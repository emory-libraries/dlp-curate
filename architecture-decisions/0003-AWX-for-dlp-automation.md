# 3. AWX-for-dlp-automation

* Status: Accepted
* Date: 2020-03-05

## Context
The team has been developing Ansible roles for a wide variety of issues. They govern everything from building the EC2s to backing up individual components of DLP. We need a neutral platform to run these roles on. This platform would need to be able to run the playbooks on demand or scheduled. RedHat provides two solutions: AWX and Ansible Tower. 

## Decision
AWX is the upline, free version of Ansible Tower. It is available primary as docker images. AWX is capable of running playbooks as required.

## Consequences
Since AWX runs in docker, some knowledge of docker will need to be developed by the team.

AWX is not supported officially by Red Hat, they support only the offcial paid version Ansible Tower. 

## Alternatives
This section briefly outlines the alternatives we could have taken, with PRO's and CON's.

### Use Ansible Tower

- PRO: Officially supported by Red Hat
- PRO: Does not require docker knowledge
- CON: Licensing scheme is inventory based
