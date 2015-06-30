// $Id: autobuild.sh,v 1.3 2008/01/14 12:42:34 david_henry Exp $
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

#!/usr/bin/bash
#autoincrementing of nodeid
source $HOME/nextid.sh
# Assumes presence of environment variable CC2420_DEF_CHANNEL
echo "Building nodeid $NEXTID channel number $CC2420_DEF_CHANNEL"
/opt/tinyos-1.x/tools/make/msp/set-mote-id --objcopy msp430-objcopy --objdump msp430-objdump --target ihex build/tmoteinvent/main.ihex build/tmoteinvent/main.ihex.out-$NEXTID TOS_LOCAL_ADDRESS=$NEXTID CC2420_CHANNEL=$CC2420_DEF_CHANNEL
echo "Burning main.ihex.out-$NEXTID"
# truncate EOF from TOSboot
sed '/^:00000001FF$/ d' /opt/tinyos-1.x/tos/lib/Deluge/TOSboot/build/telosb/main.ihex > both.ihex
# add your application
cat build/tmoteinvent/main.ihex.out-$NEXTID >> both.ihex
# Burn via JTAG
msp430-downloader both.ihex
echo "#!/usr/bin/bash" > $HOME/nextid.sh
echo "export NEXTID=$[$NEXTID+1]" >> $HOME/nextid.sh
#
