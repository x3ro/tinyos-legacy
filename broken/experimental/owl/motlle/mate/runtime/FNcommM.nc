module FNcommM {
  provides {
    interface MateBytecode as Encode;
    interface MateBytecode as Decode;
    interface MateBytecode as Send;
  }
  uses {
    interface MotlleGC as GC;
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;
    interface MotlleValues as V;

    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    interface SendMsg as SendPacket;
  }
  provides event result_t sendDone(); // for packet-send retries
}
implementation {
  msize encode(vvector v, unsigned char *data) {
    msize i = 0, vlen = call T.vector_length(v);
    svalue *elems = v->data;

    while (vlen--)
      {
	mvalue x = call V.read(elems++);
	msize len = 0;

	// len . x specific length encoding request
	if (call T.pairp(x))
	  {
	    vpair p = call T.pair(x);
	    mvalue flen = call V.read(&p->car);

	    if (call T.intp(flen))
	      {
		vint field_len = call T.intv(flen);

		if (field_len <= 0 || field_len > TOSH_DATA_LENGTH)
		  return 0;
		len = field_len;
		x = call V.read(&p->cdr);
	      }
	    else
	      return 0;
	  }
	if (call T.intp(x)) // encode integer as 2 bytes
	  {
	    vint ix = call T.intv(x);
	    unsigned char b1 = ix, b2 = ix >> 8;

	    if (!len) // default length
	      len = 2;

	    if (data)
	      {
		data[i] = b1;
		if (len > 1)
		  {
		    msize j = len;

		    data[i + 1] = b2;
		    while (--j > 1)
		      data[i + j] = 0;
		  }
	      }
	  }
	else if (call T.realp(x)) // encode float as 4 bytes
	  {
	    len = 4;

	    if (data)
	      *(mvalue *)data = x;
	  }
	else if (call T.stringp(x)) // encode string as-is
	  {
	    vstring s = call T.string(x);
	    msize slen = call T.string_length(s);

	    if (!len) // default length
	      len = slen;

	    if (data)
	      {
		if (slen < len)
		  {
		    memcpy(data + i, s->str, slen);
		    memset(data + i + slen, 0, len - slen);
		  }
		else
		  memcpy(data + i, s->str, len);
	      }
	  }
	i += len;
      }

    return i;
  }

  //FN encode: v -> s. Encode a vector as a string. Produces a string which
  //is the concatenation of the elements of v, each encoded as follows:
  //  i: encode as 2 little-endian bytes
  //  f: encode as 4-byte float
  //  s: encode n-char string as n identical bytes
  //  i . x: encode x as usual, pad (w/ 0s) or truncate to n bytes
  //         ignored for floats (always encoded as 4 bytes)
  command result_t Encode.execute(uint8_t instr, MateContext* context) {
    mvalue arg1 = call S.get(context, 0);

    if (call T.vectorp(arg1))
      {
	vvector v = call T.vector(arg1);
	msize len = encode(v, NULL);
	vstring s;

	if (len == 0)
	  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	else
	  {
	    s = call T.alloc_string(len);
	    if (s)
	      {
		v = call T.vector(call S.pop(context, 1));
		encode(v, s->str);
		call S.qpush(context, call T.make_string(s));
	      }
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Encode.byteLength() {
    return 1;
  }

  //FN decode: s v -> v. Decode string s into v, based on the decoding rules
  //specified in v. Elements of v should be:
  //  i: 1->1-byte unsigned, 2->2-byte unsigned, 
  //     -1->1-byte signed, -2->2-byte signed
  //  f: decode a 4-byte float
  //  s2: overwrite s2 with chars from s
  command result_t Decode.execute(uint8_t instr, MateContext* context) {
    mvalue arg2 = call S.pop(context, 1);
    mvalue arg1 = call S.pop(context, 0);

    if (call T.stringp(arg1) && call T.vectorp(arg2))
      {
	vstring s = call T.string(arg1);
	vvector v = call T.vector(arg2);
	msize i = 0, slen = call T.string_length(s),
	  vlen = call T.vector_length(v);
	svalue *elems = v->data;
	unsigned char *packet = s->str;

	if (!call GC.mutable(elems))
	  {
	    call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
	    return SUCCESS;
	  }
	while (vlen--)
	  {
	    mvalue x = call V.read(elems);

	    if (call T.intp(x)) // decode 1 or 2 byte integer
	      {
		vint ix = call T.intv(x);

		// enough source data?
		if (i + (ix < 0 ? -ix : ix) > slen)
		  {
		    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		    return SUCCESS;
		  }
		switch (ix) 
		  {
		  case 1: ix = packet[i++]; break;
		  case -1: ix = (int8_t)packet[i++]; break;
		  case 2: case -2:
		    ix = packet[i++]; 
		    ix |= packet[i++] << 8;
		    break;
		  default:
		    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		    return SUCCESS;
		  }
		call V.write(elems, call T.make_int(ix));
	      }
	    else if (call T.realp(x)) // decode float
	      {
		mvalue r;

		// enough source data?
		if (i + 4 > slen)
		  {
		    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		    return SUCCESS;
		  }
		r = *(mvalue *)packet;
		if (!call T.realp(r))
		  {
		    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		    return SUCCESS;
		  }
	      }
	    else if (call T.stringp(x)) // copy into string
	      {
		vstring sdest = call T.string(x);
		msize sdestlen = call T.string_length(sdest);

		if (!call GC.mutable(sdest))
		  {
		    call E.error(context, MOTLLE_ERROR_VALUE_READ_ONLY);
		    return SUCCESS;
		  }
		if (i + sdestlen > slen)
		  {
		    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
		    return SUCCESS;
		  }
		memcpy(sdest->str, s->str + i, sdestlen);
	      }
	    elems++;
	  }
	call S.qpush(context, arg2);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t Decode.byteLength() {
    return 1;
  }


  MateContext *sendingContext;
  bool retry;
  TOS_Msg msg;
    
  void resend() {
    uint8_t len = msg.length;
    uint16_t addr = msg.addr;

    // SendPacket could munge length
    if (!call SendPacket.send(addr, len, &msg))
      {
	msg.addr = addr;
	msg.length = len;
	retry = TRUE;
      }
  }
  
  //FN send: i s -> b. Send packet s to address i, returning success/failure.
  command result_t Send.execute(uint8_t instr, MateContext* context) {
    mvalue arg2 = call S.pop(context, 1);
    mvalue arg1 = call S.pop(context, 1);
    vint addr;
    vstring packet;
    msize len;

    if (!(call T.stringp(arg2) && call T.intp(arg1)))
      {
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	return SUCCESS;
      }
    addr = call T.intv(arg1);
    packet = call T.string(arg2);
    len = call T.string_length(packet);

    if (len > TOSH_DATA_LENGTH)
      {
	call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	return SUCCESS;
      }
    memcpy(msg.data, packet, len);
    msg.addr = addr;
    msg.length = len;
    context->state = MATE_STATE_BLOCKED;
    sendingContext = context;

    resend();

    call Synch.yieldContext(context);

    return SUCCESS;
  }

  command uint8_t Send.byteLength() {
    return 1;
  }

  event result_t SendPacket.sendDone(TOS_MsgPtr mesg, result_t success) {
    MateContext *sender = sendingContext;

    if (sender == NULL) 
      return SUCCESS;

    retry = FALSE;
    sendingContext = NULL;
    if (call S.push(sender, call T.make_bool(success)))
      call Synch.resumeContext(sender, sender);

    return SUCCESS;
  }

  event result_t sendDone() { // Generic sendDone
    if (retry)
      resend();
    return SUCCESS;
  }

  event void EngineStatus.rebooted() {
    sendingContext = NULL;
    retry = FALSE;
  }
}
