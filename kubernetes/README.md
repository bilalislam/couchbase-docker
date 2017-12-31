# Cluster using Kubernetes

## Start Minikube

eval $(minikube completion bash) && minikube start --docker-opt="default-ulimit=nofile=500000:500000" && minikube dashboard --url


## Create Master RC
```
kubectl create -f master-service.yml
```

You can now access the Couchbase Web Console using
(if you are not shown a user/password prompt then please wait until completed initializing)
```
minikube service --url couchbase-service
```

## Create Worker RC
```
sed -e "s/SERVICE_IP_OF_MASTER/$(kubectl get po -l app=couchbase-master-pod -o wide | tr -s ' ' | grep couchbase-master-controller- | cut -d " " -f 6)/" worker-service.yml | kubectl create -f -
```

## Scale cluster
```
kubectl scale --replicas=3 rc/couchbase-worker-controller
```
