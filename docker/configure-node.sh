#!/bin/bash

set -x
set -m

IP=`hostname -I | cut -d ' ' -f1`
echo "IP: " $IP

/entrypoint.sh couchbase-server &

echo "Type: $TYPE"

echo "Waiting for Couchbase"
until $(curl --output /dev/null --silent --head --fail -u Administrator:password http://127.0.0.1:8091); do
    printf '.'
    sleep 1
done

# Initialize Node
curl  -u Administrator:password -v http://127.0.0.1:8091/nodes/self/controller/settings \
  -d 'data_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata& \
  index_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata'

case "$TYPE" in
"MASTER")
    echo "Rename Node"
    curl -v -u Administrator:password http://127.0.0.1:8091/node/controller/rename \
      -d "hostname=$IP"

    echo "Setup index and memory quota"
    curl -v http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300

    echo "Enable automatic failover"
    curl -v -u Administrator:password http://127.0.0.1:8091/settings/autoFailover \
        -d 'enabled=true&timeout=30'

    echo "Setup Services"
    curl -v -u Administrator:password http://127.0.0.1:8091/node/controller/setupServices \
      -d 'services=kv%2Cn1ql%2Cindex'

    echo "Set the Global Secondary Index Settings"
    curl -v -u 'Administrator:password' 'http://localhost:8091/settings/indexes' \
        -d 'indexerThreads=0' -d 'logLevel=info' -d 'maxRollbackPoints=5' -d 'memorySnapshotInterval=200' -d 'stableSnapshotInterval=5000' -d 'storageMode=memory_optimized'

    echo "Setup Administrator username and password"
    curl -v -u Administrator:password http://127.0.0.1:8091/settings/web \
      -d 'password=password&username=Administrator&port=SAME'
    ;;

"WORKER")
  echo "add server to cluster"
  curl -v -u Administrator:password \
    $COUCHBASE_MASTER:8091/controller/addNode \
    -d "hostname=$IP&user=Administrator&password=password&services=kv%2Cn1ql%2Cindex"

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    couchbase-cli rebalance --cluster=$COUCHBASE_MASTER:8091 --user=Administrator --password=password
  fi;
  ;;
esac

fg 1
