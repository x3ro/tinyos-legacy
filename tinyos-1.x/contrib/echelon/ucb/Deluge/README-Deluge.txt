
Deluge Network Reprogramming

- Project members/groups:
    * Jonathan Hui <jwhui@cs.berkeley.edu>

- This directory contains the necessary services to enable binary code
propagation over the network and reboot them. Note that the current
implementation of Deluge is more of a proof-of-concept which
demonstrates the ability to reprogram nodes over the network. There
are many issues to work out before it can readily be used in real
deployments.

- To setup the Deluge tools, create the directory net/tinyos/deluge
and copy all files in 'delugetools' into it.

- The TestDeluge application provides a simple example of how to
include the Deluge service.

- Only those nodes initially programmed with Deluge and the
appropriate bootloader can be reprogrammed over the network. We
currently support the mica2 and mica2dot platforms and the bootloaders
are in the bootloader directory. Use the following process to add
Deluge support to a node.
    1) Download the application with Deluge.
    2) Download the appropriate bootloader with uisp.

- To reprogram the network, the new binary image must be downloaded to
a source node with Deluge installed. Because Deluge is epidemic, this
source node need not be connected to the network when downloading the
new binary image to the source node. The MOTECOM environment variable
must be set appropriately (refer to the TinyOS tutorial for details).
    $ java net.tinyos.deluge.Download --srecfile <srecfile>
    $ java net.tinyos.deluge.Download --reboot

- General Action Items:
    * Reduce memory utilization
    * Better support for rolling over to a new version
    * Testing at larger network scales

- Noted Changes:
    04.16.04: Removed need to zero out flash before installing Deluge
    04.20.04: Moved away from GenericCommPromiscuous to support GenericComm apps

