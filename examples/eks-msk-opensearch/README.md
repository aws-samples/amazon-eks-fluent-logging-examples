## Multi-Tenant logging using Fluent-bit, EKS , Amazon MSK and  Amazon OpenSearch

In this example,we will showcase how to use EKS's namespace as for tenant's isolation and forward logs AMazon Managed Service for Kafka to store and Finally to OpeneSearch. To achieve this, we will deploy Fluent Bit as a DaemonSet to tail /var/log/containers/*.log on the EKS cluster and use fluent-bit annotations to configure desired parser for services in each tenant's namespace.It will create one topic for each tenant in KAFKA and a MSK connector for OpenSearch to send these logs to OpenSearch such that each tenant will have one Index. In the end there is a link to OpenSearch multi-tenancy configuration using RBAC .

Terraform code will help you to create an EKS cluster, MSK cluster, Kafka custom pluging ,Kafka Connector  and OpenSearch domain in one VPC.

#### Prerequisites

* . A S3 bucket for terraform backend
* . Access to call AWS API ( you can use AWS cloud9 IDE) or from your local machine after configuration credentials 
* . A EC2 instance  which can access your KAFKA brokers and have kafka client binary downloaded.

#### Instructions

* To get started, edit 0-proivder.tf to update backend S3 bucket , region and key prefix.

* Terraform will install fluent-bit in logging namespace and also create a example namespace.

* Refer to 3-variables.tf to create/edit more namespaces and enable logging on them.
```
default = [
    {
      "name" : "logging",
      "enable_logs_to_es" = false,
    },
    {
      "name" : "example",
      "enable_logs_to_es" = true,
```
* Note. Terraform code will create VPC and all required components. But your OpenSearch dashboard will not be accessible over internet, so you might consider using a AWS client VPN ( or any connectivity method to allow you access to dashboard). you can also launch use a Microsoft windows instance in same VPC and access it via RDP and then access your OpenSearch dashboard 

1. run 
```
terraform init

```


* Wait for terraform to complete 
2. Deploy a sample nginx pod and service  in 'example' namespace.
```
kubectl config set-context --current --namespace=example
kubectl apply -f example-deployment.yaml
kubectl get svc nginx-service-loadbalancer

```
* Note down the name of LoadBalancer and copy it in your browser and hit few times to generate access logs.

3. Login to EC2 instance which have KAFKA client binary are installed and   list KAFKA topics to verify logs_example and logs_logging topics are created and logs are sent to them.
 
```
./bin/kafka-topics.sh --bootstrap-server=<<list of your brokers>>  --list
./bin/kafka-console-consumer.sh --bootstrap-server <<list of your brokers>. --topic logs_example    

```
4. Login to your OpenSearch Dashboard as admin and verify the indexes are created for each of namespace enabled to log to OpenSearch. 


* Fluent-bit allows you to choose your parser. Annotate your pods with following to choose your parser.
   ```
      fluentbit.io/parser: apache
   ```
* If you want to completely opt out of logging for any of your pods. Use

```
fluentbit.io/exclude: "true"

```
* To configure and use RBAC with OpenSearch , you can follow instructions from https://aws.amazon.com/blogs/apn/storing-multi-tenant-saas-data-with-amazon-opensearch-service/


