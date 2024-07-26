#!/bin/bash

# Check if the .tfvars file argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <tfvars-file>"
  exit 1
fi

# The .tfvars file to use
TFVARS_FILE="$1"

# Extract the expected workspace from the .tfvars file name
EXPECTED_WORKSPACE=$(basename "$TFVARS_FILE" .tfvars | sed 's/region\.//')

# Get the current Terraform workspace
CURRENT_WORKSPACE=$(terraform workspace show)

# Check if the current workspace matches the expected workspace
if [ "$CURRENT_WORKSPACE" != "$EXPECTED_WORKSPACE" ]; then
  echo "The current workspace ($CURRENT_WORKSPACE) does not match the expected workspace ($EXPECTED_WORKSPACE)."
  echo "Switching to the expected workspace."
  terraform workspace select "$EXPECTED_WORKSPACE" || {
    echo "Failed to switch to workspace $EXPECTED_WORKSPACE. Exiting."
    exit 1
  }
fi

# Maximum number of retries
MAX_RETRIES=5
# Initial retry count
retry_count=0

# Function to plan terraform
plan_terraform() {
  terraform plan -var-file="$TFVARS_FILE"
  return $?
}

# Function to apply terraform
apply_terraform() {
  terraform apply -var-file="$TFVARS_FILE" -auto-approve
  return $?
}

# Function to check if the error is ignorable
is_ignorable_error() {
  local error_message=$1
  [[ "$error_message" == *"BucketNotEmpty"* ]] || [[ "$error_message" == *"EntityAlreadyExists"* ]]
  return $?
}

# Main loop to retry on failure
while true; do
  # Run terraform plan and capture output
  plan_output=$(plan_terraform 2>&1)
  plan_result=$?

  if [ $plan_result -ne 0 ]; then
    echo "Terraform plan failed. Exiting."
    echo "$plan_output"
    exit 1
  fi

  # Display the plan output
  echo "$plan_output"

  # Prompt user for confirmation to proceed with apply
  read -p "Do you want to proceed with terraform apply? (yes/no): " user_input
  if [ "$user_input" != "yes" ]; then
    echo "User chose not to proceed with apply. Exiting."
    exit 0
  fi

  # Run terraform apply and capture output
  error_message=$(apply_terraform 2>&1)
  result=$?

  if [ $result -eq 0 ]; then
    echo "Terraform apply succeeded."
    exit 0
  fi

  # Check if the error is ignorable
  if is_ignorable_error "$error_message"; then
    echo "Ignoring error: $error_message"
  else
    echo "Non-ignorable error occurred: $error_message"
    exit 1
  fi

  # Increment retry count
  retry_count=$((retry_count + 1))
  if [ $retry_count -ge $MAX_RETRIES ]; then
    echo "Reached maximum retries ($MAX_RETRIES). Exiting."
    exit 1
  fi

  echo "Retrying... ($retry_count/$MAX_RETRIES)"
  sleep 5  # Wait before retrying
done