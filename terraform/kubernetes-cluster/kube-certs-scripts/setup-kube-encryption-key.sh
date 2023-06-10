#!/bin/bash

# Get the newest file's mofidication date from S3 bucket.
newest_modified_date=$(aws s3api list-objects-v2 --bucket $bucket_name --prefix $s3_prefix_path --query 'sort_by(Contents, &LastModified)[0].LastModified' --output text)
newest_file_was_modified_date=$(date -d $newest_modified_date +%s)
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
