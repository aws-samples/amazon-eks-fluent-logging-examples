# Centralized logging for multi-tenant applications on Amazon EKS

In this example, we will showcase how to build a centralized logging solution for multi-tenant environments where applications that belong to different teams or customers run in a shared Amazon EKS cluster.

## Components

Fluent Bit DaemonSet to collect, modify, and enrich logs from applications, and publish the logs to Amazon Managed Streaming for Kafka (Amazon MSK).

Amazon MSK to forward log events to various destination and as a buffering layer to avoid indexing pressure in Amazon OpenSearch. This layer will provide tenant isolation and improve resilience of the solution.

Amazon OpenSearch to monitor, visualize, and analyze logs. OpenSearch is a distributed, community-driven, Apache 2.0-licensed, 100% open-source search and analytics suite used for a broad set of use cases like real-time application monitoring, log analytics, and website search.

Terraform by HashiCorp, is an infrastructure as code tool similar to AWS CloudFormation to provision and manage infrastructure on AWS.

## Features

Security and compliance - This solution provides data isolation for logs ingested and stored so that each tenant can only access their own logs. It also can help you to meet your compliance requirements, for example anonymizing personally identifiable information (PII) in logs which is required by GDPR.

Business and technical insights -  You can produce business insights such as geographical distribution of customers or popularity of a product over time. Software engineers can also use this solution to troubleshoot an issue, or to create metrics and alarms to proactively notify the application owners of any issues.

Log routing - You can forward logs to various destinations for different purposes such as logs archival, cold logs analysis, and third party observability or security information and event management (SIEM) solutions such as Splunk or Datadog.

## Architecture

![Architecture](Ref-Architecture.png?raw=true "Title")

### Fluent Bit config

In this example, we used the Lua filter plugin to add a key `namespace` with value of Kubernetes namespace name prefixed by `logs_`. This key is subsequently used in the Kafka output plugin to define Kafka topic name dynamically. Therefore, all logs belong to a Kubernetes namespace will be grouped by a Kafka topic.

## Prerequisites

* An Amazon S3 bucket as a Terraform backend to store Terraform state data files.
* An IAM role, or an IAM user principal with required privileges to create resources such as Amazon VPC, Amazon S3 bucket, Amazon EKS cluster, Amazon MSK cluster, and Amazon OpenSearch cluster.
* The following tools installed on a machine.
  * Kubectl - for more information, see [Installing or updating kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html).
  * Terraform - for more information, see [Installing Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
  * Optionally, Apache Kafka client libraries and tools - for more information, see [Create a topic](https://docs.aws.amazon.com/msk/latest/developerguide/create-topic.html).

## Instructions

* Clone the repository

```bash
git clone https://github.com/aws-samples/amazon-eks-fluent-logging-examples.git
```

* CD into terraform directory

```bash
cd amazon-eks-fluent-logging-examples/examples/eks-msk-opensearch/terraform
```

**Note**. Terraform code will create VPC and all required components.But your OpenSearch dashboard will not be accessible over internet, so you might consider using a AWS client VPN/RDP access to a windows EC2 instance (or any connectivity method to allow you access to dashboard).

#### Instructions
* Clone the repository.
* cd into amazon-eks-fluent-logging-examples/examples/eks-msk-opensearch/terraform.
* To get started, edit 0-proivder.tf to update backend S3 bucket , region and key prefix.
* [Optional] Edit 3-variables.tf to create/edit more namespaces and enable logging on them. In this example we are creating two namespaces. "enable_logs_to_es" is a boolean value which when tru will enable logging for the namespace.
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

1. Run following terraform commands to create infrastructure. 
```
terraform init
terraform apply

```
Terraform apply will ask you for OpenSearch domain master password which you will later use to login to OpenSearch Dashboard.Note it down and keep it safe.

2. Deploy a sample nginx pod and service in 'example' namespace.The deployment will help us to generate some logs for samples.
```
kubectl config set-context --current --namespace=example
kubectl apply -f example-deployment.yaml
kubectl get svc nginx-service-loadbalancer

```
* Note down the name of loadBalancer and copy it in your browser and hit it few times to generate access logs.

3. Login to machine which has KAFKA client binary are installed and list KAFKA topics to verify logs_example topic is created.Use following commands to verify your topics and messages in topic.
 
```
./bin/kafka-topics.sh --bootstrap-server=<<list of your brokers>>  --list
./bin/kafka-console-consumer.sh --bootstrap-server <<list of your brokers> --topic logs_example    

```
4. Login to your OpenSearch Dashboard as admin and verify the indexes are created for each of namespace enabled to log to OpenSearch. 


* If you have applications requiring different parsers for your pods,fluent-bit allows you to choose your parser.Annotate your application pods with following annotation to choose your parser.
```
fluentbit.io/parser: <parser-name>
```
* If you want to completely opt out of logging for any of your pods.Use following annotation.

```
fluentbit.io/exclude: "true"
```
    
 **Configure Multi-tenancy on OpenSearch**
    
Logs being sent to OpenSearch with this solution will create unique indexes with the same name of logs_<namespace> name.That gives OpenSearch/Organisation adminstrators capability to create tenants,roles with required permission on Indexes and assign to OpenSearch users.
    
Please follow the reference blog below to achieve this with OpenSearch.
https://aws.amazon.com/blogs/apn/storing-multi-tenant-saas-data-with-amazon-opensearch-service/


