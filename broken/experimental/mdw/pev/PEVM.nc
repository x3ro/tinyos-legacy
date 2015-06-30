/* Author: Matt Welsh
 * Last updated: 1 Nov 2002
 * 
 */

includes AM;
includes Multihop;
includes Collect;

/**
 * 
 **/
module PEVM {
  provides interface StdControl;
  uses {
    interface ADC;
    interface Timer;
    interface Leds;
    interface Send as SendToRoot;
    interface Collect;
    interface Location;
  }
}
implementation {

  enum {
    TIMER_RATE = 1000,
    TIMER_GETADC_COUNT = 5,
    SENSOR_THRESHOLD = 0x300,
    COLLECT_SIZE = 10,
  };

  int timer_ticks;
  mote_reading my_reading;
  mote_reading neighbor_readings[COLLECT_SIZE];
  struct TOS_Msg send_packet;
  bool send_busy;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    send_busy = FALSE;
    return call Timer.start(TIMER_REPEAT, TIMER_RATE);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      call ADC.getData();
    }
    return SUCCESS;
  }

  bool is_maximum(mote_reading my_reading, mote_reading *neigh_readings, int neigh_size) {
    mote_reading *max = NULL;
    int i;
    for (i = 0; i < neigh_size; i++) {
      if (max == NULL) max = &neigh_readings[i];
      else if (neigh_readings[i].reading > max.reading) 
	max = &neigh_readings[i];
    }
    if (max->reading > my_reading.reading) return false;
    else if (max->reading < my_reading.reading) return true;
    // If equal, break tie
    if (max->addr < TOS_LOCAL_ADDRESS) return false;
    else return true;
  }

  bool calc_centroid(mote_reading my_reading, mote_reading *neigh_readings, int neigh_size, point *centroid) {
    float total_mass;
    int i;
    float cx, cy;
    point loc, my_loc;

    total_mass = my_reading.reading;
    if (!call Location.get_location(my_reading.addr, &my_loc)) return NULL;
    cx = my_loc.x * my_reading.reading;
    cx = my_loc.y * my_reading.reading;
    for (i = 0; i < neigh_size; i++) {
      if (!call Location.get_location(neigh_readings[i].addr, &loc)) continue;
      cx += loc.x * neigh_readings[i].reading;
      cy += loc.y * neigh_readings[i].reading;
      total_mass += neigh_readings[i].reading;
    }
    cx /= total_mass;
    cy /= total_mass;
    centroid->x = cx;
    centroid->y = cy;
    return SUCCESS;
  }

  bool send_to_root(uint8_t *data, int len) {
    int i;
    uint16_t length;
    uint8_t *outdata = (uint8_t *)call Send.getBuffer(&send_packet, &length);
    if (length > len) return FAIL;
    for (i = 0; i < len; i++) {
      outdata[i] = data[i];
    }
    if (call Send.send(&send_packet, len) == SUCCESS) {
      send_busy = TRUE;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  task void processTask() {
    neighbor_size = COLLECT_SIZE;
    if (call Collect.collect(my_reading, neighbor_readings, &neighbor_size) != SUCCESS) {
      return;
    }
    ismax = is_maximum(my_reading, neighbor_readings, neighbor_size);
    if (isMax) {
      if (calc_centroid(my_reading, neighbor_readings, neighbor_size, &centroid)) {
	send_to_root(&centroid, sizeof(centroid));
      }
    }
  }

  event result_t ADC.dataReady(uint16_t data) {
    int neighbor_size;
    bool ismax;
    point centroid;

    my_reading.reading = data;
    my_reading.addr = TOS_LOCAL_ADDRESS;

    if (data < SENSOR_THRESHOLD) return;

    post processTask();
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, bool success) {
    call Leds.greenToggle();
    send_busy = FALSE;
    return SUCCESS;
  }

}


