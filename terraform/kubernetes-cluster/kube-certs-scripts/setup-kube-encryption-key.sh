#!/bin/bash

# `set -e` : Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

check_variables() {
  local var_name
  for var_name in "$@"; do
      if [[ -z "${!var_name}" ]]; then
          echo "Error: $var_name is not set."
          exit 1
      fi
  done
}

function main() {
  check_variables "bucket_name" "s3_prefix_path" "expired_delta_seconds" || exit 1

  # Get the newest file's mofidication date from S3 bucket.
  newest_modified_date=$(aws s3api list-objects-v2 --bucket $bucket_name --prefix $s3_prefix_path --query 'sort_by(Contents, &LastModified)[0].LastModified' --output text 2>/dev/null || echo "")

  newest_file_was_modified_date=$(date -d $newest_modified_date +%s 2>/dev/null || echo "999999999999")
  expiration_threshold=$(date -d "-$expired_delta_seconds seconds" +%s)

  # Trying to retrieve the encryption key from SSM
  encryption_key=$(aws ssm get-parameter --name "/k8s-the-hard-way/encryption_key" --with-decryption --output text --query 'Parameter.Value' 2>/dev/null || echo "")

  # The encryption key will be regenerated if the certificate files in S3 have expired.
  # A file's expiration is determined by comparing its modification date to the current time and an expiration delta.
  # If the modification date plus the expiration delta is earlier than the current time, it indicates that the file has expired.
  # This can also be expressed as:
  #  newest_file_was_modified_date < expiration_threshold, 
  # where:
  #  expiration_threshold is calculated as: now - expired_delta_seconds.

  if [[ -z $encryption_key || $newest_file_was_modified_date -lt $expiration_threshold ]]; then
    # Generate a new encryption key
    encryption_key=$(head -c 32 /dev/urandom | base64)
  fi

  # Use the encryption key as needed in the rest of your script
  echo "{\"encryption_key\": \"$encryption_key\"}"
}


# This block will only execute if the script is executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
