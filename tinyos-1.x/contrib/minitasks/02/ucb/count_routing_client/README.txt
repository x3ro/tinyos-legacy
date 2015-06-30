File:  minitasks/02/ucb/count_routing_client/README.txt
Authors:  Cory Sharp
Version:  $Revision: 1.2 $ $Date: 2003/01/13 03:12:55 $
Document created on:  Dec 9, 2002

Description:  Receive a counter over the radio via NestArch Routing then
display that counter on the LED's.


Here's a quick summary of the various files you'll find in this directory.


    AppCount.nc

The applicaiton-level wirings.  Note that this file knows nothing of the
particular configuration of the routing components, only that at the very top
of the routing chain RoutingSendByBroadcast and RoutingReceive are available.


    AppCountM.nc

Implementation code for AppCount.nc.  Only the top-level RoutingSendByBroadcast
and RoutingReceive are known to this module.


    RoutingC.nc

Wiring connecting from TinyOS's GenericComm up to the interfaces promised in
the module provides section.  This is the only application file that requires
information of the routing chain.

