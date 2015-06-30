
module RRReduceM { 
  provides {
    interface Reduce[uint8_t type];
  }
  uses {
    interface Tuning;
    interface Region[uint8_t type];
    interface TupleSpace[uint8_t type];
    interface Timer[uint8_t type];
  }
} implementation {

  enum {
    STATE_IDLE,
    STATE_FORMING_REGION,
    STATE_GETTING_TUPLES,
    STATE_REDUCING,
  };

  enum {
    EMPTY_KEY = 0xff,
    DEFAULT_MAX_OUTSTANDING = 4,
    DEFAULT_REDUCE_TIMEOUT = 10000,
  };

  /* Abstract components would fix this... */
  struct _typestate {
    int state;
    bool pending_local_tuple;
    int num_outstanding_gets; 
    int num_issued_gets;
    int num_completed_gets;
    int max_outstanding_gets;
    operator_t cur_op;
    ts_key_t cur_value_key; 
    ts_key_t cur_result_key;
    bool cur_toall;
    bool region_formed;
    int num_neighbors;
    int cur_neighbor;
    uint16_t *neighbors;
    struct {
      bool valid;
      uint16_t addr;
      uint32_t value;
    } values[RADIOREGION_MAX_NEIGHBORS+1];
  } state[NUM_REGION_TYPES];

  int reduce_timeout;
  task void reduceTask();
  task void get_local_tuple();

  static void resetState(uint8_t type) {
    int n;
    dbg(DBG_USR1, "RRReduceM: resetState()\n");
    state[type].state = STATE_IDLE;
    state[type].pending_local_tuple = FALSE;
    state[type].cur_toall = FALSE;
    state[type].cur_value_key = state[type].cur_result_key = EMPTY_KEY;
    state[type].cur_neighbor = 0;
    state[type].num_completed_gets = 0;
    state[type].num_issued_gets = 0;
    state[type].num_outstanding_gets = 0;
    for (n = 0; n < RADIOREGION_MAX_NEIGHBORS+1; n++) {
      state[type].values[n].valid = FALSE;
    }
  }

  static result_t start_reduce(uint8_t type, operator_t op, ts_key_t value_key, 
      ts_key_t result_key, bool toall) {

    dbg(DBG_USR1, "RRReduceM: start_reduce (type %d op %d)\n", type, op);

    if (!call Tuning.getDefault(KEY_RADIOREGION_MAX_OUTSTANDING_GETS, 
	&state[type].max_outstanding_gets, DEFAULT_MAX_OUTSTANDING)) {
      dbg(DBG_USR1, "RRReduceM: Can't get max_outstanding\n");
      return FAIL;
    }
    if (!call Tuning.getDefault(KEY_RADIOREGION_REDUCE_TIMEOUT,
	&reduce_timeout, DEFAULT_REDUCE_TIMEOUT)) {
      dbg(DBG_USR1, "RRReduceM: Can't get reduce_timeout\n");
      return FAIL;
    }

    state[type].cur_op = op;
    state[type].cur_value_key = value_key;
    state[type].cur_result_key = result_key;
    
    if (!state[type].region_formed) {
      dbg(DBG_USR1, "RRReduceM: Forming region\n");
      state[type].state = STATE_FORMING_REGION;
      if (!call Region.getRegion[type]()) {
       	resetState(type);
	dbg(DBG_USR1, "RRReduceM: Region.getRegion() failed\n");
	return FAIL;
      } else {
	return SUCCESS;
      }
    } else {
      dbg(DBG_USR1, "RRReduceM: Region already formed\n");
      state[type].pending_local_tuple = TRUE;
      post get_local_tuple();
      return SUCCESS;
    }
  }

  default command bool Region.getRegion[uint8_t type]() {
    return FAIL;
  }
  default command int Region.getNodes[uint8_t type](uint16_t **node_list_ptr) {
    return FAIL;
  }
  default event void Reduce.reduceDone[uint8_t type](ts_key_t result_key, 
      result_t success, float quality) {
     return;
  }
  default command result_t Timer.start[uint8_t type](char ttype, uint32_t interval) {
    return FAIL;
  }

  task void get_local_tuple() {
    int type;
    /* Initiate local tuple get for all pending types */
    for (type = 0; type < NUM_REGION_TYPES; type++) {
      if (state[type].pending_local_tuple) {
	state[type].pending_local_tuple = FALSE;

	if (!call Timer.start[type](TIMER_ONE_SHOT, reduce_timeout)) {
	  dbg(DBG_USR1, "RRReduceM: Can't call timer, failing\n");
	  resetState(type);
	}

	state[type].state = STATE_GETTING_TUPLES;
	state[type].num_issued_gets = 1;
	state[type].num_outstanding_gets = 1;
	if (!call TupleSpace.get[type](state[type].cur_value_key, 
	      TOS_LOCAL_ADDRESS, &(state[type].values[0].value))) {
	  dbg(DBG_USR1, "RRReduceM: Local TS.get() failed\n");
	  resetState(type);
	}
      }
    } 
    return;
  }

  event void Region.getDone[uint8_t type](result_t success) {
    if (state[type].state != STATE_FORMING_REGION) {
      dbg(DBG_USR1, "RRReduceM: Region.getDone[%d] not in STATE_FORMING_REGION\n", type);
      resetState(type);
      return;
    }

    if (!success) {
      dbg(DBG_USR1, "RRReduceM: Region.getDone[%d] failed\n", type);
      signal Reduce.reduceDone[type](state[type].cur_result_key, FAIL, 0.0);
      resetState(type);
      return;
    }

    // Initiate tuple collection
    state[type].region_formed = TRUE;
    state[type].num_neighbors = call Region.getNodes[type](&state[type].neighbors);
    dbg(DBG_USR1, "RRReduceM: Region.getDone[%d], %d neighbors\n", type, 
	state[type].num_neighbors);
    state[type].pending_local_tuple = TRUE;
    post get_local_tuple();

  }

  event void TupleSpace.getDone[uint8_t type](ts_key_t key, uint16_t nodeaddr, 
      void *buf, int buflen, result_t success) {
    dbg(DBG_USR1, "RRReduceM: TS.getDone() type %d node %d key %d success %d\n", type, nodeaddr, key, success);
    if (key != state[type].cur_value_key || state[type].state != STATE_GETTING_TUPLES) {
      dbg(DBG_USR1, "RRReduceM: TS.getDone[%d] not in STATE_GETTING_TUPLES\n", type);
      // Don't reset state - we might be reducing already after a timeout
      return;
    }

    if (success) {
      int n;
      if (nodeaddr == TOS_LOCAL_ADDRESS) {
	state[type].values[0].valid = TRUE;
	state[type].values[0].addr = TOS_LOCAL_ADDRESS;
      } else {
	for (n = 0; n < state[type].num_neighbors; n++) {
  	  if (state[type].neighbors[n] == nodeaddr) {
  	    state[type].values[n+1].valid = TRUE;
	    state[type].values[n+1].addr = nodeaddr;
  	    break;
  	  }
   	}
      }
      if (++state[type].num_completed_gets == state[type].num_neighbors+1) {
	state[type].state = STATE_REDUCING;
	post reduceTask();
	return;
      }
    }

    state[type].num_outstanding_gets--;

    while (state[type].num_issued_gets < state[type].num_neighbors+1 && 
	state[type].num_outstanding_gets < state[type].max_outstanding_gets) {
      int slot = state[type].num_issued_gets-1;
      state[type].num_issued_gets++;
      state[type].num_outstanding_gets++;
      if (!call TupleSpace.get[type](state[type].cur_value_key, 
	    state[type].neighbors[slot],
	  &(state[type].values[slot+1].value))) {
	dbg(DBG_USR1, "RRReduceM: TS.get(%d) failed\n", state[type].neighbors[slot]);
	// Pretend it completed
	state[type].num_completed_gets++;
	state[type].num_outstanding_gets--;
	return;
      }
    }
  }

  task void reduceTask() {
    int type;

    // Iterate through all types that need reduction
    for (type = 0; type < NUM_REGION_TYPES; type++) {
      int n;
      uint32_t reduceid = TOS_LOCAL_ADDRESS;
      uint32_t reduceval = 0;
      bool foundvalid = FALSE;
      int validcount = 0;
      float quality;
      if (state[type].state != STATE_REDUCING) continue;

      // If no valid values, fail
      for (n = 0; n < state[type].num_neighbors+1; n++) {
	if (state[type].values[n].valid) {
	  foundvalid = TRUE;
	  if (state[type].cur_op == REDUCE_OP_MIN || 
	      state[type].cur_op == REDUCE_OP_MAX ||
	      state[type].cur_op == REDUCE_OP_MINID || 
	      state[type].cur_op == REDUCE_OP_MAXID) {
	    reduceval = state[type].values[n].value;
	    reduceid = state[type].values[n].addr;
	  }
	  break;
	}
      } 

      if (!foundvalid) {
	signal Reduce.reduceDone[type](state[type].cur_result_key, FAIL, 0.0);
	resetState(type);
	return;
      }
      dbg(DBG_USR1, "RRReduceM: Initial reduceval: %d\n", reduceval);

      for (n = 0; n < state[type].num_neighbors+1; n++) {
	if (state[type].values[n].valid) {
	  validcount++;
	  switch (state[type].cur_op) {
	    case REDUCE_OP_ADD: 
	      reduceval += state[type].values[n].value; break;
	    case REDUCE_OP_PROD: 
	      reduceval *= state[type].values[n].value; break;
	    case REDUCE_OP_MIN: 
	      if (state[type].values[n].value < reduceval) {
		reduceval = state[type].values[n].value;
	      } 
	      break;
	    case REDUCE_OP_MAX: 
	      if (state[type].values[n].value > reduceval) {
		reduceval = state[type].values[n].value;
	      }
	      break;
	    case REDUCE_OP_MINID: 
	      if (state[type].values[n].value < reduceval) {
		reduceval = state[type].values[n].value;
		reduceid = state[type].values[n].addr;
	      } 
	      break;
	    case REDUCE_OP_MAXID: 
	      if (state[type].values[n].value > reduceval) {
		reduceval = state[type].values[n].value;
		reduceid = state[type].values[n].addr;
	      }
	      break;
	    default: 
	      dbg(DBG_USR1, "RRReduceM: Bad operator %d\n", state[type].cur_op);
 	      resetState(type);
	      break;
	  }
	  dbg(DBG_USR1, "RRReduceM[%d]: values[%d] = %d, reduceval %d\n", type, n, state[type].values[n].value, reduceval);
	}
      }

      dbg(DBG_USR1, "RRReduceM[%d]: Final reduceval: %d\n", type, reduceval);
      if (state[type].cur_op == REDUCE_OP_MINID || 
	  state[type].cur_op == REDUCE_OP_MAXID) {
	call TupleSpace.put[type](state[type].cur_result_key, &reduceid, 
	    sizeof(reduceid));
      } else {
	call TupleSpace.put[type](state[type].cur_result_key, &reduceval, 
	    sizeof(reduceval));
      }
      quality = (validcount * 1.0) / ((state[type].num_neighbors+1) * 1.0);
      signal Reduce.reduceDone[type](state[type].cur_result_key, SUCCESS, quality);
      resetState(type);
    }
  }

  command result_t Reduce.reduceToOne[uint8_t type](operator_t op, 
      ts_key_t value_key, ts_key_t result_key) {
    dbg(DBG_USR1, "RRReduceM: reduceToOne called (op %d value %d result %d)\n", op, value_key, result_key);
    if (state[type].state != STATE_IDLE) return FAIL;
    resetState(type); // Really need to 'key' each reduction 
    return start_reduce(type, op, value_key, result_key, FALSE);
  }

  command result_t Reduce.reduceToAll[uint8_t type](operator_t op, 
      ts_key_t value_key, ts_key_t result_key) {
    dbg(DBG_USR1, "RRReduceM: reduceToAll called (op %d value %d result %d)\n", op, value_key, result_key);
    if (state[type].state != STATE_IDLE) return FAIL;
    resetState(type); // Really need to 'key' each reduction 
    return start_reduce(type, op, value_key, result_key, TRUE);
  }

  event result_t Timer.fired[uint8_t type]() {
    if (state[type].state != STATE_GETTING_TUPLES) return SUCCESS;
    dbg(DBG_USR1, "RRReduceM: Timer[%d] fired, posting reduceTask()\n", type);
    state[type].state = STATE_REDUCING;
    post reduceTask();
    return SUCCESS;
  }

}

