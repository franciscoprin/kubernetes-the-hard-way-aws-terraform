# Kubernetes Cluster with Terraform and AWS

This repository contains Terraform configuration files to create a Kubernetes cluster on AWS. The cluster is provisioned using Terraform, and it leverages AWS services for infrastructure management.


```mermaid
flowchart LR
    subgraph Border
        subgraph AWS["<i class='fab fa-aws' style='font-size:25px;margin-top:5px;color:#FF8C00;'></i>"]
            iam-role["<img class='S3Icon' src='https://symbols.getvecta.com/stencil_23/20_iam-role.0c61dbd0ca.svg' width='40px' height='40px'/><p>k8s-nodes-role</p>"]
            s3-bucket["<img class='S3Icon' src='https://www.logicata.com/wp-content/uploads/2020/01/Amazon-Simple-Storage-Service-S3_Bucket-with-Objects_light-bg@4x.png' width='70px' height='70px'/><p>kubernetes-the-hard-way</p><i class='fa fa-folder' aria-hidden='true'> kube-certs/</i>"]
        end
        s3-bucket ---|hello there\nhi| iam-role
    end

    %% Defining Class Styles
    classDef Border fill:#fff,stroke:#fff,stroke-width:4px,color:#fff,stroke-dasharray: 5 5;
    classDef AWS fill:transparent,stroke:#FF8C00,stroke-width:2px,color:#000,stroke-dasharray: 8 4;
    classDef S3Icon margin:0px, stroke-width:1px, padding:0px, fill:#aaf0d1, position:absolute, bottom:0px, right:0px, stroke:green, stroke-dasharray: 5 5, rx:5px, ry:5px, color:#004225;

    %% Custom Styles

    %% Assigning Nodes to Classes
    class Border Border;
    class AWS AWS;
    class s3-bucket S3Icon;
```


## Infra-prin Container

The `infra-prin` container is used in this repository to provide the necessary tools for managing the Kubernetes cluster. It comes pre-installed with `kubectl`, AWS CLI, and other utilities needed to interact with the cluster.

## AWS Authentication

Please note that AWS authentication is performed outside of the `infra-prin` container. You will need to authenticate with AWS using your preferred method, such as configuring AWS CLI with your access key and secret key.

Once authenticated, the `~/.aws` directory is mounted inside the `infra-prin` container to provide the necessary credentials and tokens for accessing AWS services.

## Getting Started

To get started with creating the Kubernetes cluster:

1. Get authenticated with AWS using your preferal method locally.
2. Run `make run` to build and get inside of the `infra-prin` container.
3. cd inside the k8s TF folder `cd ./terraform/kubernetes-cluster.
4. Plan and apply your changes `terraform plan`.
