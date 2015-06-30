/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "sp.h"
#include "sp_cc2420.h"

/**
 * Implementation of the link primitives that support SP.
 * <p>
 * CC2420Synchronized manages the underlying CC2420 radio stack and sets
 * up duty cycling activities.  By default, CC2420Synchronized uses
 * CC2420AlwaysOnM.  See the documentation inside CC2420AlwaysOnM for more
 * information about how it works.
 * <p>
 * To use the low power duty cycled implementation, CC2420SyncMojoM,
 * you have the following two options:
 * <ol>
 * <li> Compile your application with <tt>make &lt;platform&gt; lowpower</tt>
 *      which will pull in both CC2420SyncMojoM and NetSyncC network
 *      protocol, or
 * <li> Add the following define to your makefile which will pull in the
 *      synchronization code in CC2420SyncMojoM but <b>not</b> NetSyncC:<br>
 *      <tt>CFLAGS += -DCC2420_SYNC</tt>
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration CC2420SynchronizedC {
  provides {
    interface StdControl;
    interface SPSend;
    interface SPLinkStats;
    interface SPLinkEvents;
    interface SPInterface;
  }
  uses {
    interface ObjectPool<sp_message_t> as Pool;
    interface ObjectPoolEvents<sp_message_t> as PoolEvents;
  }
}
implementation {
  components 
#ifdef CC2420_SYNC
  CC2420SyncSaneC as Impl
#else
  CC2420SyncAlwaysOnC as Impl
#endif
  ;

  StdControl = Impl;
  SPSend = Impl;
  SPLinkStats = Impl;
  SPLinkEvents = Impl;
  SPInterface = Impl;

  Pool = Impl;
  PoolEvents = Impl;

}
