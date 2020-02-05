## Fluent Bit and AWS App Mesh

In this example, we will showcase how to parse the Envoy access logs for AWS App Mesh in an Amazon EKS cluster. To achieve this, we will deploy Fluent Bit as a DaemonSet to tail /var/log/containers/*.log on the EKS cluster and forward to CloudWatch.

#### Prerequisites

* An EKS Cluster with the appropriate IAM Roles attached to the worker nodes for App Mesh and CloudWatch. This can easily be achieved by standing up a cluster with [eksctl](https://eksctl.io/usage/iam-policies/) and adding the appropriate IAM add-on policies.

* Enable [App Mesh Integration](https://docs.aws.amazon.com/app-mesh/latest/userguide/mesh-k8s-integration.html) on the cluster.

* Set up the [Color App](https://docs.aws.amazon.com/app-mesh/latest/userguide/deploy-mesh-connected-service.html) as described in the AWS App Mesh Documentation. We will edit deployment below.

#### Instructions

* To get started, create the Namespace that's needed for the the Fluent Bit components.
```
kubectl apply -f logging-ns.yaml
```
* Deploy the Fluent Bit DaemonSet.
```
kubectl apply -f fluent-bit/
```
* Deploy the Color App.
1. There is a file called [color.yaml](color-app/color.yaml) which is the same manifest that's used in the [Color App](https://docs.aws.amazon.com/app-mesh/latest/userguide/deploy-mesh-connected-service.html) from the AWS App Mesh Documentation in the prerequisites. However, it's been slightly modified to emit the colorteller-black Envoy access logs to `/dev/stdout` and also adds an annotation of `fluentbit.io/parser: envoy` to the colorteller-black container. This annotation suggests that the data should be processed using the pre-defined parser called envoy which is defined in the [fluent-bit-configmap.yaml](fluent-bit/fluent-bit-configmap.yaml). This configuration is how we will wire up Fluent Bit to parse the Envoy access logs for App Mesh. Please see this [link](https://docs.fluentbit.io/manual/filter/kubernetes) for more info on pre-defined parsers in Fluent Bit.
```
kubectl apply -f color-app/color.yaml
``` 
2. You should already have a curler container if you followed the Color App instructions from the prerequisites. Exec into the curler container and rerun the below:
```
for i in {1..100}; do curl colorgateway:9080/color; echo; done
```
3. View the colorteller-black logs in CloudWatch. The Envoy access logs should now be parsed like the example below:
```
{
    "kubernetes": {
        "annotations": {
            "fluentbit.io/parser": "envoy",
            "kubernetes.io/psp": "eks.privileged"
        },
        "container_hash": "b10687cb4b94ef7aecc0c6e815efb56c8d8889db5316bafc42477acd908a0e91",
        "container_name": "envoy",
        "docker_id": "3be97d47d717ae3ba9937d1bd58b683cdb8b24bd5c66cf7fefeb2ee47c808b08",
        "host": "ip-192-168-10-112.ec2.internal",
        "labels": {
            "app": "colorteller",
            "pod-template-hash": "d868b5bc9",
            "version": "black"
        },
        "namespace_name": "appmesh-demo",
        "pod_id": "42336070-4796-11ea-ac15-0278ee4c2031",
        "pod_name": "colorteller-black-d868b5bc9-zwz28"
    },
    "log": "[2020-02-05T16:37:27.958Z] \"GET / HTTP/1.1\" 200 - 0 5 0 0 \"-\" \"Go-http-client/1.1\" \"6c6ae4b8-60ac-98b6-ba32-a3a4a5c938bf\" \"colorteller.appmesh-demo:9080\" \"127.0.0.1:9080\"\n",
    "log_processed": {
        "authority": "colorteller.appmesh-demo:9080",
        "bytes_received": "0",
        "bytes_sent": "5",
        "code": "200",
        "duration": "0",
        "method": "GET",
        "path": "/",
        "protocol": "HTTP/1.1",
        "request_id": "6c6ae4b8-60ac-98b6-ba32-a3a4a5c938bf",
        "response_flags": "-",
        "start_time": "2020-02-05T16:37:27.958Z",
        "upstream_host": "127.0.0.1:9080",
        "user_agent": "Go-http-client/1.1",
        "x_envoy_upstream_service_time": "0",
        "x_forwarded_for": "-"
    },
    "stream": "stdout",
    "time": "2020-02-05T16:37:33.976469719Z"
}
```


