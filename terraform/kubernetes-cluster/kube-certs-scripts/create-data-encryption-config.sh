#!/bin/bash

kube_certs=${1:?Error: kube_certs parameter not provided}
encryption_key=${2:?Error: encryption_key parameter not provided}

# Create the `encryption-config.yaml` encryption config file:
cat > ./$kube_certs/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${encryption_key}
      - identity: {}
EOF


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
# aws s3 cp ./$kube_certs/kube-scheduler.kubeconfig s3://mybucket/kube-scheduler.kubeconfig

# #############
# # Using SCP #
# #############

# # Copy the `encryption-config.yaml` encryption config file to each controller instance:
# export instance_ssh_user="admin"
# for instance in controller-0 controller-1 controller-2; do
#   export external_ip=$(aws ec2 describe-instances --filters \
#     "Name=tag:Name,Values=${instance}" \
#     "Name=instance-state-name,Values=running" \
#     --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
#   scp -o StrictHostKeyChecking=no -i ../../private_key.pem \
#     encryption-config.yaml $instance_ssh_user@${external_ip}:~/
# done
