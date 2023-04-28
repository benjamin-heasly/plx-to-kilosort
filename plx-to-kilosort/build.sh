#!/bin/sh

set -e

sudo docker build -t ninjaben/plx-to-kilosort:local .

# sudo docker run -ti --rm ninjaben/plx-to-kilosort:local /bin/bash

# Run a container locally to check if mexPlex is present and runnable.
# Since this step actually runs Matlab, we'll need to configure a license.
# This assumes a local ./licence.lic issued for a local MAC address.
# There are other ways to set up the Matlab license with Docker, too: https://hub.docker.com/r/mathworks/matlab
LICENSE_MAC_ADDRESS=$(cat /sys/class/net/en*/address)
LICENSE_FILE="$(pwd)/license.lic"
sudo docker run --rm \
  --mac-address "$LICENSE_MAC_ADDRESS" \
  -v $LICENSE_FILE:/licenses/license.lic \
  -e MLM_LICENSE_FILE=/licenses/license.lic \
  -v "/home/ninjaben/Desktop/codin/gold-lab/plexon_data/MrM:/home/matlab/MrM" \
  ninjaben/plx-to-kilosort:local \
  -batch "success = testMexPlex()"

# Local test to convert a .plx file.
sudo docker run --rm \
  --mac-address "$LICENSE_MAC_ADDRESS" \
  -v $LICENSE_FILE:/licenses/license.lic \
  -e MLM_LICENSE_FILE=/licenses/license.lic \
  -v "/home/ninjaben/Desktop/codin/gold-lab/plexon_data/MrM:/home/matlab/MrM" \
  ninjaben/plx-to-kilosort:local \
  -batch "[chanMapFile, binFile, opsFile] = plxToKilosort('/home/matlab/MrM/Raw/MM_2022_11_28C_V-ProRec.plx', '/home/matlab/MrM/Kilosort', 'chanY', linspace(0, 2250, 16), 'tRange', [0, 30], 'ops', {'fproc', '/home/matlab/kilosortScratch/temp_wh2.dat'})"

sudo docker run --rm \
  --mac-address "$LICENSE_MAC_ADDRESS" \
  -v $LICENSE_FILE:/licenses/license.lic \
  -e MLM_LICENSE_FILE=/licenses/license.lic \
  -v "/home/ninjaben/Desktop/codin/gold-lab/plexon_data/MrM:/home/matlab/MrM" \
  ninjaben/plx-to-kilosort:local \
  -batch "[chanMapFile, binFile, opsFile] = plxToKilosort('/home/matlab/MrM/Raw/MM_2022_08_05_REC.plx', '/home/matlab/MrM/Kilosort', 'chanY', linspace(0, 2250, 16), 'tRange', [0, 30], 'connected', true(6,1))"
