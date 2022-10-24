#!/bin/bash

# -----------------------------------------------------------------------------------------
# Falcon variables
# -----------------------------------------------------------------------------------------
FALCON_API_BASE_URL=api.crowdstrike.com

# -----------------------------------------------------------------------------------------
# CrowdStrike API Access Token
# -----------------------------------------------------------------------------------------
# Get CrowdStrike API Access Token
FALCON_API_ACCESS_TOKEN=$(curl -sL -X POST "https://${FALCON_API_BASE_URL}/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
    --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" | jq -cr '.access_token')

# -----------------------------------------------------------------------------------------
# CrowdStrike Image Prevention Policy Evaluation
# -----------------------------------------------------------------------------------------
IMAGE_PREVENTION_POLICY_RESPONSE=$(curl -sL -X GET "https://container-upload.${FALCON_CLOUD_REGION}.crowdstrike.com/policy-checks?policy_type=image-prevention-policy&repository=${IMAGE_REPO}&tag=${IMAGE_TAG}" \
  -H "Authorization: Bearer ${FALCON_API_ACCESS_TOKEN}" | jq -r '.resources[0]')

DENY_RESULT=$(echo ${IMAGE_PREVENTION_POLICY_RESPONSE} | jq -r '.deny')
ACTION_RESULT=$(echo ${IMAGE_PREVENTION_POLICY_RESPONSE} | jq -r '.action')
PREVENTION_POLICY_NAME=$(echo ${IMAGE_PREVENTION_POLICY_RESPONSE} | jq -r '.policy.name')
PREVENTION_POLICY_DESCRIPTION=$(echo ${IMAGE_PREVENTION_POLICY_RESPONSE} | jq -r '.policy.description')

if [[ "${DENY_RESULT}" == "true" && "${ACTION_RESULT}" == "block" ]]; then
    echo "-----------------------------------------------------------------------------------------"
    echo "CrowdStrike Image Assessment result: Image -Blocked- due to Image Prevention Policy"
    echo "${PREVENTION_POLICY_NAME} - ${PREVENTION_POLICY_DESCRIPTION}"
    echo "-----------------------------------------------------------------------------------------"
    echo " "
    echo "Malware:"
    curl -s -X GET "https://container-upload.${FALCON_CLOUD_REGION}.crowdstrike.com/reports?repository=${IMAGE_REPO}&tag=${IMAGE_TAG}" \
        -H "Authorization: Bearer ${FALCON_API_ACCESS_TOKEN}" | jq -r '.ELFBinaries[] | select(.Malicious == true) | "\(.Malicious) - \(.Permissions) : \(.Path)"'
    
    echo " "
    echo "Detections:"
    curl -s -X GET -H "Authorization: Bearer ${FALCON_API_ACCESS_TOKEN}" \
                    "https://container-upload.${FALCON_CLOUD_REGION}.crowdstrike.com/reports?repository=${IMAGE_REPO}&tag=${IMAGE_TAG}" |\
                    jq -r '.Detections[].Detection | "\(.Severity) - \(.Type) - \(.Name) - \(.Title) - \(.Details.Match)"'
    
    echo " "
    echo "Vulnerabilities:"
    curl -s -X GET -H "Authorization: Bearer ${FALCON_API_ACCESS_TOKEN}" \
                    "https://container-upload.${FALCON_CLOUD_REGION}.crowdstrike.com/reports?repository=${IMAGE_REPO}&tag=${IMAGE_TAG}" |\
                    jq -r '.Vulnerabilities[].Vulnerability | "\(.CVEID)\t\(.Product.PackageSource)\t\(.Details.exploited.status)\t\(.Details.severity)\t\(.Details.exploitability_score)"'
    
    sleep 1
    exit 1
else
    echo "-----------------------------------------------------------------------------------------"
    echo "CrowdStrike Image Assessment result: Image not Blocked by Image Prevention Policy."
    echo "-----------------------------------------------------------------------------------------"
    exit 0
fi