#!/bin/bash

# Mock fields:
S3_PREFIX_PATH="tes-S3_PREFIX_PATH"
BUCKET_NAME="tes-BUCKET_NAME"
K8S_PUBLIC_ADDRESS="https://tes-K8S_PUBLIC_ADDRESS.com"
ENCRYPTION_KEY="tes-ENCRYPTION_KEY"

# Function to mock aws s3 cp command:
mock_aws_s3_cp() {
    echo "Mocking aws s3 cp command: aws s3 cp $1 $2"
    # Add any additional assertions or custom behavior you want for the mock
    # In this example, we're just printing the mocked command
}

# Mocking aws s3 cp command:
mock_aws() {
    if [ "$1" == "s3" ] && [ "$2" == "cp" ]; then
        mock_aws_s3_cp "$3" "$4"
    else
        # Call the actual aws command if not mocking s3 cp
        command aws "$@"
    fi
}

# Mocking rm command:
mock_rm() {
    echo "Mocking rm command: rm $1 $2"
}

expected_files=(
    admin-csr.json
    admin-key.pem
    admin.csr
    admin.kubeconfig
    admin.pem
    ca-config.json
    ca-csr.json
    ca-key.pem
    ca.csr
    ca.pem
    encryption-config.yaml
    kube-controller-manager-csr.json
    kube-controller-manager-key.pem
    kube-controller-manager.csr
    kube-controller-manager.kubeconfig
    kube-controller-manager.pem
    kube-proxy-csr.json
    kube-proxy-key.pem
    kube-proxy.csr
    kube-proxy.kubeconfig
    kube-proxy.pem
    kube-scheduler-csr.json
    kube-scheduler-key.pem
    kube-scheduler.csr
    kube-scheduler.kubeconfig
    kube-scheduler.pem
    kubernetes-csr.json
    kubernetes-key.pem
    kubernetes.csr
    kubernetes.pem
    service-account-csr.json
    service-account-key.pem
    service-account.csr
    service-account.pem
    worker-0-csr.json
    worker-0-key.pem
    worker-0.csr
    worker-0.kubeconfig
    worker-0.pem
    worker-1-csr.json
    worker-1-key.pem
    worker-1.csr
    worker-1.kubeconfig
    worker-1.pem
    worker-2-csr.json
    worker-2-key.pem
    worker-2.csr
    worker-2.kubeconfig
    worker-2.pem
)

test_check_files_created() {

    # Execute script by using mocking functions:
    # Setup test:
    cd ..
    alias aws='mock_aws'
    alias rm='mock_rm'

    # Aliases are not expanded when the shell is not interactive, 
    # unless the expand_aliases shell option is set using shopt:
    shopt -s expand_aliases

    # Run tested function:
    . ./kube-certs-scripts/setup-kube-certs.sh \
            $S3_PREFIX_PATH \
            $BUCKET_NAME \
            $K8S_PUBLIC_ADDRESS \
            $ENCRYPTION_KEY

    # Assert expected results.

    actual_files=$(ls ./$S3_PREFIX_PATH)
    sorted_expected_files=$(printf "%s\n" "${expected_files[@]}" | sort)
    assertEquals "$(echo $sorted_expected_files)" "$(echo $actual_files)"
    # echo "${expected_files[*]}"
    # for expected_file in "${expected_files[@]}"; do
    #     error_message="Expected file '$expected_file' not found at path '$S3_PREFIX_PATH'"
    #     assertTrue "$error_message" "[ -f ./$S3_PREFIX_PATH/$expected_file ]"
    # done

    # Unset test:
    unalias aws
    unalias rm
    cd -

    # Clean test:
    rm -fr ../$S3_PREFIX_PATH
}

# sourcing the unit test framework
. shunit2
