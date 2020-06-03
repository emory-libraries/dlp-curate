# 5. Route 53 Hosted Zone

* Status: Accepted
* Date: 2020-05-07

## Context

Servers are often destroyed and rebuilt with a new private IP address, so a block of IP addresses is added into the `/etc/hosts` file of each server in a group when one is provisioned.
This was an extension of work done for Solr Cloud that writes the IPs of the other Solr Cloud instances of a group.
Recently, a Solr server experienced corruption of it's `/etc/hosts` file, which caused the instance to drop out of the cluster.

Fedora produces 503 errors when under load, primarily during Curate imports.
This causes the background jobs associated with the imports to go into retries, and sends error notifications to Honeybadger.
Sometimes, the jobs do not succeed when they are retried, causing DPS team members to have to fix the affected works manually.

Our theory at the moment is that something about using `/etc/hosts` (rather than a centralized DNS solution like AWS's Route 53) is the cause of Fedora's errors.

Route 53, was blocked by AWS@Emory at the time the DLP project started, but has since been enabled.

## Decision

Avoid using `/etc/hosts` for server-to-server communication by setting up DNS for our servers, using a Route 53 private hosted zone (.internal.emory.edu).
Point the .env files of Curate to the internal.emory.edu address for Fedora and IIIF.
Add <service>.internal.emory.edu as a ServerAlias for Fedora, IIIF, and Solr.
Change the SOLR_HOST and ZK_HOST variables for Solr instances.
Use the internal.emory.edu hostname for Zookeeper config, instead of an IP address value.

## Consequences
All EC2s must re-register their new A-record in Route 53 when they are created, so that Route 53 always has the latest IP address.

## Alternatives

### Continue using hosts file

* PRO: Arguably simpler setup because it avoid the need to use another AWS service.
* CON: Vulnerable to hosts file corruption or changes.
* CON: Complicates new EC2 creation.
