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
