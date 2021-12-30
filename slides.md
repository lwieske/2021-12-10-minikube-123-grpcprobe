---
marp: true
---

<!-- _class: invert -->

## Kubernetes Pods

* Pods are the smallest deployable units of computing in Kubernetes.

* A Pod (as in a pod of whales or pea pod) is a group of one or more containers,
  with shared storage and network resources, and a specification for how to run
  the containers.

* A Pod's contents are always co-located and co-scheduled, and run in a shared
  context.

* A Pod models an application-specific "logical host": it contains one or more
  application containers which are relatively tightly coupled.

---

## Init + Ephemeral Pods

* As well as application containers, a Pod can contain init containers that run
  during Pod startup.

* You can also inject ephemeral containers for debugging if your cluster offers
  this.

  * FEATURE STATE: Kubernetes v1.23 [beta]

---

## Liveness, Readiness and Startup Probes

* The kubelet uses **liveness probes** to know when to restart a container. For
  example, liveness probes could catch a deadlock, where an application is
  running, but unable to make progress.

* The kubelet uses **readiness probes** to know when a container is ready to
  start accepting traffic. A Pod is considered ready when all of its containers
  are ready.

* The kubelet uses **startup probes** to know when a container application has
  started. If such a probe is configured, it disables liveness and readiness
  checks until it succeeds, making sure those probes don't interfere with the
  application startup.

---

## Liveness Command

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

---

##  Liveness Command (II)

* In the configuration file, you can see that the Pod has a single Container.
  The periodSeconds field specifies that the kubelet should perform a liveness
  probe every 5 seconds. The initialDelaySeconds field tells the kubelet that it
  should wait 5 seconds before performing the first probe. To perform a probe,
  the kubelet executes the command cat /tmp/healthy in the target container. If
  the command succeeds, it returns 0, and the kubelet considers the container to
  be alive and healthy. If the command returns a non-zero value, the kubelet
  kills the container and restarts it.

* For the first 30 seconds of the container's life, there is a /tmp/healthy
  file. So during the first 30 seconds, the command cat /tmp/healthy returns a
  success code. After 30 seconds, cat /tmp/healthy returns a failure code.

---

## HTTP Liveness Probe

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/liveness
    args:
    - /server
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

---

## HTTP Liveness Probe (II)

* In the configuration file, you can see that the Pod has a single container.
  The periodSeconds field specifies that the kubelet should perform a liveness
  probe every 3 seconds. The initialDelaySeconds field tells the kubelet that it
  should wait 3 seconds before performing the first probe. To perform a probe,
  the kubelet sends an HTTP GET request to the server that is running in the
  container and listening on port 8080. If the handler for the server's /healthz
  path returns a success code, the kubelet considers the container to be alive
  and healthy. If the handler returns a failure code, the kubelet kills the
  container and restarts it.

* Any code greater than or equal to 200 and less than 400 indicates success. Any
  other code indicates failure.

---

## HTTP Liveness Probe (III)

```
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    duration := time.Now().Sub(started)
    if duration.Seconds() > 10 {
        w.WriteHeader(500)
        w.Write([]byte(fmt.Sprintf("error: %v", duration.Seconds())))
    } else {
        w.WriteHeader(200)
        w.Write([]byte("ok"))
    }
})
```

---

## TCP Liveness Probe

```
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: k8s.gcr.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
```

---

## TCP Liveness Probe (II)

* As you can see, configuration for a TCP check is quite similar to an HTTP
  check. This example uses both readiness and liveness probes. The kubelet will
  send the first readiness probe 5 seconds after the container starts. This will
  attempt to connect to the goproxy container on port 8080. If the probe
  succeeds, the Pod will be marked as ready. The kubelet will continue to run
  this check every 10 seconds.

---

## gRPC Liveness Probe

```
apiVersion: v1
kind: Pod
metadata:
  name: etcd-with-grpc
spec:
  containers:
  - name: etcd
    image: k8s.gcr.io/etcd:3.5.1-0
    command: [ "/usr/local/bin/etcd", \
                "--data-dir",  "/var/lib/etcd", \
                "--listen-client-urls", "http://0.0.0.0:2379", \
                "--advertise-client-urls", "http://127.0.0.1:2379", \
                "--log-level", "debug"]
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc:
        port: 2379
      initialDelaySeconds: 10
```

---

## gRPC Liveness Probe (II)

* FEATURE STATE: Kubernetes v1.23 [alpha]

* You must enable the GRPCContainerProbe feature gate in order to configure checks that rely on gRPC.

* Configuration problems are considered a probe failure, similar to HTTP and TCP probes.

---

## gRPC Liveness Probe Demo

<!-- _class: invert -->

```
kubectl apply -f https://k8s.io/examples/pods/probe/content/en/examples/pods/probe/grpc-liveness.yaml

sleep 15

kubectl describe pod etcd-with-grpc
```
