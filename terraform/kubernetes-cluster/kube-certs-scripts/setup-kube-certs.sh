#!/bin/bash

s3_prefix_path=${1:?Error: s3_prefix_path parameter not provided}
bucket_name=${2:?Error: bucket_name parameter not provided}
k8s_public_address=${3:?Error: k8s_public_address parameter not provided}
# k8s_public_address=$(aws elbv2 describe-load-balancers --names kubernetes | jq -r '.LoadBalancers[0].DNSName')
encryption_key=${4:?Error: encryption_key parameter not provided}

mkdir -p ./$s3_prefix_path

./kube-certs-scripts/create-ca-files.sh $s3_prefix_path $k8s_public_address

./kube-certs-scripts/create-data-encryption-config.sh $s3_prefix_path $encryption_key

./kube-certs-scripts/create-kubeconfigs.sh $s3_prefix_path $k8s_public_address

# Upload files to S3 bucket:
aws s3 cp ./$s3_prefix_path s3://$bucket_name/$s3_prefix_path --recursive

# Delete unecesary secrets:
rm -fr ./$s3_prefix_path
