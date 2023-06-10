#!/bin/bash
# Docs: https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/05-kubernetes-configuration-files.md

kube_certs=${1:?Error: kube_certs parameter not provided}
k8s_public_address=${2:?Error: k8s_public_address parameter not provided}

# The kubelet Kubernetes Configuration File
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=./$kube_certs/ca.pem \
    --embed-certs=true \
    --server=https://${k8s_public_address}:443 \
    --kubeconfig=./$kube_certs/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=./$kube_certs/${instance}.pem \
    --client-key=./$kube_certs/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=./$kube_certs/${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=./$kube_certs/${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=./$kube_certs/${instance}.kubeconfig
done

# The kube-proxy Kubernetes Configuration File
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=./$kube_certs/ca.pem \
  --embed-certs=true \
  --server=https://${k8s_public_address}:443 \
  --kubeconfig=./$kube_certs/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=./$kube_certs/kube-proxy.pem \
  --client-key=./$kube_certs/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=./$kube_certs/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=./$kube_certs/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=./$kube_certs/kube-proxy.kubeconfig

# The kube-controller-manager Kubernetes Configuration File
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=./$kube_certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=./$kube_certs/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=./$kube_certs/kube-controller-manager.pem \
  --client-key=./$kube_certs/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=./$kube_certs/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=./$kube_certs/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=./$kube_certs/kube-controller-manager.kubeconfig

# The kube-scheduler Kubernetes Configuration File
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=./$kube_certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=./$kube_certs/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=./$kube_certs/kube-scheduler.pem \
  --client-key=./$kube_certs/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=./$kube_certs/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=./$kube_certs/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=./$kube_certs/kube-scheduler.kubeconfig

# The admin Kubernetes Configuration File
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=./$kube_certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=./$kube_certs/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=./$kube_certs/admin.pem \
  --client-key=./$kube_certs/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=./$kube_certs/admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=./$kube_certs/admin.kubeconfig

kubectl config use-context default --kubeconfig=./$kube_certs/admin.kubeconfig

# #################
# # Using AWS CLI #
# #################

# # Upload the appropriate `kubelet` and `kube-proxy` kubeconfig files to the S3 bucket:
# aws s3 cp ./$kube_certs/kube-proxy.kubeconfig s3://mybucket/kube-proxy.kubeconfig

# for instance in worker-0 worker-1 worker-2; do
#   aws s3 cp ./$kube_certs/${instance}.kubeconfig s3://mybucket/${instance}.kubeconfig
# done

# ## Upload the appropriate `kube-controller-manager` and `kube-scheduler` kubeconfig files to the S3 bucket:
# aws s3 cp ./$kube_certs/admin.kubeconfig s3://mybucket/admin.kubeconfig
# aws s3 cp ./$kube_certs/kube-controller-manager.kubeconfig s3://mybucket/kube-controller-manager.kubeconfig
# aws s3 cp ./$kube_certs/be-scheduler.kubeconfig s3://mybucket/kube-scheduler.kubeconfig


# #############
# # Using SCP #
# #############

# # Distribute the Kubernetes Configuration Files
# export instance_ssh_user="admin"

# ## Copy the appropriate `kubelet` and `kube-proxy` kubeconfig files to each worker instance:
# for instance in worker-0 worker-1 worker-2; do
#   external_ip=$(aws ec2 describe-instances --filters \
#     "Name=tag:Name,Values=${instance}" \
#     "Name=instance-state-name,Values=running" \
#     --output text --query 'Reservations[].Instances[].PublicIpAddress')

#   scp -o StrictHostKeyChecking=no -i ../../private_key.pem \
#     ${instance}.kubeconfig kube-proxy.kubeconfig $instance_ssh_user@${external_ip}:~/
# done

# ## Copy the appropriate `kube-controller-manager` and `kube-scheduler` kubeconfig files to each controller instance:
# for instance in controller-0 controller-1 controller-2; do
#   external_ip=$(aws ec2 describe-instances --filters \
#     "Name=tag:Name,Values=${instance}" \
#     "Name=instance-state-name,Values=running" \
#     --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
#   scp -o StrictHostKeyChecking=no -i ../../private_key.pem \
#     admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig $instance_ssh_user@${external_ip}:~/
# done