#!/bin/bash

TARGET_USER=${1:-$USER}

mkdir -p /home/$TARGET_USER/.openvscode-server/extensions

cwd=$(pwd)

# Create a tmp dir for downloading
tdir=/home/$TARGET_USER/.openvscode-server/extension_download_cache
mkdir -p "${tdir}" && cd "${tdir}"
# Direct download links to external .vsix not available on https://open-vsx.org/
urls=(\
    https://github.com/microsoft/vscode-cpptools/releases/latest/download/cpptools-linux.vsix \
    https://github.com/lharri73/DBC-Language-Syntax/releases/latest/download/dbc-2.0.0.vsix \
)
# Download via wget from $urls array.
for url in "${urls[@]}"; do
    pkg_name=$(echo ${url} | cut -d '/' -f 9)
    if [[ ! $(find ${pkg_name} -ctime -7) ]]; then
        wget "${url}"
    fi
    ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --extensions-dir /home/$TARGET_USER/.openvscode-server/extensions/ --install-extension ${pkg_name}
done

ms_marketplace_urls=(\
    https://marketplace.visualstudio.com/_apis/public/gallery/publishers/nonanonno/vsextensions/vscode-ros2/0.1.5/vspackage \
    https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-iot/vsextensions/vscode-ros/0.9.5/vspackage \
)
for ms_raw in "${ms_marketplace_urls[@]}"; do
    pkg_name=$(echo ${ms_raw} | cut -d '/' -f 10)
    if [[ ! $(find ${pkg_name}.vsix -ctime -7) ]]; then
        wget --limit-rate=750k -O - ${ms_raw} | gunzip -c  > ${pkg_name}.vsix
    fi
    ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --extensions-dir /home/$TARGET_USER/.openvscode-server/extensions/ --install-extension ${pkg_name}.vsix
done
cd $cwd

# List the extensions in this array
exts=(\
    # From https://open-vsx.org/ registry directly
    cschlosser.doxdocgen \
    #eamodio.gitlens \
    jeff-hykin.better-cpp-syntax \
    ms-python.isort \
    ms-python.black-formatter \
    ms-python.flake8 \
    ms-python.python \
    ms-pyright.pyright \
    ms-toolsai.jupyter \
    njpwerner.autodocstring \
    RandomFractalsInc.geo-data-viewer \
    redhat.vscode-xml \
    redhat.vscode-yaml \
    shd101wyy.markdown-preview-enhanced \
    Gruntfuggly.todo-tree \
    twxs.cmake \
    muhammad-sammy.csharp \
)
# Install the $exts
for ext in "${exts[@]}"; do
    ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --extensions-dir /home/$TARGET_USER/.openvscode-server/extensions/ --install-extension "${ext}"
done

sudo chown $TARGET_USER -R /home/$TARGET_USER/.openvscode-server/extensions
sudo chgrp $GROUP_ID -R /home/$TARGET_USER/.openvscode-server/extensions
