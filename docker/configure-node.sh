#!/bin/bash

set -x
set -m

IP=`hostname -I | cut -d ' ' -f1`
echo "IP: " $IP

/entrypoint.sh couchbase-server &

echo "Type: $TYPE"

# TODO: wait for a notification that couchbase is ready
sleep 15

# Initialize Node
curl  -u Administrator:password -v -X POST http://127.0.0.1:8091/nodes/self/controller/settings \
  -d 'data_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata& \
  index_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata'

case "$TYPE" in
"MASTER")
    echo "Rename Node"
    curl  -u Administrator:password -v -X POST http://127.0.0.1:8091/node/controller/rename \
      -d "hostname=$IP"

    echo "Setup index and memory quota"
    curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300

    echo "Setup Services"
    curl  -u Administrator:password -v -X POST http://127.0.0.1:8091/node/controller/setupServices \
      -d 'services=kv%2Cn1ql%2Cindex%2Cfts'

    echo "Setup Administrator username and password"
    curl  -u Administrator:password -v -X POST http://127.0.0.1:8091/settings/web \
      -d 'password=password&username=Administrator&port=SAME'

    # Setup Bucket
    #curl  -u Administrator:password -v -X POST http://127.0.0.1:8091/pools/default/buckets \
    #  -d 'flushEnabled=1&threadsNumber=3&replicaIndex=0&replicaNumber=0& \
    #  evictionPolicy=valueOnly&ramQuotaMB=597&bucketType=membase&name=default& \
    #  authType=sasl&saslPassword=password'

    # Load travel-sample bucket
    #curl -v -X POST -u 'Administrator:password' 'http://localhost:8091/sampleBuckets/install' -d '["travel-sample"]'
    ;;

"WORKER")
  echo "add server to cluster"
  curl -u Administrator:password \
    $COUCHBASE_MASTER:8091/controller/addNode \
    -d "hostname=$IP&user=Administrator&password=password&services=kv%2Cn1ql%2Cindex%2Cfts"

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    couchbase-cli rebalance --cluster=$COUCHBASE_MASTER:8091 --user=Administrator --password=password
  fi;
  ;;
esac

fg 1
