# Remote desktop access into a Docker container.

This setup uses the [ADE utility](https://ade-cli.readthedocs.io/en/latest/install.html) and Docker on the host machine. Under the hood, it utilizes OpenBox, NoVNC, and Caddy inside the container, to expose a VNC server to be accessible through a web browser.

The work directory of the container will be set up within this folder. Each container allows multiple  users for simultaneous remote access. The HOME directories for these users are created within this folder.

To deploy independent containers at scale, simply copy this folder and run the setup process within each copy.

## For general-purpose (single-instance) setup
The setup process involves two steps: building the container, and starting the remote access service within the container. These two steps are now separated for more flexibility. To start the service within a container, ADE is used to execute the script for step 2 from the container's shell.

Prequisites:
- Install Docker (https://docs.docker.com/engine/install/).
- Obtain a copy of the ADE executable (https://ade-cli.readthedocs.io/en/latest/install.html).

The two steps are documented in:
- `docker_build.sh` -- Step 1, build the container.
- `docker_browser_access_up.sh` -- Step 2, start the service. This script must be executed from **within** the created container.

This setup is inspired by the [Minimal ADE](https://gitlab.com/ApexAI/minimal-ade) repository.

## For setup with multiple client containers from a base image
This scenario is specially brought up with the teaching experience of MFET442 class, where more than 30 students are using the identical container base image to develop their own ROS workspaces. To manage the bulk volume of machines and computing/storage requirements, we distributed the containers on five different physical machines on the same subnet. A script, `mfet442-container-management.sh` is created for the sole purpose of bulk management. A detailed description of how the cluster is set up is illustrated below. The steps need to be repeated on each physical machine.

1. Create a folder where all container file storage will be located:
    ```sh
    cd ~ && mkdir container_ws && cd container_ws
    ```
   Clone the `mfet442` branch of this repository:
    ```sh
    git clone -b mfet442 https://github.com/HaoguangYang/container_over_browser.git
    ```
2. Modify `docker/Dockerfile` to select the build of ROS1 or ROS2 images, by toggling the comments in lines 60-61, e.g.:
     ```diff
     --- a/docker/Dockerfile
     +++ b/docker/Dockerfile
     @@ -57,8 +57,8 @@ RUN --mount=type=cache,target=/var/cache/apt \
          apt-get upgrade -y && \
          apt-get install -y ros-${ROS_DISTRO}-desktop
  
     -FROM ros2_humble_desktop AS mfet442
     -# FROM ros_noetic_desktop_full AS mfet442
     +# FROM ros2_humble_desktop AS mfet442
     +FROM ros_noetic_desktop_full AS mfet442
  
      SHELL ["/bin/bash", "-c"]
     ```
   Build the docker image with:
     ```sh
     ./docker_build.sh
     ```
   If you have multiple versions of the images co-existing, you may want to edit the tag they are given, to a string other than `latest`. This can be done either by editing the `docker_build.sh` prior to building:
     ```diff
     --- a/docker_build.sh
     +++ b/docker_build.sh
     @@ -2,7 +2,7 @@
     
      export DOCKER_BUILDKIT=1
     
     -docker build -t container_over_browser_base:latest -f ./docker/Dockerfile .
     +docker build -t mfet442::ros2-humble-desktop -f ./docker/Dockerfile .

     ```
   or with `docker tag` command after the image is built, e.g.:
    ```sh
    docker tag container_over_browser_base:latest mfet442::ros2-humble-desktop
    ```
   Once the image has been built, do a `docker image ls -a`, you should see all built images, e.g.:
    ```log
    $ docker image ls -a
    REPOSITORY                    TAG                       IMAGE ID       CREATED        SIZE
    mfet442                       ros-noetic-desktop-full   2091d6db8d1b   2 months ago   4.62GB
    mfet442                       ros2-humble-desktop       606bf48b4dc5   2 months ago   4.15GB
    ```
3. Preparation work before bringing up the container cluster.
   - Collect the "ApexAI Development Environment" (ade) command-line tool at https://gitlab.com/ApexAI/ade-cli/-/releases, and extract the executable into this folder, renaming it as `ade`. Make sure the executable flag is set with `chmod +x ./ade`.
   - Probe the local area network to find a continuous IP address range within the same subnet as the physical computer, find the gateway address of the current subnet, and find one open port for accessing the container remotely.
     - To find the gateway: `route -n`, the one-hop gateway is marked with `UG` flag. A one-line command will do the direct extraction: `route -n | grep 'UG[ \t]' | awk '{print $2}'`.
     - To find the occupied and vacant IP address: `nmap -sP ${YOUR_SUBNET}`, e.g.: `nmap -sP 10.165.103.0/24`. Rule out all addresses that appear as `Host is up`. Sketch out a large-enough IP pool for your cluster based on the remaining available IP addresses.
     - To find open ports: do it on your own computer to scan the machine hosting the containers `nmap -v -v -Pn -p 0-65535 ${HOST_ADDRESS}`. Note down the ports listed as `open` or `closed` (not `filtered`). Make sure to retry the scan when your computer is connected to different subnets on campus (WiFi, wired, in different buildings of the campus, through VPN, etc.), as the students are expecting to connect to the hosted containers wherever they are on the campus network.
     - Edit the beginning section of the provided management script `mfet442-container-management.sh`, to match the actual network setup. Please follow the text comments in the script for a detailed explanation.
4. Start the container cluster.
    
