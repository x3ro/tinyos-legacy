includes Strength;
includes RFTag;

module LocationNodeM {
  provides interface StdControl;
  uses {
    interface StdControl  as RadioControl;

    // Xnp allows for reprogramming over the radio
    interface Xnp;

    // local broadcast for gradient purposes
    interface SendMsg as SendGradient;
    // messages sent via BAP to the base-station.
    interface SendData as CommandToBase;

    // local receipt of local broadcast messages for gradients
    interface ReceiveMsg  as ReceiveGradient;
    // messages from the base-station to us
    interface Receive  as CommandFromBase;

    // Communication to/from the base-station host (eg, we are basestation)
    interface SendMsg    as BaseToHost;
    interface ReceiveMsg as HostToBase;

    // Communication between motes for signal strength calibration
    interface SendMsg    as SendPot;
    interface ReceiveMsg as ReceivePot;

    interface Receive as BaseReceiveCommand;
    interface SendData as BaseSendCommand;

    // Communication from the RFTag
    interface ReceiveMsg as ReceiveTag;

    // interface Pot;
    interface Random;

    interface IsBaseStation;

    interface Leds;
    interface Timer;
    interface CC1000Control;
  }
}

implementation {
  enum {
    // number of anchors to remember distance from
    MAX_ANCHORS =     11,
    // command numbers
    SET_ANCHOR =      1,
    GET_DISTANCE =    2,
    SET_POT =         3,
    REPLY =           4,
    RESET   =         5,
    TEST_RADIO =      6,
    POT_REPLY =       7,
    UPDATE =          8,
    TAG =             9,
    HELLO =           10,
    HELLO_ACK =       11,
    TEST_STAT =       12,
    TEST_STAT_REPLY = 13,
    TEST_STAT_JR =    14,
    SET_POT_MAP =     15,
    POT_MAP_REPLY =   16,
    // number of clock ticks between anchor broadcasts
    ANCHOR_INTERVAL        = 70,
    MAX_DELAY_MASK         = 0x1f,
    N_STRENGTHS            = 10,
    MAX_POT_VALUE          = N_STRENGTHS-1,
    DEFAULT_BASE_POT_VALUE = MAX_POT_VALUE,
    DEFAULT_POT_VALUE      = MAX_POT_VALUE/2,
    MAX_PAYLOAD            = 29,
    N_BROADCASTS           = 10,
    TEST_RELOAD            = 4,
    MAX_LOST_DELAY_MASK    = 32-1,
    MIN_LOST_DELAY         = 96,
    N_POT_REPEATS          = 5,
    MAX_NEIGHBORS          = 50,
    POT_MAP_LEN            = 8,
    MAX_STRENGTH_VALUE     = 0x3ff
  };

  enum {
    POT_TEST    = 0,
    POT_STATS   = 1,
    POT_REQUEST = 2
  };

  // pot record
  typedef struct {
    int16_t  id;                  // id of calibratee
    uint8_t  counts[N_STRENGTHS]; // counts at various strengths
  } __attribute__ ((packed)) pot_rec;

  // pot_stats record
  typedef struct {
    uint16_t neighbors[MAX_NEIGHBORS]; // id of senders
    uint16_t n_neighbors[N_STRENGTHS]; // 90 percentile neighbors
  } __attribute__ ((packed)) pot_stats_rec;

  // pot packet
  typedef struct {
    int16_t  source;                // id of sender
    int16_t  dest;                  // id of dest if applicable
    uint8_t  type;                  // kind of 
    union {
      uint8_t  value;               // signal strength
      uint8_t  counts[N_STRENGTHS]; // counts at various strengths
    };
  } __attribute__ ((packed)) pot_msg;

  // structure of command message
  typedef struct {
    char     unused; // used to be cmd_id
    uint16_t source;
    uint16_t dest;
    char     cmd_no;
    union {
      char  status;
      short anchor;
      uint8_t pot_value;
      struct {
	char     anchor_known;
	short    anchor;
	uint16_t distance;
	short    version;
      } reply;
      struct {
	short id;
	short time;
      } tag;
      struct {
	char    total;
	uint8_t sizes[N_STRENGTHS]; // neighborhood sizes at various strengths
      } hoods;
      struct {
	uint16_t pots[POT_MAP_LEN]; // pot setting cutoffs for various distances
      } pot_map;
    } args;
    unsigned short sig_strength;
  } __attribute__ ((packed)) command_msg;

  // structure of gradient message
  typedef struct {
    short    anchor;
    uint16_t distance;
    short    source;
    short    version;
  } __attribute__ ((packed)) gradient_msg;

  TOS_Msg pot_packet;
  TOS_Msg command_packet;
  TOS_Msg gradient_packet;
  TOS_Msg anchor_packet;
  TOS_Msg update;
  TOS_Msg hello;

  // anchor record
  typedef struct {
    int16_t  id;       // id of anchor
    uint16_t distance; // current working distance from corresponding anchor
    int16_t  version;  // version of corresponding working distance
    char     is_dirty; // need to relay?
  } __attribute__ ((packed)) anchor_rec;

  command_msg baseSendData;

  // reset flag triggering reset in tick
  char is_reset;
  // need to send hello messages
  char is_lost;
  int8_t lost_delay;
  // 1 if this node is an anchor, 0 otherwise
  char is_anchor;
  // true if radio calibration is in progress
  char  is_testing_radio;
  // remaining number of calibration tests
  char  test_count;
  // current radio strength in sanitized units
  char   now_pot_value;
  char   pot_value;
  int8_t pot_delay;
  int8_t pot_repeat_count;
  char   pot_pending;
  // number of signal strength tests at particular strength remaining
  char  n_broadcasts;
  // number of neighbors heard in signal strength experiments
  char  n_neighbors;
  // gradient count used in anchor only
  short version;
  // delay before broadcasting command packet
  char command_delay;
  // delay before broadcasting gradient packet
  char gradient_delay;
  // delay before broadcasting anchor packet
  short anchor_delay;
  // number of waves to send
  char anchor_repeat_count;
  // 1 if a base_send is in progress, 0 otherwise
  char is_base_send_pending;
  // 1 if a command is in progress, 0 otherwise
  char command_pending;
  // 1 if a gradient is in progress, 0 otherwise
  char gradient_pending;
  // 1 if a uart transmission is in progress, 0 otherwise
  char update_pending;
  // 1 if node is a base station, 0 otherwise
  bool is_base;

  // the position in the list to use for the next new anchor
  char next_anchor;
  // anchor records for recording to anchor distance etc
  anchor_rec anchors[MAX_ANCHORS];
  // record for signal strength experiments
  pot_rec       pot;
  // record for signal strength experiments
  pot_stats_rec pot_stats;
  
  uint16_t pot_map[POT_MAP_LEN];

  void update_host(anchor_rec* anchor);

  void reset_stats () {
    char i;
    pot.id = -1;
    for(i = 0; i < MAX_NEIGHBORS; i++) {
      pot_stats.neighbors[(int)i] = -1;
    }
    for(i = 0; i < N_STRENGTHS; i++) {
      pot.counts[(int)i]            = 0;
      pot_stats.n_neighbors[(int)i] = 0;
    }
    pot_delay        = -1;
    pot_repeat_count = -1;
    n_neighbors      = 0;
  }

  void reset () {
    char i;
    for(i = 0; i < MAX_ANCHORS; i++) {
      anchor_rec* a = &anchors[(int)i];
      a->id         = -1;
      a->distance   = 0xffff;
      a->version    = -1;
      a->is_dirty   = 0;
    }
    // default pot_map is return 1 for any strength
    for (i = 0; i < POT_MAP_LEN; i++)
      pot_map[(int)i] = 0;
    reset_stats();
    is_lost              = !is_base;
    lost_delay           = 0;
    next_anchor          = 0;
    is_anchor            = 0;
    version              = -1;
    command_delay        = -1;
    gradient_delay       = -1;
    anchor_delay         = ANCHOR_INTERVAL;
    anchor_repeat_count  = 0;
    is_testing_radio     = 0;
    test_count           = 0;
    pot_pending          = 0;
    command_pending      = 0;
    gradient_pending     = 0;
    update_pending       = 0;
    is_reset             = 0;
    is_base_send_pending = 0;
    call Leds.greenOn();
    call Leds.redOn();
    call Leds.yellowOn();
  }

  void set_radio_power (uint8_t pot_value_) {
    uint8_t power = signal_strength_settings[(int)pot_value_];
    call CC1000Control.SetRFPower(power);
  }

  command result_t StdControl.init() {
    // reduce the strength of the radio
    call Leds.redToggle();
    call Random.init();

    call Xnp.NPX_SET_IDS();

    is_base = (TOS_LOCAL_ADDRESS == 0);
    now_pot_value = is_base ? DEFAULT_BASE_POT_VALUE : DEFAULT_POT_VALUE;
    set_radio_power(now_pot_value);
    reset();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Leds.greenToggle();
    call IsBaseStation.setBase(is_base);
    call Timer.start(TIMER_REPEAT, 64); // tick16ps
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }  


  // this gets called when Xnp gets a radio message initiating a new program download
  event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP) {
    call Leds.yellowOn();
    call Timer.stop(); // kill off the state machine since we want everyone
    // quite while the download is happening in order to minimize collisions
    call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
    return SUCCESS;
  }

  // this gets called when the new program download is complete
  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP) {
    return SUCCESS;
  }




  // store the distance away from the anchor
  // if the anchor is already in the list, the distance will be updated
  // otherwise a new entry will be made
  void set_distance(short id, uint16_t dist, short vers) {
    char i;
    anchor_rec* anchor;
    for(i = 0; i < MAX_ANCHORS; i++) {
      anchor = &anchors[(int)i];
      if(anchor->id == id) 
	goto zupdate;
    }
    // not found, allocate a new one
    anchor     = &anchors[(int)next_anchor];
    anchor->id = id;
    next_anchor++;
    if(next_anchor == MAX_ANCHORS) 
      next_anchor = 0;
  zupdate:
    anchor->distance = dist;
    anchor->version  = vers;
    anchor->is_dirty = 1;    // requires updating neighbors
  }

  event TOS_MsgPtr BaseReceiveCommand.receive
      (TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
    if(update_pending == 0) {
      command_msg *packet, *opack;
      packet = (command_msg *)payload;
          
      // RELAY TO HOST THROUGH UART
      update.group                   = 0x7d;
      update.addr                    = TOS_UART_ADDR;
      update.length                  = MAX_PAYLOAD;
      update.type                    = 5; // to host

      opack                          = (command_msg*) update.data;
      memcpy(opack, packet, sizeof(command_msg));
      // opack->sig_strength            = msg->strength;

      call Leds.redToggle();     
      if(call BaseToHost.send(TOS_UART_ADDR, MAX_PAYLOAD, &update) == SUCCESS) {
	// call Leds.yellowToggle();
	// call Leds.greenToggle();
	update_pending = 1;
      } else {
	// TODO: PERHAPS RESEND LATER?
	call Leds.greenOff();
      }
    }

    return msg;
  }

  event result_t BaseSendCommand.sendDone(uint8_t* data, result_t success) {
    is_base_send_pending = 0;
    return success;
  }

  task void baseSend () {
    if(call BaseSendCommand.send((uint8_t*)&baseSendData, sizeof(command_msg)) 
         == SUCCESS) {
      call Leds.yellowToggle();  
    } else {
      call Leds.greenToggle();  
      is_base_send_pending = post baseSend();
    }
  }

  // Handle incoming messages from the base-station host.  Eg, the machine running
  // our java code.  The host will send commands to nodes, and receive commands
  // from nodes as replies.
  event TOS_MsgPtr HostToBase.receive(TOS_MsgPtr msg) {
    call Leds.redToggle();  
    if (!is_base_send_pending) {
      memcpy(&baseSendData, msg->data, sizeof(command_msg));
      is_base_send_pending = post baseSend();
    }
    return msg;
  }

  // command message received
  event TOS_MsgPtr CommandFromBase.receive
      (TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
    char i;
    command_msg *packet, *reply;

    call Leds.greenToggle();
    packet = (command_msg*) payload;

    // if the final destination is this node or the broadcast address
    // perform the correct action
    if(packet->dest == TOS_LOCAL_ADDRESS || packet->dest == TOS_BCAST_ADDR) {
      switch(packet->cmd_no) {
      case SET_ANCHOR:
	is_lost   = 0;
	is_anchor = packet->args.status;
	// if this node is an anchor, set the distance from itself to 0
	if(is_anchor) {	
	  call Leds.yellowToggle();	 
	  version += 1;
	  set_distance(TOS_LOCAL_ADDRESS,0,version);
	  anchor_delay        = ANCHOR_INTERVAL;
	  anchor_repeat_count = packet->args.status;
	}
	break;

      case GET_DISTANCE:
	if(command_delay == -1) {
	  is_lost = 0;
	  reply = (command_msg*) command_packet.data;
	  reply->source                  = TOS_LOCAL_ADDRESS;
	  // send the reply back to the source - IMPLICITLY BASE STATION NOW.
	  reply->dest                    = packet->source;
	  reply->cmd_no                  = REPLY;
	  reply->args.reply.anchor       = packet->args.anchor;
	  reply->args.reply.anchor_known = 0;
	  reply->args.reply.distance     = 0;
	  reply->args.reply.version      = -1;
	  for(i = 0; i < MAX_ANCHORS; i++) {
	    anchor_rec *anchor = &anchors[(int)i];
	    if(anchor->id == packet->args.anchor) {
	      reply->args.reply.anchor_known = 1;
	      reply->args.reply.distance     = anchor->distance;
	      reply->args.reply.version      = anchor->version;
	      break;
	    }
	  }
	
	  // This should really be hidden from us...
	  command_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;
	}
	break;

      case SET_POT:
	if (!(packet->dest == TOS_BCAST_ADDR && is_base)) {
	  now_pot_value = packet->args.pot_value;
	  set_radio_power(now_pot_value);
	  if (command_delay == -1) {
	    reply                 = (command_msg*) command_packet.data;
	    reply->source         = TOS_LOCAL_ADDRESS;
	    // send the reply back to the source - IMPLICITLY BASE STATION NOW.
	    reply->dest           = packet->source;
	    reply->cmd_no         = POT_REPLY;
	    reply->args.pot_value = now_pot_value;
	    command_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;
	  }
	}
	break;

      case SET_POT_MAP:
	if (!(packet->dest == TOS_BCAST_ADDR && is_base)) {
	  for (i = 0; i < POT_MAP_LEN; i++)
	    pot_map[(int)i] = packet->args.pot_map.pots[(int)i];
	  if (command_delay == -1) {
	    reply         = (command_msg*) command_packet.data;
	    reply->source = TOS_LOCAL_ADDRESS;
	    // send the reply back to the source - IMPLICITLY BASE STATION NOW.
	    reply->dest   = packet->source;
	    reply->cmd_no = POT_MAP_REPLY;
	    command_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;
	  }
	}
	break;

      case HELLO_ACK:
	is_lost = 0;
	break;

      case TEST_RADIO:
	// start calibration procedure
	reset_stats();
	call Leds.yellowToggle();
	call Leds.redToggle();
	is_testing_radio = 1;
	pot_value        = 0;
	n_broadcasts     = N_BROADCASTS;
	set_radio_power(pot_value);
	break;

      case TEST_STAT:
	// collect final stats
	call Leds.yellowToggle();
	if (command_delay == -1) {
	  call Leds.redToggle();
	  reply         = (command_msg*) command_packet.data;
	  reply->source = TOS_LOCAL_ADDRESS;
	  // send the reply back to the source - IMPLICITLY BASE STATION NOW.
	  reply->dest   = packet->source;
	  reply->cmd_no = TEST_STAT_REPLY;
	  reply->args.hoods.total = n_neighbors;
	  for (i = 0; i < N_STRENGTHS; i++) 
	    reply->args.hoods.sizes[(int)i] = pot_stats.n_neighbors[(int)i];
	  command_delay = (call Random.rand() & MAX_DELAY_MASK) + 1;
	}
	break;

      case TEST_STAT_JR:
	// collect local stats
	call Leds.yellowToggle();
	if (command_delay == -1) {
	  call Leds.redToggle();
	  reply         = (command_msg*) command_packet.data;
	  reply->source = TOS_LOCAL_ADDRESS;
	  // send the reply back to the source - IMPLICITLY BASE STATION NOW.
	  reply->dest   = packet->source;
	  reply->cmd_no = TEST_STAT_REPLY;
	  reply->args.hoods.total = pot.id;
	  for (i = 0; i < N_STRENGTHS; i++) 
	    reply->args.hoods.sizes[(int)i] = pot.counts[(int)i];
	  command_delay = (call Random.rand() & MAX_DELAY_MASK) + 1;
	}
	break;

      case RESET:
	is_reset = 1;
	break;
	
      default:
	break;
      }
    }

    return msg;
  }
 
  // get the distance measurement from the strength field of the message
  uint16_t get_distance(TOS_MsgPtr msg) {
    char i;
    int  x = /* MAX_STRENGTH_VALUE - */ msg->strength;
    for (i = 0; i < POT_MAP_LEN; i++) {
      if (x < pot_map[(int)i])
	return i + 1;
    }
    return 1; // should never happen
  }
 
  // pot message received
  event TOS_MsgPtr ReceivePot.receive(TOS_MsgPtr msg) {
    pot_msg* packet = (pot_msg*) msg->data;
    uint16_t src    = packet->source;
    uint16_t dst    = packet->dest;
    uint8_t  type   = packet->type;
    uint8_t  val    = packet->value;
    pot_msg* potsky;
    char     i;
    if (type != POT_TEST)
      call Leds.redToggle();
    switch (type) {
      // SIGNAL STRENGTH PACKET
    case POT_TEST:
      call Leds.redToggle();
      if (pot.id != src) {
	call Leds.yellowToggle();
	pot.id = src;
	for (i = 0; i < N_STRENGTHS; i++) 
	  pot.counts[(int)i] = 0;
      }
      if (val < N_STRENGTHS) {
	call Leds.greenToggle();
	pot.counts[val]++;
      }
      break;
      // NODE SIGNAL STRENGTH STATS REQUEST
    case POT_REQUEST:
      call Leds.yellowToggle();
      potsky         = (pot_msg*)&pot_packet.data;
      potsky->source = TOS_LOCAL_ADDRESS;
      potsky->dest   = pot.id;
      potsky->type   = POT_STATS;
      for (i = 0; i < N_STRENGTHS; i++) 
	potsky->counts[(int)i] = pot.counts[(int)i];
      pot_repeat_count = N_POT_REPEATS;
      pot_delay        = (call Random.rand() & MAX_DELAY_MASK) + 1;
      break;
      // NODE SIGNAL STRENGTH STATS REPLY
    case POT_STATS:
      // if (dst == TOS_LOCAL_ADDRESS) { // targetted towards me?
      potsky = (pot_msg*)&pot_packet.data;
      call Leds.greenToggle();
      for (i = 0; i < n_neighbors; i++)
	if (pot_stats.neighbors[(int)i] == src) // already found
	  goto done;
      pot_stats.neighbors[(int)(n_neighbors++)] = src;
      for (i = 0; i < N_STRENGTHS; i++) 
	if (packet->counts[(int)i] >= (int)(0.9*N_BROADCASTS))
	  // if (packet->counts[(int)i] > 0)
	  pot_stats.n_neighbors[(int)i]++;
      if (n_neighbors >= MAX_NEIGHBORS)
	n_neighbors = MAX_NEIGHBORS-1;
    done:
      // }
      break;
    }
    return msg;
  }

  // gradient message received
  event TOS_MsgPtr ReceiveGradient.receive(TOS_MsgPtr msg) {
    gradient_msg* packet = (gradient_msg*) msg->data;
    int   i;
    // if gradient packet is waiting to be sent, ignore message
    // calculate total distance
    uint16_t dist = packet->distance + get_distance(msg);
    short    vers = packet->version;
    call Leds.yellowToggle();
    // check if record exists for this anchor
    for(i = 0; i < MAX_ANCHORS; i++) {
      anchor_rec *anchor = &anchors[(int)i];
      if(anchor->id == packet->anchor) {
	uint16_t disti = anchor->distance;
	short    versi = anchor->version;
	if(vers >= versi) { // same or newer version?
	  if(dist < disti || vers > versi) {
	    // new version or new distance is smaller than stored distance, 
	    // so update stored distance and broadcast
	    call Leds.redToggle();
	    anchor->distance   = dist;
	    // reset the version for this anchor
	    anchor->version    = vers;
	    anchor->is_dirty   = 1;
	  }
	}
	return msg;
      }
    }
    // no record exists for this anchor, so add it and broadcast
    set_distance(packet->anchor, dist, vers);
    return msg;
  }
 
  // currently unused but could allow incremental gradient updates to the host
  void update_host(anchor_rec* anchor) {
    command_msg* pkt = (command_msg*) update.data;
    pkt->source                  = TOS_LOCAL_ADDRESS;
    pkt->cmd_no                  = REPLY;
    pkt->args.reply.anchor_known = 1;
    pkt->args.reply.anchor       = anchor->id;
    pkt->args.reply.distance     = anchor->distance;
    pkt->args.reply.version      = anchor->version;
    pkt->sig_strength            = 0;
    command_pending              = 1;
    if (call CommandToBase.send((uint8_t*)&update.data, sizeof(command_msg)) == FAIL)
      command_pending = 0;
  }

  // update neighbors with lower gradient value
  void update_gradient(anchor_rec* anchor) {
    if (gradient_delay == -1) {
      gradient_msg* gradient = (gradient_msg*) gradient_packet.data;
      gradient->anchor       = anchor->id;
      gradient->distance     = anchor->distance;
      gradient->version      = anchor->version;
      gradient->source       = TOS_LOCAL_ADDRESS;
      gradient_delay         = (call Random.rand() & MAX_DELAY_MASK) + 1;
      anchor->is_dirty       = 0;
    }
  }

  // finished sending message
  event result_t SendGradient.sendDone(TOS_MsgPtr msg, result_t success) {
    // call Leds.redToggle();
    if(gradient_delay == 0 && msg == &gradient_packet) {
      if (success)
	gradient_delay = -1;
      else
	gradient_delay = (call Random.rand() & MAX_DELAY_MASK) + 1;
    }
    if(anchor_delay == 0 && msg == &anchor_packet) {
      if (success)
	anchor_repeat_count--;
      anchor_delay     = ANCHOR_INTERVAL;
    }
    gradient_pending = 0;
    return success;
  }
 
  // finished sending message
  event result_t CommandToBase.sendDone(uint8_t* data, result_t success) {
    if (command_delay == 0) {
      if (success)
	command_delay = -1;
      else
	command_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;
    }
    command_pending = 0;
    return success;
  }
 
  event result_t BaseToHost.sendDone(TOS_MsgPtr msg, result_t success) {
    // call Leds.redToggle();
    // reset the correct delay
    if(msg == &update) {
      update_pending = 0;
    }
    return success;
  }
 
  event result_t SendPot.sendDone(TOS_MsgPtr msg, result_t success) {
    pot_msg *potsky = (pot_msg*)msg->data;
    if (success) {
      if (potsky->type == POT_TEST)
	n_broadcasts--;
      pot_repeat_count--;
    }
    if (pot_repeat_count > 0) // resend
      pot_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;

    set_radio_power(now_pot_value);
    pot_pending = 0;
    return success;
  }
 
  event result_t Timer.fired() {
    char i;

    // handle reset message
    if (is_reset) {
      reset();
      return SUCCESS;
    }

    // send commands
    if(command_delay > 1) {
      // counting down
      command_delay--;
    } else if(command_delay == 1) {
      // wait until able to send
      if(!command_pending) {
	// try and send packet
	command_pending = 1;
	command_delay   = 0;
	if (call CommandToBase.send
	      ((uint8_t*)&command_packet.data, sizeof(command_msg)) == FAIL) {
	  command_pending = 0;
	  command_delay   = (call Random.rand() & MAX_DELAY_MASK) + 2;
	}	  
	return SUCCESS;
      }
    }

    // propagate gradients
    if (gradient_delay > 1) {
      // counting down
      gradient_delay--;
    } else if(gradient_delay == 1) {
      // wait until able to send
      if(!gradient_pending) {
	// try and send packet
	gradient_pending = 1;
	gradient_delay   = 0;
	if (call SendGradient.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &gradient_packet)
	      == FAIL) {
	  gradient_pending = 0;
	  gradient_delay   = (call Random.rand() & MAX_DELAY_MASK) + 1;
	}
	return SUCCESS;
      }
    }

    // launch repeated gradients from anchors if anchor 
    if(is_anchor && (anchor_repeat_count > 0)) {
      if(anchor_delay > 1) {
	// counting down
	anchor_delay--;
      } else if(anchor_delay == 1) {
	// wait until able to send
	if(!gradient_pending) {
	  gradient_msg* gradient = (gradient_msg*) anchor_packet.data;
	  gradient->anchor   = TOS_LOCAL_ADDRESS;
	  gradient->distance = 0;
	  gradient->version  = version;
	  gradient->source   = TOS_LOCAL_ADDRESS;
	  // try and send packet

	  call Leds.redToggle();	 

	  gradient_pending = 1;
	  anchor_delay     = 0;
	  if (call SendGradient.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &anchor_packet)
	        == FAIL) {
	    gradient_pending = 0;
	    anchor_delay     = ANCHOR_INTERVAL;
	  }
	  return SUCCESS;
	}
      }
    }

    // updated lower gradient estimates
    for(i = 0; i < MAX_ANCHORS; i++) {
      anchor_rec* anchor = &anchors[(int)i];
      if(anchor->is_dirty) {
	update_gradient(anchor);
	// update_host(anchor);
	return SUCCESS;
      }
    }

    // send out hello messages to host
    if (is_lost && !command_pending && !is_testing_radio) {
      if (lost_delay <= 0) {
	command_msg* dis = (command_msg*) hello.data;
	command_pending  = 1;
	dis->source      = TOS_LOCAL_ADDRESS;
	dis->cmd_no      = HELLO;
	command_pending  = call CommandToBase.send
	                    ((uint8_t*)&hello.data, sizeof(command_msg));
	lost_delay       = (call Random.rand() & MAX_LOST_DELAY_MASK) 
	                     + MIN_LOST_DELAY;
	return SUCCESS;
	// call Leds.yellowToggle();
      } else 
	lost_delay--;
    }

    // radio calibration reply
    if (pot_delay > 1) {
      // counting down
      pot_delay--;
    } else if(pot_delay == 1) {
      // wait until able to send
      if(!pot_pending) {
	// try and send packet
	pot_pending = 1;
	pot_delay   = 0;
	set_radio_power(MAX_POT_VALUE);
	call Leds.yellowToggle();
	if (call SendPot.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &pot_packet)
	      == FAIL) {
	  pot_pending = 0;
	  pot_delay   = (call Random.rand() & MAX_DELAY_MASK) + 1;
	  set_radio_power(now_pot_value);
	}
	return SUCCESS;
      }
    }

    // radio calibration 
    if (is_testing_radio && !command_pending) {
      if (test_count-- <= 0) {
	test_count = TEST_RELOAD;
	call Leds.greenToggle();
	if (n_broadcasts <= 0) {
	  n_broadcasts  = N_BROADCASTS;
	  pot_value++;
	  set_radio_power(pot_value);
	}

	if (pot_value >= N_STRENGTHS) {
	  pot_msg *potsky  = (pot_msg*) pot_packet.data;
	  call Leds.yellowToggle();
	  is_testing_radio = 0;
	  potsky->source   = TOS_LOCAL_ADDRESS;
	  potsky->type     = POT_REQUEST;
	  set_radio_power(MAX_POT_VALUE);
	  pot_pending      = 1;
	  pot_repeat_count = 3;
	  if (call SendPot.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &pot_packet) == FAIL) {
	    set_radio_power(now_pot_value);
	    pot_pending = 0;
	  }
	} else {
	  pot_msg *potsky = (pot_msg*) pot_packet.data;
	  potsky->source  = TOS_LOCAL_ADDRESS;
	  potsky->type    = POT_TEST;
	  // send the reply back to the source
	  potsky->value   = pot_value;
	  // try and send packet
	  pot_pending     = 1;
	  if (call SendPot.send(TOS_BCAST_ADDR, MAX_PAYLOAD, &pot_packet) == FAIL) {
	    pot_pending = 0;
	  }
	}
      }
    }
    return SUCCESS;
  }
 
  /// TAG PROCESSING

  event TOS_MsgPtr ReceiveTag.receive(TOS_MsgPtr msg) {
    tag_msg* tag = (tag_msg*)msg->data;
    command_msg *reply;

    call Leds.yellowToggle();

    if(command_delay == -1) {
      reply = (command_msg*) command_packet.data;
      reply->source        = TOS_LOCAL_ADDRESS;
      // send the reply back to the source - IMPLICITLY BASE STATION NOW.
      reply->dest          = 0xffff;
      reply->cmd_no        = TAG;
      reply->args.tag.id   = tag->id;
      reply->args.tag.time = tag->time;
      reply->sig_strength  = /* MAX_STRENGTH_VALUE - */ msg->strength;
      // This should really be hidden from us...
      command_delay = (call Random.rand() & MAX_DELAY_MASK) + 2;
    }
    return msg;
  }

}
