# Couchbase on Minikube

Example of setting up Couchbase running on [minikube](https://github.com/kubernetes/minikube).

# Build Couchbase Docker Image

See README.md in docker directory.

# Start Vouchbase Master and Worker nodes

See README.md in kubernetes directory.

## Example database setup

# Load travel-sample bucket
```
curl -v -u 'Administrator:password' "$(minikube service --url couchbase-webconsole-service)/sampleBuckets/install" \
    -d '["travel-sample"]'
```

# Optional: High availability with replicas

```
curl -v -u 'Administrator:password' "$(minikube service --url couchbase-webconsole-service)/pools/default/buckets/travel-sample " \
    -d replicaNumber=2 
```

# Example: Create Memory-Optimized Global Index
```
curl -v -u 'Administrator:password' "$(minikube service --url couchbase-query-service)/query/service" \
    -d 'statement=CREATE INDEX country_index ON `travel-sample`( country ) 
                  WITH {"num_replica": 2};'
```
