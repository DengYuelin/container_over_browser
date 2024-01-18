#!/bin/bash

# Creates a new user inside a container if it does not yet exist,
# and set up password-protected browser remote access under that user.
#
# USAGE:
# export ADE_NAME=your_container_id
# ./ade start && ./ade enter
# ./docker_browser_access_up.sh new_user_name new_passwd access_port &
# The new user is setup as new_user_name, password is new_passwd
# and has a home directory of /home/new_user_name.
# The home directory is mapped to $(pwd)/new_user_name,
# i.e. /home/$USER/new_user_name in the container.
# After starting the script, the remote desktop is accessible through a web browser at:
# http://container_ip:access_port
# The container_ip depends on the network configuration your Docker is set up with.

NEW_USER=${1:-test_usr}
NEW_PASSWD=${2:-ecet581@purdue.edu}
ACCESS_PORT=${3:-9080}

# if the new user does not exist, create it
if [[ ! $(cat /etc/passwd | grep $NEW_USER) ]] ; then
    # creation of home directory
    mkdir -p /home/$USER/users/$NEW_USER
    if [[ ! -s /home/$NEW_USER ]] ; then
        sudo ln -s -f /home/$USER/users/$NEW_USER /home/$NEW_USER
    fi
    # add the user to the system, assign proper groups
    sudo useradd -M -g "$GROUP_ID" -d "/home/$NEW_USER" -s /bin/bash "$NEW_USER"
    sudo usermod -aG video $NEW_USER
    sudo usermod -aG dialout $NEW_USER
    echo "$NEW_USER:$NEW_PASSWD" | sudo chpasswd

    # copy env variable setup script, etc.
    cp -r /home/$USER/.bashrc /home/$USER/.profile /home/$NEW_USER/
    # copy over lxterminal beautify config
    mkdir -p /home/$NEW_USER/.config/lxterminal/
    cp /home/$USER/docker/lxterminal.conf /home/$NEW_USER/.config/lxterminal/
    cp /home/$USER/.bashrc /home/$NEW_USER/.bashrc
    echo "cd /home/\${USER}/" >> /home/$NEW_USER/.bashrc

    # MFET 442: deploy vscode extensions and settings
    if [[ -d /home/$USER/.openvscode-server ]] ; then
        cp -r /home/$USER/.openvscode-server /home/$NEW_USER/
        rm -rf /home/$NEW_USER/.openvscode-server/extension_download_cache
    fi

    sudo chown $NEW_USER -R /home/$NEW_USER/
    sudo chgrp $GROUP_ID -R /home/$NEW_USER/
    sudo chmod g+rw -R /home/$NEW_USER/
elif [[ "$NEW_USER" == "$USER" ]]; then
    # change my own config if new_user is user
    mkdir -p /home/$USER/.config/lxterminal/
    cp /home/$USER/docker/lxterminal.conf /home/$USER/.config/lxterminal/
fi

# with the new user, swithc to the new user and start the remote access service
PASSWD_HASH=$(caddy hash-password --plaintext $NEW_PASSWD)
if [[ "$NEW_USER" != "$USER" ]]; then
    echo $NEW_PASSWD | sudo HTTP_BASIC_AUTH_PASSWD_HASH=$PASSWD_HASH ACCESS_PORT=$ACCESS_PORT -S su $NEW_USER -c "supervisord -c /etc/supervisord.conf"
else
    HTTP_BASIC_AUTH_PASSWD_HASH=$PASSWD_HASH ACCESS_PORT=$ACCESS_PORT supervisord -c /etc/supervisord.conf
fi
