#!/bin/sh

set -e

sudo docker build -t ninjaben/plx-to-kilosort:local .

# sudo docker run -ti --rm ninjaben/plx-to-kilosort:local /bin/bash

# Run a container locally to check if mex gpu functions are present and runnable.
# Since this step actually runs Matlab, we'll need to configure a license.
# This assumes a local ./licence.lic issued for a local MAC address.
# There are other ways to set up the Matlab license with Docker, too: https://hub.docker.com/r/mathworks/matlab
LICENSE_MAC_ADDRESS=$(cat /sys/class/net/en*/address)
LICENSE_FILE="$(pwd)/license.lic"
sudo docker run --rm \
  --mac-address "$LICENSE_MAC_ADDRESS" \
  -v $LICENSE_FILE:/licenses/license.lic \
  -e MLM_LICENSE_FILE=/licenses/license.lic \
  ninjaben/plx-to-kilosort:local \
  -batch "success = testMexPlex()"
