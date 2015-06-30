File:  minitasks/02/ucb/count_routing_server/README.txt
Authors:  Cory Sharp
Version:  $Revision: 1.1 $ $Date: 2002/12/10 05:28:04 $
Document created on:  Dec 9, 2002

Description:  Increment a counter, both displaying it on the LED's and sending
over the radio via NestArch Routing Broadcast.


Here's a quick summary of the various files you'll find in this directory.


    AppCount.nc

The applicaiton-level wirings.  Note that this file knows nothing of the
particular configuration of the routing components, only that at the very top
of the routing chain RoutingSendByBroadcast and RoutingReceive are available.


    AppCountM.nc

Implementation code for AppCount.nc.  Only the top-level RoutingSendByBroadcast
and RoutingReceive are known to this module.


    AppRoutingM.nc

Wiring connecting from TinyOS's GenericComm up to the interfaces promised in
the module provides section.  This is the only application file that requires
information of the routing chain.

