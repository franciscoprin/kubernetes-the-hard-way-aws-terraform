#!/bin/bash

# HELPER FUNCTIONS:

# Include the function to be tested
source setup-kube-encryption-key.sh

# get flag value in command:
parse_options() {
  local flag_name="$1"
  shift
  local flag_value

  # Loop through the positional arguments
  while [ $# -gt 0 ]; do
      current_arg="$1"

      # Check if the current argument matches the flag name
      if [ "$current_arg" == "$flag_name" ]; then
          # Get the value of the flag
          flag_value=$2
          break
      fi

      # Go to the nex argument:
      shift
  done

  echo $flag_value
}

# Replace flag value in command:
replace_flag_value() {
    flag_name="$1"       # Flag name to replace
    new_value="$2"       # New value for the flag
    shift 2

    # Initialize the modified string
    modified_string=""

    # Loop through the positional arguments
    while [ $# -gt 0 ]; do
        current_arg="$1"

        # Check if the current argument matches the flag name
        if [ "$current_arg" == "$flag_name" ]; then
            # Replace the value of the flag with the new value
            modified_string+="$current_arg $new_value"
            shift 2  # Skip the flag and its original value
        else
            # Append the current argument to the modified string
            modified_string+="$current_arg"
            shift 1  # Move to the next argument
        fi

        # Append a space after each argument
        modified_string+=" "
    done

    # Remove any trailing whitespace
    modified_string=${modified_string% }

    echo "$modified_string"
}

# MOCKING FUNCTIONS:

# - mock aws command:
mock_aws_ssm_get_parameter() {
  # Parse the command line options using the reusable function
  local name_flag_value=$(parse_options "--name" "$@")

  if [[ "$name_flag_value" != "/k8s-the-hard-way/encryption_key" ]]; then
    echo "Error: Invalid parameter path" >&2  # Redirect error message to stderr
    exit 1
  fi

  # Mock the output of the get-parameter command
  echo $mock_encryption_key # "MockEncryptionKey"
}

mock_aws_s3api_list_objects(){
  # Parse the command line options using the reusable function
  local query_flag_value=$(parse_options "--query" "$@")

  if [[ "$query_flag_value" != "sort_by(Contents, &LastModified)[0].LastModified" ]]; then
    echo "Error: Invalid parameter query" >&2  # Redirect error message to stderr
    exit 1
  fi

  # Check if the global variable mock_newest_modified_date is set
  if [[ -z $mock_newest_modified_date ]]; then
    echo "Error: mock_newest_modified_date is not set" >&2  # Redirect error message to stderr
    exit 1
  fi

  # Mock the output of the list-objects command
  echo $mock_newest_modified_date # "2022-05-10T12:30:45Z"
}

mock_aws() {
  local service="$1"
  local action="$2"
  shift 2

  # Declare an associative array to serve as a mapping between 
  # the AWS CLI command and the corresponding mock function.
  declare -A mock_command_map

  # Mapping `aws ssm get-parameter` command:
  mock_command_map["ssm get-parameter"]="mock_aws_ssm_get_parameter"

  # Mapping `aws s3api list-objects-v2` command:
  mock_command_map["s3api list-objects-v2"]="mock_aws_s3api_list_objects"

  # Using the `service` and `action` arguments as the key to 
  # retrieve the corresponding mock function name otherwise empty string.
  mock_command="${mock_command_map["$service $action"]}"

  if [[ -n $mock_command ]]; then
    result=$($mock_command "$@")
    echo $result
    exit 0
  fi

  # The `command` keyword is used to run a command without executing any function or alias with the same name.
  # This is done to ensure that the mock function does not call itself recursively.
  command aws "$@"
}

# - mock data command:
mock_date() {
  local date_flag_value=$(parse_options "-d" "$@")

  # If the data commands look similar to `data -d "-20 days" +%s`, rather than substracting the current time, use a mock_now instead.
  if [[ "$date_flag_value" =~ ^[-+].* ]]; then
    local new_args=$(replace_flag_value "-d" "\"$mock_now $date_flag_value\"" "$@")

    # `eval` helps to preserve quotes around each element, for instance: "-20 days"
    eval "command date ${new_args[*]}"
    return
  fi

  command date "$@"
}

# - mock base64 command:
mock_base64() {

  if [[ -z "$mock_new_encryption_key" ]]; then
    echo "Error: mock_new_encryption_key is not set"
    exit 0
  fi

  echo $mock_new_encryption_key
}

# TESTS:
test_new_encryption_key_is_created_when_it_has_expired() {
  # The encryption_key was already created and stored in SSM,
  mock_encryption_key="MockEncryptionKey"

  # but it has already experied so it needs to be replaced.
  # An experied key should fully the following enequality:
  #   mock_newest_modified_date < mock_now - expired_delta_seconds
  mock_newest_modified_date="2022-03-10T12:30:45Z"
  mock_now="2022-03-10T12:31:45Z"
  expired_delta_seconds=45 # seconds

  # if above conditions are meet a new_encryption_key will be created:
  mock_new_encryption_key="NewMockEncryptionKey"

  # Run tested function:
  expected_result="{\"encryption_key\": \"$mock_new_encryption_key\"}"
  actual_result=$(main)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
  assertNotNull " mock_encryption_key is not set: $mock_encryption_key" "$mock_encryption_key"
}

test_new_encryption_key_is_created_when_it_is_unset_in_ssm() {
  # The encryption_key wasn't created and stored in SSM
  unset mock_encryption_key

  # and it is uptodate.
  # An experied key should fully the following enequality:
  #   mock_newest_modified_date < mock_now - expired_delta_seconds
  mock_newest_modified_date="2022-03-10T12:30:45Z"
  mock_now="2022-03-10T12:30:45Z"
  expired_delta_seconds=86400 # 20 days in seconds

  # if above conditions are meet a new_encryption_key will be created:
  mock_new_encryption_key="NewMockEncryptionKey2"

  # Run tested function:
  expected_result="{\"encryption_key\": \"$mock_new_encryption_key\"}"
  actual_result=$(main)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
  assertNull " mock_encryption_key is set" "$mock_encryption_key"
}

test_non_encryption_key_recreation_when_it_is_uptodate_and_set_in_ssm() {
  # The encryption_key was already created and stored in SSM,
  mock_encryption_key="MockEncryptionKey3"

  # and it is uptodate.
  # An experied key should fully the following enequality:
  #   mock_newest_modified_date < mock_now - expired_delta_seconds
  mock_newest_modified_date="2022-03-10T12:30:45Z"
  mock_now="2022-03-10T12:30:45Z"
  expired_delta_seconds=86400 # 20 days in seconds

  # if above conditions are meet no new_encryption_key will be created:
  mock_new_encryption_key="NewMockEncryptionKey3"

  # Run tested function:
  expected_result="{\"encryption_key\": \"$mock_encryption_key\"}"
  actual_result=$(main)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
  assertNotNull " mock_encryption_key is not set" "$mock_encryption_key"
}

test_ensure_environment_variables_exist(){
  unset bucket_name
  export s3_prefix_path="."
  export expired_delta_seconds="."

  expected_result="Error: bucket_name is not set."
  actual_result=$(bash ./setup-kube-encryption-key.sh)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"

  ###
  ###

  export bucket_name="bucket_name"
  unset s3_prefix_path
  export expired_delta_seconds="."

  expected_result="Error: s3_prefix_path is not set."
  actual_result=$(bash ./setup-kube-encryption-key.sh)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"

  ###
  ###

  export bucket_name="."
  export s3_prefix_path="."
  unset expired_delta_seconds

  expected_result="Error: expired_delta_seconds is not set."
  actual_result=$(bash ./setup-kube-encryption-key.sh)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
}

test_new_encryption_key_is_created_when_empty_s3_bucket_and_it_is_unset_in_ssm() {
  # When the s3 bucket is empty, the command `aws s3api list-objects-v2` will fail.
  # To simulate that error the `mock_newest_modified_date` variale is unset.
  # In this case `mock_newest_modified_date` will be set with infity that is equivalent to 999999999999
  # So the encryption_key shouldn't be recreated.
  unset mock_newest_modified_date

  # The encryption_key wasn't created and stored in SSM.
  unset mock_encryption_key

  # and it is uptodate.
  # An experied key should fully the following enequality:
  #   mock_newest_modified_date < mock_now - expired_delta_seconds
  mock_now="2022-03-10T12:30:45Z"
  expired_delta_seconds=86400 # 20 days in seconds

  # if above conditions are meet no new_encryption_key will be created:
  mock_new_encryption_key="NewMockEncryptionKey4"

  # Run tested function:
  expected_result="{\"encryption_key\": \"$mock_new_encryption_key\"}"
  actual_result=$(main)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
  assertNull " mock_newest_modified_date is set" "$mock_newest_modified_date"
  assertNull " mock_encryption_key is set" "$mock_encryption_key"
}

test_non_entryption_key_recreation_when_empty_s3_bucket_and_set_in_ssm() {
  # When the s3 bucket is empty, the command `aws s3api list-objects-v2` will fail.
  # To simulate that error the `mock_newest_modified_date` variale is unset.
  # In this case `mock_newest_modified_date` will be set with infity that is equivalent to 999999999999
  # So the encryption_key shouldn't be recreated.
  unset mock_newest_modified_date

  # The encryption_key was already created and stored in SSM,
  mock_encryption_key="MockEncryptionKey4"

  # and it is uptodate.
  # An experied key should fully the following enequality:
  #   mock_newest_modified_date < mock_now - expired_delta_seconds
  mock_now="2022-03-10T12:30:45Z"
  expired_delta_seconds=86400 # 20 days in seconds

  # if above conditions are meet no new_encryption_key will be created:
  mock_new_encryption_key="NewMockEncryptionKey4"

  # Run tested function:
  expected_result="{\"encryption_key\": \"$mock_encryption_key\"}"
  actual_result=$(main)

  # Assert expected results:
  assertEquals "$expected_result" "$actual_result"
  assertNull " mock_newest_modified_date is set" "$mock_newest_modified_date"
  assertNotNull " mock_encryption_key is not set" "$mock_encryption_key"
}

setUp() {
  # Aliases are not expanded when the shell is not interactive, 
  # unless the expand_aliases shell option is set using shopt:
  shopt -s expand_aliases

  # Mock commands and functions:
  alias aws='mock_aws'
  alias date='mock_date'
  alias base64='mock_base64'
  function check_variables() {
    :
  }

  # Required local:
  local mock_now
  local expired_delta_seconds
  local mock_newest_modified_date
  local actual_result
  local expected_result
  local mock_encryption_key
  local mock_new_encryption_key
}

tearDown() {
  # # Unset test:
  # unalias aws
  # unalias date
  # unalias create_new_key

  unset mock_now
  unset expired_delta_seconds
  unset mock_newest_modified_date
  unset actual_result
  unset expected_result
  unset mock_encryption_key
  unset mock_new_encryption_key
  unset bucket_name
  unset s3_prefix_path
  unset expired_delta_seconds

  # Reset aliases expandtion when the shell is not interactive.
  shopt -u expand_aliases
}

# sourcing the unit test framework
. shunit2
