#!/bin/bash

# NOTE: This file is kept for backwards compatibility. Theoretically you do not need this anymore.
# In the latest setup, the additional (service restart) steps following password change have been implemented with aliases.

if [[ ! $1 ]] ; then
  echo "ERROR: no new password is provided."
  echo "Example usage: ./update_password.sh your_new_password"
  exit -1
fi

NEW_PASSWD=$1
echo "$USER:$NEW_PASSWD" | sudo chpasswd

ACCESS_PORT=2701

# this line below is a generic approach
# PASSWD_HASH=$(caddy hash-password --plaintext $NEW_PASSWD)

# this method below only works on a system with blowfish set as password hashing method
# requires to change before running this script: /etc/pam.d/common-password: lines

# here are the per-package modules (the "Primary" block)
# password       [success=1 default=ignore]      pam_unix.so obscure sha512
# to
# password       [success=1 default=ignore]      pam_unix.so obscure blowfish

PASSWD_HASH=$(sudo cat /etc/shadow | grep $USER | cut -d ":" -f 2)

# restart processes
echo $NEW_PASSWD | sudo -S pkill -2 -f supervisord
echo "SUCCESS! Please refresh all windows and log in with your new credentials."
HTTP_BASIC_AUTH_PASSWD_HASH=$PASSWD_HASH ACCESS_PORT=$ACCESS_PORT supervisord -c /etc/supervisord.conf > /dev/null 2>&1 &
