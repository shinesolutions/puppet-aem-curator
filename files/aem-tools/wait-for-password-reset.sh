#!/usr/bin/env bash
# Wait until the AEM Password Reset bundle has reset the system users' passwords
# since the AEM service last started, restarting AEM once if it hasn't.
#
# When the repository is restored from a snapshot, the Sling JCR installer can
# scan its watched folders just before the password reset package writes its
# install folder, so the bundle never activates and the passwords are not reset.
# A restart makes the installer rescan and pick the bundle up.

set -o nounset
set -o errexit

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 service log_file timeout_seconds"
  exit 1
fi

service="$1"
log_file="$2"
timeout="$3"
interval=10

# Succeeds if the bundle logged a password reset after the service last started.
# The log can also contain lines from before the snapshot was taken.
password_reset_since_start() {
  started=$(date -d "$(systemctl show -p ActiveEnterTimestamp --value "$service")" +%s)
  grep -h 'passwordreset.Activator Changed the password for admin' "$log_file" 2>/dev/null |
    awk '{ split($1, d, "."); print d[3] "-" d[2] "-" d[1] " " substr($2, 1, 8) }' |
    while read -r timestamp; do
      if [ "$(date -d "$timestamp" +%s)" -ge "$started" ]; then
        echo found
        break
      fi
    done | grep -q found
}

wait_for_password_reset() {
  for (( elapsed=0; elapsed<timeout; elapsed+=interval )); do
    if password_reset_since_start; then
      return 0
    fi
    sleep "$interval"
  done
  return 1
}

if wait_for_password_reset; then
  echo "AEM password reset completed"
  exit 0
fi

echo "AEM password reset not seen within ${timeout} seconds, restarting ${service}"
systemctl restart "$service"

if wait_for_password_reset; then
  echo "AEM password reset completed after restarting ${service}"
  exit 0
fi

echo "AEM password reset not seen within ${timeout} seconds after restarting ${service}"
exit 1
