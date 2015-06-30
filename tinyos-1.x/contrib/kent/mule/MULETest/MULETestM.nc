/** MULETestM.nc
 *
 * This app sends counter values out over the radio, and tracks the number
 * of packets that have been lost.
 * Probably on works under TOSSIM, which is fine because I don't care if it
 * doesn't work on real motes.
 * 
**/

includes IntMsg;

module MULETestM {
  provides interface StdControl;

  uses {
    interface ReceiveMsg as ReceiveIntMsg;
    interface StdControl as CommControl;
  }
} implementation {

  int16_t lastReceived[TOSH_NUM_NODES];
  uint32_t numLost[TOSH_NUM_NODES];

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < TOSH_NUM_NODES; i++) {
      lastReceived[i] = -1;
      numLost[i] = 0;
    }
    
    return call CommControl.init();
  }

  command result_t StdControl.start() {
    return call CommControl.start();
  }

  command result_t StdControl.stop() {
    return call CommControl.stop();
  }

  event TOS_MsgPtr ReceiveIntMsg.receive(TOS_MsgPtr m) {
    IntMsg *message = (IntMsg *)m->data;
    int val = message->val, src = message->src;

    if (lastReceived[src] == -1) 
      lastReceived[src] = val;
    else {
      int diff = val - lastReceived[src] - 1; 
      if (val == lastReceived[src])  {
	dbg(DBG_USR2, "MULETestM: received %d from %d\n", val, src);
	dbg(DBG_USR2, "DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!DUP!\n");

	return m;
      }
      numLost[src] += diff;
      lastReceived[src] = val;
    }
    
    dbg(DBG_USR2, "MULETestM: received %d from %d, total lost %d\n", 
	val, src, numLost[src]);

    return m;
  }

}
