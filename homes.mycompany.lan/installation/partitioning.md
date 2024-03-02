# Partitioning


As I'm walking through this project I'm working with virtual machines hosted on my home nas, which does not allow me to create
partitions for my virtual drives. I will however elaborate a possible partition strategy for this server.


Let's say our home export server supports 1TB of storage, and 16GB of RAM.

We want it to be able to accomodate at least 10 homes per department, with a hard quota of 25GB each.
This brings the minimum required homes space to a total of 500GB

Since this server will solely provide a home export service, there won't be any need to have more than 10GB for the root partition.

Because this service won't be RAM intensive, we shouldn't have to worry too much about memory swapping. However, since we are working with a lot of storage,
we might as well allocate some storage for a swap partition. We'll calculate this partition with the classical method, which brings us to 24GB.

The auth process will be handled by the kdc server, so there won't be any need to allocate a local partition for the users database.

We will reserve another 20GB for generic logging.


This brings our partitioning scheme to:
```
/:                          10GB
/homes/sales:               250GB
/homes/customercare:        250GB
/var/log:                   20GB
/swap:                      24GB
```

This brings us to 554GB out of the available 1TB. 
We could take into account that in the future we might have to support an extra department with equal storage needs.
Taking that into account, maximizing the number of homes per department we obtain
```
/:                          10GB
/homes/sales:               300GB
/homes/customercare:        300GB
/var/log:                   20GB
/swap:                      24GB
```

If one day we need to add an extra department we can allocate 300GB to it, bringing the total storage to 954GB.
Otherwise we can decide to dynamically grow the two original departments based on our needs.
