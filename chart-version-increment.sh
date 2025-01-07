#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <CHART_FILE>"
  exit 1
fi

CHART_FILE=$1

currentVersion=$(awk '/^version:/ {print $2}' "$CHART_FILE")

IFS='.' read -r -a versionParts <<< "$currentVersion"

newVersion="${versionParts[0]}.${versionParts[1]}.$((versionParts[2] + 1))"

sed -i "s/^version: .*/version: ${newVersion}/" "$CHART_FILE"

echo "Updated version from ${currentVersion} to ${newVersion} of ${CHART_FILE}"