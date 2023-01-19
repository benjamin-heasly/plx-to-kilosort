#!/bin/sh

set -e

# This is adapted from build_and_verify_mexPlex.m from the plexon Matlab Offline Files SDK.
# The original runs in Matlab to compile mexPlex mex-functions.
# This version runs in the plain-old-shell outside of Matlab.
# Doing this avoids having to launch/license Matlab during our Docker image build.

# The original Matlab script ran:
#   mex -output mexPlex -outdir .. PlexMethods.cpp
# For this add the "-v" flag and capture the verbose output, see mex-v-output.txt.
# Now we just copy over the relevant parts to run from here.
# The result will be /home/matlab/Matlab-Offline-Files-SDK/mexPlex.mexa64

# Creating this tmp dir lets us run the mex commands verbatim.
mkdir -p /tmp/mex_15474392659988_1/

export INCLUDE="/usr/lib/gcc/x86_64-linux-gnu/9/include;/usr/include/c++/9;/usr/include/c++/9/x86_64-linux-gnu;/usr/include/c++/9/backward"

# Building with 'g++'.
/usr/bin/g++ -c -DMATLAB_DEFAULT_RELEASE=R2017b  -DUSE_MEX_CMD   -D_GNU_SOURCE -DMATLAB_MEX_FILE  -I"/opt/matlab/R2022b/extern/include" -I"/opt/matlab/R2022b/simulink/include" -fexceptions -fPIC -fno-omit-frame-pointer -pthread -std=c++11 -O2 -fwrapv -DNDEBUG "/home/matlab/Matlab-Offline-Files-SDK/mexPlex/PlexMethods.cpp" -o /tmp/mex_15474392659988_1/PlexMethods.o
/usr/bin/g++ -c -DMATLAB_DEFAULT_RELEASE=R2017b  -DUSE_MEX_CMD   -D_GNU_SOURCE -DMATLAB_MEX_FILE  -I"/opt/matlab/R2022b/extern/include" -I"/opt/matlab/R2022b/simulink/include" -fexceptions -fPIC -fno-omit-frame-pointer -pthread -std=c++11 -O2 -fwrapv -DNDEBUG "/opt/matlab/R2022b/extern/version/cpp_mexapi_version.cpp" -o /tmp/mex_15474392659988_1/cpp_mexapi_version.o
/usr/bin/g++ -pthread -Wl,--no-undefined  -shared -O -Wl,--version-script,"/opt/matlab/R2022b/extern/lib/glnxa64/c_exportsmexfileversion.map" /tmp/mex_15474392659988_1/PlexMethods.o /tmp/mex_15474392659988_1/cpp_mexapi_version.o   -lstdc++ -Wl,--as-needed -Wl,-rpath-link,/opt/matlab/R2022b/bin/glnxa64 -L"/opt/matlab/R2022b/bin/glnxa64" -Wl,-rpath-link,/opt/matlab/R2022b/extern/bin/glnxa64 -L"/opt/matlab/R2022b/extern/bin/glnxa64" -lMatlabDataArray -lmx -lmex -lm -lmat -o /home/matlab/Matlab-Offline-Files-SDK/mexPlex.mexa64
# Recompile embedded version with '-DMATLAB_MEXCMD_RELEASE=R2017b'
/usr/bin/g++ -c -DMATLAB_DEFAULT_RELEASE=R2017b  -DUSE_MEX_CMD   -D_GNU_SOURCE -DMATLAB_MEX_FILE  -I"/opt/matlab/R2022b/extern/include" -I"/opt/matlab/R2022b/simulink/include" -fexceptions -fPIC -fno-omit-frame-pointer -pthread -std=c++11 -O2 -fwrapv -DNDEBUG "/opt/matlab/R2022b/extern/version/cpp_mexapi_version.cpp" -o /tmp/mex_15474392659988_1/cpp_mexapi_version.o -DMATLAB_MEXCMD_RELEASE=R2017b
/usr/bin/g++ -pthread -Wl,--no-undefined  -shared -O -Wl,--version-script,"/opt/matlab/R2022b/extern/lib/glnxa64/c_exportsmexfileversion.map" /tmp/mex_15474392659988_1/PlexMethods.o /tmp/mex_15474392659988_1/cpp_mexapi_version.o   -lstdc++ -Wl,--as-needed -Wl,-rpath-link,/opt/matlab/R2022b/bin/glnxa64 -L"/opt/matlab/R2022b/bin/glnxa64" -Wl,-rpath-link,/opt/matlab/R2022b/extern/bin/glnxa64 -L"/opt/matlab/R2022b/extern/bin/glnxa64" -lMatlabDataArray -lmx -lmex -lm -lmat -o /home/matlab/Matlab-Offline-Files-SDK/mexPlex.mexa64

# Delete the tmp dir to reduce image size.
rm -rf /tmp/mex_15474392659988_1/
