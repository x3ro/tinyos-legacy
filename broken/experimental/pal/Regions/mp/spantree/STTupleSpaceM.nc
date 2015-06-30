module STTupleSpaceM {
  provides {
    interface StdControl;
    interface TupleSpace;
  }
  uses {
    interface Tuning;
    interface SendMsg as BroadcastSend;
    interface ReceiveMsg as BroadcastReceive;
  }

} implementation {

  struct TOS_Msg send_packet;
  bool send_busy;

  enum {
    STTS_HT_SIZE = 64,
    STTS_HT_MASK = 0x3f,
    EMPTY_ADDR = 0xffff,
  };

  typedef struct {
    uint16_t srcaddr;
    uint8_t key;
    uint8_t data_len;
    uint8_t data[TUPLESPACE_BUFLEN];
  } ht_entry;
  ht_entry hashtable[STTS_HT_SIZE];
  int cur_anyaddr_bucket = 0;

  static uint8_t ht_bucket_num(uint16_t addr, uint8_t key) {
    return (addr ^ key) & STTS_HT_MASK;
  }
  static ht_entry *ht_bucket(uint16_t addr, uint8_t key) {
    return &hashtable[ht_bucket_num(addr, key)];
  }

  static void initialize() {
    int i;

    send_busy = FALSE;
    for (i = 0; i < STTS_HT_SIZE; i++) {
      hashtable[i].srcaddr = EMPTY_ADDR;
    }
  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    initialize();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  static void putLocal(uint16_t addr, ts_key_t key, void *buf, int buflen) {
    ht_entry *bucket = ht_bucket(addr, key);
    bucket->srcaddr = addr;
    bucket->key = key;
    memcpy(bucket->data, buf, buflen);
    bucket->data_len = buflen;
  }

  command result_t TupleSpace.get(ts_key_t key, uint16_t moteaddr, void *buf) {
    if (moteaddr == TUPLESPACE_ANYADDR || 
	moteaddr == TUPLESPACE_ANYADDR_CLEAR) {
      while (cur_anyaddr_bucket < STTS_HT_SIZE) {
	ht_entry *entry = &hashtable[cur_anyaddr_bucket];
	cur_anyaddr_bucket++;
	if (entry->key == key && entry->srcaddr != EMPTY_ADDR) {
	  dbg(DBG_USR1, "STTS: Matching TUPLESPACE_ANYADDR with mote %d key %d\n", entry->srcaddr, entry->key);
	  memcpy(buf, entry->data, entry->data_len);
	  signal TupleSpace.getDone(key, entry->srcaddr, buf, entry->data_len, SUCCESS);
	  if (moteaddr == TUPLESPACE_ANYADDR_CLEAR) {
	    entry->srcaddr = EMPTY_ADDR; // Clear it out
	  }
	  return SUCCESS;
	}
      }
      dbg(DBG_USR1, "STTS: No buckets match TUPLESPACE_ANYADDR for key %d\n", key);
      cur_anyaddr_bucket = 0;
      return FAIL;

    } else {
      ht_entry *bucket = ht_bucket(moteaddr, key);
      dbg(DBG_USR1, "STTS: Reading mote %d key %d\n", moteaddr, key);
      if (bucket->srcaddr != moteaddr || bucket->key != key) return FAIL;
      memcpy(buf, bucket->data, bucket->data_len);
      signal TupleSpace.getDone(key, moteaddr, buf, bucket->data_len, SUCCESS);
      return SUCCESS;
    }
  }

  command result_t TupleSpace.put(ts_key_t key, void *buf, int buflen) {
    dbg(DBG_USR1, "STTS: Setting mote %d key %d\n", TOS_LOCAL_ADDRESS, key);

    // Put locally
    if (key >= TUPLESPACE_MAX_KEY) return FAIL;
    if (buflen > TUPLESPACE_BUFLEN) return FAIL;
    putLocal(TOS_LOCAL_ADDRESS, key, buf, buflen);

    // Broadcast data
    if (!send_busy) {
      SpanTreeRegion_TSMsg *msg = (SpanTreeRegion_TSMsg *)&send_packet.data;
      msg->srcaddr = TOS_LOCAL_ADDRESS;
      msg->key = key;
      msg->data_len = buflen;
      memcpy(msg->data, buf, buflen);
      send_busy = TRUE;
      if (!call BroadcastSend.send(TOS_BCAST_ADDR, sizeof(SpanTreeRegion_TSMsg), &send_packet)) {
	dbg(DBG_USR1, "STTS: Can't broadcast put() message\n");
	send_busy = FALSE;
      }
    }
    dbg(DBG_USR1, "STTS: put done: key %d len %d\n", key, buflen);
    return SUCCESS;
  }

  event result_t BroadcastSend.sendDone(TOS_MsgPtr msg, result_t success) {
    send_busy = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr BroadcastReceive.receive(TOS_MsgPtr msg) {
    SpanTreeRegion_TSMsg *tsmsg = (SpanTreeRegion_TSMsg *)msg->data;
    dbg(DBG_USR1, "STTS: broadcast receive: node %d key %d len %d\n", 
	tsmsg->srcaddr, tsmsg->key, tsmsg->data_len);
    putLocal(tsmsg->srcaddr, tsmsg->key, tsmsg->data, tsmsg->data_len);
    return msg;
  }


}

