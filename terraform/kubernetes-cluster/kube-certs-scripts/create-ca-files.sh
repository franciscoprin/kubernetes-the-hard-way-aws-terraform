#!/bin/bash
kube_certs=${1:?Error: kube_certs parameter not provided}
k8s_public_address=${2:?Error: k8s_public_address parameter not provided}

cat > ./$kube_certs/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ./$kube_certs/ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ./$kube_certs/ca-csr.json | cfssljson -bare ./$kube_certs/ca

##########

cat > ./$kube_certs/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -profile=kubernetes \
  ./$kube_certs/admin-csr.json | cfssljson -bare ./$kube_certs/admin

##########

# The Kubelet Client Certificates

for i in 0 1 2; do
  instance="worker-${i}"
  instance_hostname="ip-10-1-1-2${i}"
  cat > ./$kube_certs/${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  internal_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress')

  cfssl gencert \
    -ca=./$kube_certs/ca.pem \
    -ca-key=./$kube_certs/ca-key.pem \
    -config=./$kube_certs/ca-config.json \
    -hostname=${instance_hostname},${external_ip},${internal_ip} \
    -profile=kubernetes \
    ./$kube_certs/worker-${i}-csr.json | cfssljson -bare ./$kube_certs/worker-${i}
done

# The Controller Manager Client Certificate
cat > ./$kube_certs/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -profile=kubernetes \
  ./$kube_certs/kube-controller-manager-csr.json | cfssljson -bare ./$kube_certs/kube-controller-manager

# The Kube Proxy Client Certificate:
cat > ./$kube_certs/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -profile=kubernetes \
  ./$kube_certs/kube-proxy-csr.json | cfssljson -bare ./$kube_certs/kube-proxy

# The Scheduler Client Certificate
cat > ./$kube_certs/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -profile=kubernetes \
  ./$kube_certs/kube-scheduler-csr.json | cfssljson -bare ./$kube_certs/kube-scheduler

# The Kubernetes API Server Certificate
cat > ./$kube_certs/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

kubernetes_hostnames=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local
cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -hostname=10.32.0.1,10.1.1.10,10.1.1.11,10.1.1.12,${k8s_public_address},127.0.0.1,${kubernetes_hostnames} \
  -profile=kubernetes \
  ./$kube_certs/kubernetes-csr.json | cfssljson -bare ./$kube_certs/kubernetes

# The Service Account Key Pair
cat > ./$kube_certs/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=./$kube_certs/ca.pem \
  -ca-key=./$kube_certs/ca-key.pem \
  -config=./$kube_certs/ca-config.json \
  -profile=kubernetes \
  ./$kube_certs/service-account-csr.json | cfssljson -bare ./$kube_certs/service-account

#################
# Using AWS CLI #
#################



# #############
# # Using SCP #
# #############

# # Distribute the Client and Server Certificates
# export instance_ssh_user="admin"

# ## Copy the appropriate certificates and private keys to each worker instance:
# for instance in worker-0 worker-1 worker-2; do
#   external_ip=$(aws ec2 describe-instances --filters \
#     "Name=tag:Name,Values=${instance}" \
#     "Name=instance-state-name,Values=running" \
#     --output text --query 'Reservations[].Instances[].PublicIpAddress')

#   scp -o StrictHostKeyChecking=no -i ../../private_key.pem \
#     ca.pem ${instance}-key.pem ${instance}.pem \
#     $instance_ssh_user@${external_ip}:~/
# done

# ## Copy the appropriate certificates and private keys to each controller instance:
# for instance in controller-0 controller-1 controller-2; do
#   export external_ip=$(aws ec2 describe-instances --filters \
#     "Name=tag:Name,Values=${instance}" \
#     "Name=instance-state-name,Values=running" \
#     --output text --query 'Reservations[].Instances[].PublicIpAddress')

#   scp -o StrictHostKeyChecking=no -i ../../private_key.pem \
#     ca.pem ca-key.pem kubernetes-key.pem \
#     kubernetes.pem service-account-key.pem \
#     service-account.pem $instance_ssh_user@${external_ip}:~/
# done
