File:  minitasks/02/ucb/routing/README.txt
Authors:  Cory Sharp
Version:  $Revision: 1.4 $ $Date: 2002/12/15 10:38:58 $
Document created on:  Dec 9, 2002

Here's a quick summary of the various files you'll find in this directory.


    AM.h

Added a void* for the RoutingMsg_t associated with the current TOS_Msg in the
internal accounting section of that structure.  This lets us easily convert
from TOS's SendMsg.sendDone(TOS_Msg*,result_t) to NestArch's
RoutingSend.sendDone(RoutingMsg_t*,result_t).


    AM.patch

Diff file of the above for easily updating the local AM.h when/if TOS's AM.h
changes.


    BerkeleyRouting.nc

A skeleton NestArch routing implementation, which is currently just a proof of
sanity of the proposed architecture.  This routing implementation may be
stacked or chained because it both provides and uses the general-purpose
NestArch Routing interfaces.


    Routing.h

All typedefs, structs, unions, and enums relating to the NestArch routing
proposal.


    RoutingGetDestination.nc
    RoutingGetHopCount.nc
    RoutingGetSourceAddress.nc
    RoutingGetTimeStamp.nc
    RoutingGetType.nc

Interface extensions for providing additional information and configuration
that may be exposed by a routing component.


    RoutingReceive.nc
    RoutingSend.nc

The general-purpose NestArch Routing send and receive interfaces that take the
union RoutingDestination_t as the routing destination.


    RoutingSendByAddress.nc
    RoutingSendByBroadcast.nc
    RoutingSendByCBR.nc
    RoutingSendByGeo.nc

Specialized send interfaces that take some particular routing destination
datatype as the routing destination.


    RoutingSendByAddressM.nc
    RoutingSendByBroadcastM.nc
    RoutingSendByCBRM.nc
    RoutingSendByDirectionM.nc
    RoutingSendByLocationM.nc

Specialized send modules that take some particular routing destination semantic
as the routing destination and forwards appropriately to the general-purpose
NestArch Routing send and receive interfaces.


    TinyOSRoutingM.nc

This is a translation layer from the general-purpose NestArch Routing
interfaces to TinyOS's GenericComm.  With this module, no other routing
components need to know about any of TinyOS's communication API's.

