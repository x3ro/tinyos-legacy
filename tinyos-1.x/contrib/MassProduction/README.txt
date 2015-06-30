// $Id: README.txt,v 1.2 2008/01/14 12:32:06 david_henry Exp $
/*
 * Copyright (c) 2008 Zickel Engineering
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached ZICKEL-LICENSE
 * file. If you do not find these files, copies can be found at
 * http://www.zickel.net/ZICKEL-LICENSE.txt and by emailing info@zickel.net.
 */

/**
 * @author David Henry, Zickel Engineering <info@zickel.net>
 */

This method provides a simple way to initialize a number of motes, each with a unique Node ID.
Optionally it is possible th change the default radio channel number.
No recompilation of code is necessary as this method relies on the use of the
set-mote-id script which, in fact, does more than its name implies.

set-mote-id is used to change the value of any symbol in the .data section of
a loadable file, such as main.exe.

Environment
===========
This method was developed in the Moteiv Boomerang tool kit. As burning was
done via JTAG and msp430-downloader, there is an intermediate process to
concatenate the TOSBoot binary to the application binary. If you are burning
via USB this is taken care of automatically.

Methodology
===========
A unique ID is generated from the nextid.sh script, which is itself regenerated
by the autobuild.sh script.
autobuild.sh generates a new ihex file from the generic main.exe file. It has
a new value of TOS_LOCAL_ADDRESS and, optionally, CC2420_CHANNEL. This line
can be modified to alter any symbol in the loadable file.
The new ihex file is burned to the mote.
After completion of burning, the value of NEXTID is incremented as a new copy
of nextid.sh generated.
