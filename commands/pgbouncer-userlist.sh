#!/bin/bash

# Usage: pgbouncer-userlist.sh user password

USERNAME=$1
PASSWORD=$2

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

# Generate md5 hash: md5(password + username)
HASH=$(echo -n "${PASSWORD}${USERNAME}" | md5sum | awk '{print $1}')
PG_HASH="md5${HASH}"

# Output in PgBouncer format
echo "\"$USERNAME\" \"$PG_HASH\""
