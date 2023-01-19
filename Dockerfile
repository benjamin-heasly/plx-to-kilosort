# Start with the MATLAB base image (published on Docker Hub).
FROM mathworks/matlab:r2022b

# Obtain the Plexon OmniPlex and MAP Offline SDK Bundle.
# https://plexon.com/wp-content/uploads/2017/08/OmniPlex-and-MAP-Offline-SDK-Bundle_0.zip
WORKDIR /home/matlab/
RUN wget -q "https://plexon.com/wp-content/uploads/2017/08/OmniPlex-and-MAP-Offline-SDK-Bundle_0.zip" \
    && unzip "OmniPlex-and-MAP-Offline-SDK-Bundle_0.zip" \
    && unzip "OmniPlex and MAP Offline SDK Bundle/Matlab Offline Files SDK.zip" \
    && mv "Matlab Offline Files SDK" /home/matlab/Matlab-Offline-Files-SDK \
    && rm -rf "OmniPlex and MAP Offline SDK Bundle" \
    && rm "OmniPlex-and-MAP-Offline-SDK-Bundle_0.zip"

# Get the build script that to compile the Plexon mexPlex mex-function.
USER root
COPY ./mex-build/mex-build.sh /home/matlab/mex-build.sh
RUN chown matlab:matlab /home/matlab/mex-build.sh && chmod 755 /home/matlab/mex-build.sh

# Build mexPlex.
USER matlab
WORKDIR /home/matlab
RUN /home/matlab/mex-build.sh

# Get the Matlab code for converting .plx files to kilosort's format.
COPY ./matlab /home/matlab/plx-to-kilosort

# Configure Matlab on startup.
COPY ./matlab/startup.m /home/matlab/Documents/MATLAB/startup.m
