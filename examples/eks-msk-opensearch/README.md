## Multi-Tenant logging using Fluent-bit, EKS , Amazon MSK and  Amazon OpenSearch

* Let us start by explaining some of the key terms we will refer throught the solution .
* 
* * Tenant - A tenant will be used to refer to a seperate deployment of microservices/pods **
* * Broker - A broker is a software services to decouple publisher and consumers. In generic terms it will be our message queue which will store the log messages before these are sent for visulaization. **
* * MSK - It refers to Amazon Managed Service for Kafka ( Our broker in this case) **
* * Terraform - It's hasrhcorp tool to defind infrastructure as a code **

In this example, we will showcase how to send your application logs from EKS to OpenSearch via Amazon MSK (managed KAFKA). 

We will use tenant(an isloated deployment of microservices/pods) notion using Kubernetes namespace so that each tenant has a seperate namespace.  The solution helps to meet following use cases in a multi-tenant deployment from EKS cluster.


* Use of a broker to de-couple sending logs directly to OpenSearch so that broker can store logs if the OpenSearch is not available or having  some issues. In this example we will use Amazon MSK to store our logs.

* Fan out logs to multiple destinations. We can use KAFKA consumers or Connectors to send logs from your Pods to different destinations of your choice such as S3 or CloudWatch Logs. So Kafka can act as a Fan-Out source of your application logs.

* Seperate KAFKA topics for each tenant to achieve tenant's log Isolation(logs in seperate topics) and KAFKA sink connector will then send logs to OpenSearch creating unique INDEX per topic, hence giving tenant isolation at OpenSearch also.

To achieve this we will use "fluent-bit" to collect logs from your pods. Fluent-bit is a lightweight, and highly scalable logging and metrics processor and forwarder and can be used for kubernetes workloads  to send logs to many supported destniations like CloudWatch Logs, S3 and  OpenSearch. Fluent bit uses following notions to process logs.

* INPUT to define How to collect data/events.
* FILTER to modify data to add/remove fields or enrich fields.
* OUTPUT to configure plugins to forward logs to endpoints like S3,CloudWatch etc. In our example we will use 'KAFKA' OUTPUT plugin.

Here in our case , Fluent Bit will run as a Kubernetes DaemonSet on your EKS cluster to tail /var/log/containers/*.log on the EKS cluster and use grep FILTER to process logs for configured namespaces.

We have a fluent-bit template in "template" directory, which terraform will use to generate a run-time config from the configuration values of namespaces,brokers etc.

Also note that Fluent bit configuration file has a Lua script FILTER  which is used to set topic names for KAFKA topics such that each tenant/namespace will have a corresponding unique topic "logs_<namespace>". This gives our topics a unique name if KAFKA broker is being used/shared between more than many applications.

To consume these logs from KAFKA and send to OpenSearch , we are using KAFKA connector for OpenSearch to Opensearch such that each namespace(tenant) will have one Index.

The terraform code in terraform directory which will create an EKS cluster, MSK cluster, Kafka custom plugin,MSK Connector for OpenSearch  and OpenSearch domain in VPC.

Reference Architecure ![Architecture](Ref-Architecture.png?raw=true "Title")


#### Pre-requisites

* . A S3 bucket for terraform backend
* . IAM permissions to create resources(VPC/S3 bucket/EKS Cluster/MSK Brokers/OpenSearch Domain). A Administrator access IAM role is recommended.
* . Install kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) and kafka clients binaries to verify your KAFKA brokers (optional) on a machine which can access your EKS cluster and MSK Cluster.


* Note. Terraform code will create VPC and all required components. But your OpenSearch dashboard will not be accessible over internet, so you might consider using a AWS client VPN ( or any connectivity method to allow you access to dashboard). you can also launch use a Microsoft windows instance in same VPC and access it via RDP to access your OpenSearch dashboard 

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

* Follow terraform instructions from section below ,terraform will create EKS cluster,MSK cluster and OpenSearch domain and MSK Connector for Kafka. Also it will create/install EKS components like namespace/fluent-bit daemonset.

1. run 
```
terraform init
terraform apply

```
Terraform apply will ask you for OpneSearch domain master password which you will later use to login to OpneSearch Dashboard. Note it down and keep it safe.

* Wait for terraform to complete 
2. Now let us Deploy a sample nginx pod and service  in 'example' namespace. The deployment will help us to generate some logs for samples.
```
kubectl config set-context --current --namespace=example
kubectl apply -f example-deployment.yaml
kubectl get svc nginx-service-loadbalancer

```
* Note down the name of LoadBalancer and copy it in your browser and hit it few times to generate access logs.

3. Login to machine which has KAFKA client binary are installed and list KAFKA topics to verify logs_example and logs_logging topics are created and logs are sent to them.
 
```
./bin/kafka-topics.sh --bootstrap-server=<<list of your brokers>>  --list
./bin/kafka-console-consumer.sh --bootstrap-server <<list of your brokers>. --topic logs_example    

```
4. Login to your OpenSearch Dashboard as admin and verify the indexes are created for each of namespace enabled to log to OpenSearch. 


* If you have applications requiring different parsers for your pods, Fluent-bit allows you to choose your parser. Annotate your pods with following to choose your parser.
```
fluentbit.io/parser: <parser-name>
```
* If you want to completely opt out of logging for any of your pods. Use

```
fluentbit.io/exclude: "true"
```
    
 **Configure Multi-tenancy on OpenSearch**
    
 Logs being sent to OpenSearch with above mentioned approach will create unique indexes with the same name of logs_<namespace> name. That gives OpenSearch/Organisation adminstrators capability to create tenant,roles with required permission on Indexes and assign to OpenSearch users.
    
Please follow the reference blog below to achieve this with OpenSearch.
https://aws.amazon.com/blogs/apn/storing-multi-tenant-saas-data-with-amazon-opensearch-service/


