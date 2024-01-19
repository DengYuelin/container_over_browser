#!/bin/bash
if [[ ! $1 ]] ; then
  echo "ERROR: no new password is provided."
  echo "Example usage: ./update_password.sh your_new_password"
  exit -1
fi

NEW_PASSWD=$1
echo "$USER:$NEW_PASSWD" | sudo chpasswd

ACCESS_PORT=2701
PASSWD_HASH=$(caddy hash-password --plaintext $NEW_PASSWD)
echo $NEW_PASSWD | sudo -S pkill -2 -f supervisord
echo "SUCCESS! Please refresh all windows and log in with your new credentials."
HTTP_BASIC_AUTH_PASSWD_HASH=$PASSWD_HASH ACCESS_PORT=$ACCESS_PORT supervisord -c /etc/supervisord.conf > /dev/null 2>&1 &
