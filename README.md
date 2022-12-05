# plx-to-kilosort
A bit of Matlab code to convert Plexon .plx files to something we can pass into kilosort

# Dependency
This code depends on the Plexon [OmniPlex and MAP Offline SDK Bundle](https://plexon.com/wp-content/uploads/2017/08/OmniPlex-and-MAP-Offline-SDK-Bundle_0.zip).
This is available from the [Plexon Software Downloads](https://plexon.com/software-downloads/#software-downloads-SDKs) page.

Once you have the OmniPlex and MAP Offline SDK Bundle:

 - Unzip it.
 - Find the `Matlab Offline Files SDK.zip` within.
 - Unzip that, too.
 - Add `OmniPlex and MAP Offline SDK Bundle`, with subfolders, to your Matlab path.
 - In Matlab, execute `build_and_verify_mexPlex` to compile the `mexPlex` function.

Once that works, you should be ready to proceed.

# 