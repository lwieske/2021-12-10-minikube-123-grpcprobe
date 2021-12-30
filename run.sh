#!/usr/bin/env bash

minikube start \
    --kubernetes-version=v1.23.0 \
    --container-runtime=containerd \
    --feature-gates=GRPCContainerProbe=true \
    --driver=hyperkit

sleep 60

set +x
echo "################################################################################"
echo "### gRPC liveness probe"
echo "################################################################################"
set -x

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: etcd-with-grpc
spec:
  containers:
  - name: etcd
    image: k8s.gcr.io/etcd:3.5.1-0
    command: [ "/usr/local/bin/etcd", "--data-dir",  "/var/lib/etcd", "--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc:
        port: 2380
      initialDelaySeconds: 10
EOF

sleep 60

kubectl describe pod etcd-with-grpc

sleep 20

kubectl delete pod etcd-with-grpc

sleep 3

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: etcd-with-grpc
spec:
  containers:
  - name: etcd
    image: k8s.gcr.io/etcd:3.5.1-0
    command: [ "/usr/local/bin/etcd", "--data-dir",  "/var/lib/etcd", "--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc:
        port: 2379
      initialDelaySeconds: 10
EOF

sleep 60

kubectl describe pod etcd-with-grpc

sleep 20
