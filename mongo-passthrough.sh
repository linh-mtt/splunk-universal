#!/bin/bash

export SASL_PATH=/dev/null

# Define an array to store filtered arguments
filtered_args=()

# Iterate over all input arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --setParameter=minSnapshotHistoryWindowInSeconds=5)
            shift  # Skip this parameter
            ;;
        --setParameter=ocspEnabled=*)
            shift  # Skip this parameter
            ;;
        *)
            filtered_args+=("$1")
            shift
            ;;
    esac
done

# Execute /opt/splunk/bin/mongod-4.2 with the filtered arguments
exec /opt/splunk/bin/mongod-4.2 "${filtered_args[@]}"
