# Couchbase Docker Image

This directory shows how to build a custom Couchbase Docker image that:

- Setups memory for Index and Data
- Configures the Couchbase server with Index, Data, and Query service
- Sets up username and password credentials

## Build the Image Locally

```console
eval $(minikube docker-env) && docker build -t cosmic/couchbase .
```
