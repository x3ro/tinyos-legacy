includes Location;

module LocationM {
  provides interface Location;
  uses interface Timer;
  uses interface SendMsg;
  uses interface ReceiveMsg;

} implementation {

  enum {
    TIMER_RATE = 1000,
    TIMER_BROADCAST_COUNT = 10;
    MAX_NEIGHBORS = 16,
  };

  struct neighbor_data {
    uint16_t addr;
    point location;
  } neighbors[MAX_NEIGHBORS];

  int timer_ticks;
  struct TOS_Msg send_packet;
  bool send_busy, location_set;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    int i;
    send_busy = FALSE;
    location_set = FALSE;

    for (i = 0; i < MAX_NEIGHBORS; i++) {
      neighbors[i].addr = 0;
    }

    return call Timer.start(TIMER_REPEAT, TIMER_RATE);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  command result_t Location.set_local_location(point *loc) {
    LocationMsg *lm = (LocationMsg*)send_packet.data;
    lm->sourceaddr = TOS_LOCAL_ADDRESS;
    lm->location.x = loc->x;
    lm->location.y = loc->y;
    location_set = TRUE;
    return SUCCESS;
  }

  command result_t Location.get_location(uint16_t addr, point *loc) {
    int i;
    if (addr == TOS_LOCAL_ADDRESS) {
      if (location_set) {
	*loc = lm->location;
	return SUCCESS;
      } else {
	return FAIL;
      }
    }

    for (i = 0; i < MAX_NEIGHBORS; i++) {
      if (neighbors[i].addr == addr) {
	*loc = neighbors[i].location;
	return SUCCESS;
      }
    }
    return FAIL;
  }

  task void doBroadcast() {
    if (send_busy) return;
    if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(LocationMsg), &send_packet) == SUCCESS) {
      send_busy = TRUE;
    }
  }

  event result_t Timer.fired() {
    timer_ticks++;
    if (timer_ticks % TIMER_BROADCAST_COUNT == 0) {
      post doBroadcast();
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    send_busy = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr recv_packet) {
    LocationMsg *lm = (LocationMsg *)recv_packet->data;
    int i;

    for (i = 0; i < MAX_NEIGHBORS; i++) {
      if (neighbors[i].addr == lm->sourceaddr) break;
      if (neighbors[i].addr == -1) break;
    }
    if (i == MAX_NEIGHBORS) {
      // Need to evict a neighbor - choose random
      i = (call Random.rand()) % NUM_NEIGHBORS;
    }
    neighbors[i].addr = lm->sourceaddr;
    neighbors[i].location = lm->location;
    return recv_packet;
  }

}


