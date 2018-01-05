#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 repeats interval"
  exit 1
fi

repeats="$1"
interval="$2"

crx_exited=0
for (( index=1; index <"$repeats"; index++ )); do
  echo "checking crx run process: $index run"
  #shellcheck disable=SC2009,SC2126
  count=$(ps -ef | grep -v grep | grep jar | grep crx-quickstart | wc -l )
  if [ "$count" -eq 0 ]; then
    crx_exited=1
    break
  fi
  sleep "$interval"
done

if [ "$crx_exited" -eq 0 ]; then
  echo "aem/crx process failed to stop cleanly"
  exit 1
fi

echo "aem/crx process stopped successfully"
