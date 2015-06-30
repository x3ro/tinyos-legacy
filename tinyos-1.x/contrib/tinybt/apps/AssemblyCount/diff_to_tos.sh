#!/bin/bash

# Simple script to figure out what Martin have changed... :-)

echo "***************************************************************************"
echo HCICore interface
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HCICoreC.nc HCICore0C.nc 
echo "***************************************************************************"
echo HCICore module
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HCICoreM.nc HCICore0M.nc
echo "***************************************************************************"
echo HCIPacket interface
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HCIPacketC.nc HCIPacket0C.nc
echo "***************************************************************************"
echo HCIPacket module
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HCIPacketM.nc HCIPacket0M.nc
echo "***************************************************************************"
echo HPLBTUART interface
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HPLBTUARTC.nc HPLBTUART0C.nc
echo "***************************************************************************"
echo HPLBTUART module
echo "***************************************************************************"
diff -u ../../tos/platform/btnode2_2/HPLBTUARTM.nc HPLBTUART0M.nc

