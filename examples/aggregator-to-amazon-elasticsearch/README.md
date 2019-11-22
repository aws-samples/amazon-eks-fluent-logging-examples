## Aggregator To Amazon Elasticsearch

In this example, we deploy Fluent Bit as a DaemonSet to tail /var/log/containers/*.log on an EKS cluster and forward to a FluentD aggregator running as a Service/Deployment which forwards to Amazon Elasticsearch.

#### Prerequisites

* An [Amazon Elasticsearch](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html) domain configured with [Amazon Cognito Authentication for Kibana](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-cognito-auth) and the appropriate [Access Policy](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies).

#### Instructions

* To get started, take a look at the [Dockerfile](Dockerfile) which builds a Docker Image with [fluent-plugin-aws-elasticsearch-service](https://github.com/atomita/fluent-plugin-aws-elasticsearch-service). You will need to build this image and push it to something like ECR or DockerHub.
* Create the Namespace
```
kubectl apply -f logging-ns.yaml
```
* Deploy the FluentD aggregator. Be sure to edit `AWS_ES_URL` and `AWS_ES_REGION` in fluentd container environment variable in the yaml.
```
kubectl apply -f fluentd/fluentd.yaml
```
* Deploy the Fluent Bit DaemonSet
```
kubectl apply -f fluent-bit/
```
* Deploy the sample-apps. 
1. There is a file called [nginx-fluentbit.yaml](sample-apps/nginx-fluentbit.yaml) which showcases the ability to utilize an annotation by specifying `fluentbit.io/parser: nginx`. This annotation suggests that the data should be processed using the pre-defined parser called nginx. The parser must be registered already by Fluent Bit. Please see this [link](https://docs.fluentbit.io/manual/filter/kubernetes) for more info.
```
kubectl apply -f sample-apps/nginx-fluentbit.yaml
```
2. There is a file called [apache-fluentd.yaml](sample-apps/apache-fluentd.yaml) which simply creates an Apache deployment and a service. The [fluentd.yaml](fluentd/fluentd.yaml) showcases how to specify a parser by specifying `<filter kube.var.log.containers.apache**>` in the ConfigMap.
```
kubectl apply -f sample-apps/apache-fluentd.yaml
```
* You will need to create an Index Pattern in Kibana and you can specify `logstash-*`
