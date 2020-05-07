# 5. Route 53 Hosted Zone

* Status: Accepted
* Date: 2020-05/07/2020

## Context

The initial design of the DLP Project called for all server to server communication (e.g. Curate to Fedora) to go through an application load balancer (ALB). This proved unfeasible for the fedora to curate communication because the traffic caused 503 errors on the ALB. Middleware decided to avoid ALB for curate communications to fedora, iiif (Cantaloupe), and solr. Later on, solr traffic was redirected through the ALBs to enable load balancing of the solr cloud instances. Eventually iiif may be load balanced as well.

To avoid the ALB the servers need direct communication. Since Route 53(AWS DNS) was completely disabled at the time, and since servers are often destroyed and rebuilt, each time with a new private IP address, Middleware developed an Ansible playbook that would insert a block of IP address into the /etc/hosts file of each server in a group. This was an extension of a solr cloud play that writes the IPs of the other solr cloud instances of a group. This setup worked without issue for months until a production solr instance had a corruption of its hosts file. This caused it to drop out of the cluster and fail. Additionally, at some point Route 53 private hosted zone was enabled in DLP's aws@emory account.

## Decision

Use Route 53 to create a private hosted zone of .internal.emory.edu and have each instance in the DLP account register an A record on creation of the EC2.

## Consequences

The .env files of curate will point at the internal.emory.edu address for fedora and iiif. Fedora, iiif and Solr add *.internal.emory.edu as a ServerAlias, the solrs will need additional changes to their SOLR_HOST and ZK_HOST variables, and the zookeeper config must be changed to use the internal.emory.edu hostname instead of an IP address value.

EC2 must re-register their new A-record on creation, so that Route 53 always has the latest ip address.

## Alternatives

### Continue using hosts file

* PRO: Arguably simpler setup because it avoid the need to use another AWS service.
* CON: Vulnerable to hosts file corruption or changes.
* CON: Complicates new EC2 creation.
