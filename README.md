# Remote desktop access into a Docker container.

This setup uses the [ADE utility](https://ade-cli.readthedocs.io/en/latest/install.html) and Docker on the host machine. Under the hood, it utilizes OpenBox, NoVNC, and Caddy inside the container, to expose a VNC server to be accessible through a web browser.

The work directory of the container will be set up within this folder. Each container allows multiple  users for simultaneous remote access. The HOME directories for these users are created within this folder.

To deploy independent containers at scale, simply copy this folder and run the setup process within each copy.

The setup process involves two steps: building the container, and starting the remote access service within the container. These two steps are now separated for more flexibility. To start the service within a container, ADE is used to execute the script for step 2 from the container's shell.

Prequisites:
- Install Docker (https://docs.docker.com/engine/install/).
- Obtain a copy of the ADE executable (https://ade-cli.readthedocs.io/en/latest/install.html).

The two steps are documented in:
- `docker_build.sh` -- Step 1, build the container.
- `docker_browser_access_up.sh` -- Step 2, start the service. This script must be executed from **within** the created container.

This setup is inspired by the [Minimal ADE](https://gitlab.com/ApexAI/minimal-ade) repository.
