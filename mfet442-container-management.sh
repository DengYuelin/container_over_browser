#!/bin/bash
# BEFORE YOU PROCEED:
# 1. Please build the docker images accordingly.
# change the dockerfile/Dockerfile for building different base image (ROS noetic + 20.04[focal] / ROS2 humble + 22.04[jammy])
# run:
# ./docker_build.sh
# then use:
# docker image tag container_over_browser_base:latest mfet442:ros-noetic-desktop-full
# or
# docker image tag container_over_browser_base:latest mfet442:ros2-humble-desktop
# to label the images for usage in this script.
#
# 2. Please modify the parameters below accordingly.
# ID range of clients on this machine. This number is 1-based.
START_ID=1
# MFET442-specific: start a mix of ROS1 and ROS2 clients
ROS1_END_ID=12
ROS2_END_ID=16
CONTAINER_PREFIX=crl-client-
USER_PREFIX=crl
USER_ACCESS_PORT=2701		# set to circumvent Purdue LAN firewall rules
# network interface to bind clients to
NETWORK_INTERFACE=enp0s31f6
# subnet of clients
SUBNET=10.165.103.0
NETMASK=24
GATEWAY=10.165.103.1
# start of consecutive IP addresses of all clients
# IP of a specific client = START_IP + ID - 1
START_IP=10.165.103.192
# 28: for max 16 clients on this machine
# 29: for max  8 clients on this machine
IP_RANGE_MASK=28
DOCKER_MACVLAN_NAME=pub_net
#
# 3. Usage:
# Initialize setup and bring up the containers:
# ./mfet442-container-management start
# Restarting one container as ROS1 or ROS2 instance:
# ./mfet442-container-management restart_one_instance_as_[ros1|ros2] $ID
# Copy a file or folder to all client containers (into their home directory):
# ./mfet442-container-management deploy $PATH
# Stop all containers:
# ./mfet442-container-management stop
# Remove all containers and network (but the client-created data under their home-directory will be kept):
# ./mfet442-container-management purge

#=====================================================================================

# function to add a number to an IP address
ip_add(){
  IP=$1
  INCR=$2
  IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
  INCR_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + $INCR ))`)
  INCR_IP=$(printf '%d.%d.%d.%d\n' `echo $INCR_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
  echo "$INCR_IP"
}

# function to start a container and IDE access over browser
ide_start(){
  ID=$1
  BASE_IMAGE=$2
  ADDR=$(ip_add ${START_IP} $((${ID}-1)))
  ADE_NAME=${CONTAINER_PREFIX}${ID} ADE_NET=${DOCKER_MACVLAN_NAME} \
    ADE_BASE_IMAGE=${BASE_IMAGE} ./ade start -- \
    --ip=${ADDR}
  # create new user and start browser access
  NEWUSR=${USER_PREFIX}${ID}
  NEWUSRPASSWD=${NEWUSR}@purdue.edu
  docker exec -d --user $USER ${CONTAINER_PREFIX}${ID} /bin/bash -c \
    "~/docker_browser_access_up.sh ${NEWUSR} ${NEWUSRPASSWD} ${USER_ACCESS_PORT}"
  echo "USERNAME          PASSWORD        ACCESS_ADDRESS"
  echo "${NEWUSR}      ${NEWUSRPASSWD}        ${ADDR}:${USER_ACCESS_PORT}"
}

# MFET442-specific
if [ $1 == "start" ]; then
  # create the MACVLAN interface of docker, to bridge containers onto host network
  if [[ ! $(docker network ls | grep ${DOCKER_MACVLAN_NAME}) ]] ; then
    docker network create -d macvlan \
      --subnet=${SUBNET}/${NETMASK} --gateway=${GATEWAY} \ 
      --ip-range=$(ip_add ${START_IP} $((${START_ID}-1)))/${IP_RANGE_MASK} \
      -o parent=${NETWORK_INTERFACE} ${DOCKER_MACVLAN_NAME}
  fi
  # The following part starts the containers
  for i in {${START_ID}..${ROS1_END_ID}} ; do
    ide_start ${i} mfet442:ros-noetic-desktop-full
  done
  for i in {$((${ROS1_END_ID}+1))..${ROS2_END_ID}} ; do
    ide_start ${i} mfet442:ros2-humble-desktop
  done
elif [ $1 == "restart_one_instance_as_ros1" ]; then
  ADE_NAME=${CONTAINER_PREFIX}$2 ./ade stop
  ide_start $2 mfet442:ros-noetic-desktop-full
elif [ $1 == "restart_one_instance_as_ros2" ]; then
  ADE_NAME=${CONTAINER_PREFIX}$2 ./ade stop
  ide_start $2 mfet442:ros2-humble-desktop
elif [ $1 == "deploy" ]; then
  for i in {${START_ID}..${ROS1_END_ID}} ; do
    cp -R $2 ./users/${USER_PREFIX}${i}/
  done
  for i in {$((${ROS1_END_ID}+1))..${ROS2_END_ID}} ; do
    cp -R $2 ./users/${USER_PREFIX}${i}/
  done
elif [ $1 == "stop" ]; then
  for i in {${START_ID}..${ROS1_END_ID}} ; do
    ADE_NAME=${CONTAINER_PREFIX}${i} ./ade stop
  done
  for i in {$((${ROS1_END_ID}+1))..${ROS2_END_ID}} ; do
    ADE_NAME=${CONTAINER_PREFIX}${i} ./ade stop
  done
elif [ $1 == "purge" ]; then
  for i in {${START_ID}..${ROS1_END_ID}} ; do
    docker container rm -f ${CONTAINER_PREFIX}${i}
  done
  for i in {$((${ROS1_END_ID}+1))..${ROS2_END_ID}} ; do
    docker container rm -f ${CONTAINER_PREFIX}${i}
  done
  docker network rm ${DOCKER_MACVLAN_NAME}
fi
