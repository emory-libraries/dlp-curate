# 4. IIIF Manifest Caching

* Status: Accepted
* Date: 2020-03-06

## Context
Hyrax by default does not cache IIIF manifests, which take a considerable about of time to create. The amount of time depends on the number of filesets present in the work, because Hyrax queries Fedora for each of them. For our books, there could be hundreds of pages, meaning the manifest will take minutes to generate. Lux however, does not have minutes to wait for a manifest, and will time out before the manifest is ready.

## Decision
We will save manifests as they are generated with the id of the work and the datetime the last time the work was updated to a folder that will persist through deployments to a given environment. The location of the folder will be controlled by ENV variable, and should have a sensible default. This cache will be queried before generating the manifest again, and if one is found, the cached version will be served. Additionally, we will create a rake task to generate manifests for works that do not have them. Finally, we will create another rake task to delete manifests that are no longer needed, so the cache does not grow unbounded.

## Consequences
We will know this is successful if book objects in Lux do not timeout when fetching the manifest from Curate.

One drawback to this approach is that we will have to pay for the disk space that the manifests take up. However, implementing this solution should be quicker and more straight-forward than the alternatives.

Taking this apprach does not stop us from refactoring manifest generation code in the future.

## Alternatives

### No Caching
In order for us to not need caching, we would have to drastically change the way the manifests are generated.
- PRO: We would not have to pay to store manifests.
- PRO: We would not have to clean up stale manifests.
- CON: No refactoring would match the speed of caching.
- CON: We would be responsible for the new code, greatly increasing the area of code we have to maintain.
- CON: May complicate upgrades.
- CON: Rewriting that much functionality would take longer than the solution above.

### ETags
We could attempt to add etags to manifests, and ask Apache to cache them.
- PRO: We would not have to clean up stale manifests
- CON: Caching with Apache is less well understood to implementing the caching rules ourselves.
- CON: It is unclear if we could prepopulate this.
