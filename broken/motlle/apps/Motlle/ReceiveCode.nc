includes Motlle;
module ReceiveCode {
  uses {
    interface ReceiveMsg as ReceiveCode;
    interface Debug;
    interface MotlleControl;
    interface Leds;
  }
}
implementation {
  enum { s_ready, s_data, s_globals, s_ignore } state;
  // nglobals: number of global variables, as reported by motlle
  // missing_globals: 
  //   number of globals we were supposed to create, but failed to
  //   (the pc side is assuming these exist, so we must create them
  //   at some point)
  uvalue nglobals, nload_globals, missing_globals;

  event result_t MotlleControl.init() {
    state = s_ready;
    nglobals = missing_globals = 0;
    return SUCCESS;
  }

  enum { req_load, req_reset, req_debug };

  struct motlle_cmd
  {
    uint8_t request;
    union {
      struct {
	uint8_t pad;
	uvalue nglobals;
	uvalue size;
	uint8_t data[1];
      } req_load;
      uint8_t req_debug;
    } u;
  };

  enum { DL = DATA_LENGTH & ~1 };

  void handle_data_packet(uint8_t *data, uint8_t offset) {
    // Ignoring packet because we're out of memory
    if (state == s_ignore)
      {
	if (DL - offset > nload_globals)
	  state = s_ready;
	else
	  nload_globals -= DL - offset;
	return;
      }

    if (state == s_globals)
      {
	while (nload_globals > 0 && offset < DL)
	  {
	    mvalue gv = *((mvalue *)(data + offset));

	    offset += sizeof(uvalue);
	    motlle_global_set(nglobals - nload_globals, gv);
	    nload_globals--;
	  }
	if (nload_globals == 0)
	  state = s_data;
      }

    if (state == s_data)
      {
	mvalue code;

	if ((code = motlle_data(data + offset, DL - offset)))
	  {
	    state = s_ready;
	    call MotlleControl.execute(code);
	  }
      }
  }

  void handle_load(struct motlle_cmd *packet) {
    bool ok = TRUE;

    state = s_globals;
    nload_globals = packet->u.req_load.nglobals;
    if (nload_globals + missing_globals)
      {
	nglobals = motlle_globals_reserve(nload_globals + missing_globals);
	if (nglobals)
	  missing_globals = 0;
	else
	  ok = FALSE;
      }
    if (ok)
      ok = motlle_data_init(packet->u.req_load.size) != NULL;
    if (!ok)
      {
	/* Out of memory. Ignore all data for this load */
	state = s_ignore;
	nload_globals = sizeof(uvalue) * nload_globals +
	  packet->u.req_load.size;
	call Debug.dbg8(dbg_nomemory);
      }
  }

  void handle_packet(struct motlle_cmd *packet) {
    switch (packet->request)
      {
      case req_load: {
	handle_load(packet);
	handle_data_packet((uint8_t *)packet,
			   offsetof(struct motlle_cmd, u.req_load.data));
	break;
      }
      case req_reset:
	call MotlleControl.reset();
	return;
      case req_debug:
	call Debug.setTimeout(packet->u.req_debug); // hack
	return;
      }
  }

  event TOS_MsgPtr ReceiveCode.receive(TOS_MsgPtr msg) {
    /* unlikely to appear in a message */
    if (strcmp(msg->data, "please reset now! thanks.") == 0)
      call MotlleControl.reset();
    else if (state == s_ready)
      handle_packet((struct motlle_cmd *)msg->data);
    else
      handle_data_packet(msg->data, 0);

    return msg;
  }
}
