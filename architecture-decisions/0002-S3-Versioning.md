# 2. S3 Versioning

* Status: Accepted
* Date: 2019-11-27

## Context
With versioning enabled on Fedora's S3 bucket, we have encountered difficulty uploading duplicate files, reading files in S3 back out
through Fedora, and accessing files through Cantaloupe. This manifests as 403 errors (Permission Denied),
despite AWS users having read and write permissions to the object versions in the bucket.

Versioning was turned on as a prerequesite for S3's cross-region replication, which we wanted so files in S3
would be present in two geographically separate regions.

## Decision
Disable versioning on our buckets, and develop automated S3 batch operations to replace the cross-region
replication feature.

The batch operations would:
1. Tag objects that need replication with the date that they are being replicated,
1. Copy these objects to the geographically separate bucket

Separately, all the files present in the system would be batch-tagged when a snapshot is made, with the date of
the snapshot. This prevents us from having to look for a range of replication tags when we are doing a restore.

## Consequences
Disabling versioning will disable automatic cross-region replication. It also means Fedora becomes responsible
for managing file versions.

Additional work is necessary to say whether this will solve our access problems with Cantaloupe.

## Alternatives

### This is an alternative.
Keep S3 versioning enabled.
- PRO: Cross-region replication is an AWS feature, supported and maintained by AWS resources. Other
  outcomes require Emory support.
- CON: Requires more application configuration. Uploading duplicate files currently does not work, and
  Cantaloupe's status is unknown.
- CON: Peers do not appear to be using S3 versioning.
