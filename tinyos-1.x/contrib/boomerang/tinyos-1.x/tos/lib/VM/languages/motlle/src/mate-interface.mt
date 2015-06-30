/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
any display_error;
any mvirus_chunk_size;
any chunk_offset = 6;
any value_size;
any version = 1;
any debug_level = 0;

any mate_compile(compile, s)
{
  any mstate, mglobals, compiled, saved, handlervars;

  mstate = new_mate_state();
  mglobals = mstate[0];
  set_bytecodes!(mglobals);
  set_primops!(mglobals);
  set_constants!(mglobals);
  handlervars = set_handlers!(mstate);

  compiled = closure_code(compile(mglobals, s));
  saved = remote_save(mstate, compiled);
  saved[1] = string_append(handlervars, saved[1]);

  return saved;
}

any inject(fd, compiled, options)
{
  any image, nglobals, packet, offset, ilen, header, piece;

  if (debug_level >= 1)
    {
      display("code ");
      hexprint(compiled[0]);
    }
  nglobals = string_length(compiled[1]) / value_size;
  /*for (any i = 0; i < nglobals; i++)
    if (compiled[1][i + i] != 0 || compiled[1][i + i + 1] != 128) 
      {
	display(format("global %s not null\n", i));
	error(error_bad_value);
      }*/
  header = make_string(6);
  // MateCapsule header
  write16(header, 0, options);
  write16(header, 2, string_length(compiled[0]) + 2);
  // memory_header, 2nd byte is unused (necessary to get alignment on telos)
  header[4] = nglobals;
  image = string_append(header, compiled[0]);
  ilen = string_length(image);

  display(format("sending %s byte image (version %s): ", ilen, version));
  if (debug_level >= 1)
    hexprint(image);
    
  // send image in chunks...
  packet = make_string(mvirus_chunk_size + chunk_offset);
  write32(packet, 0, version++);
  packet[4] = 0;

  piece = 0;
  offset = 0;
  for (;;)
    {
      int i;

      packet[5] = piece++;
      i = 0;
      while (i < mvirus_chunk_size && offset < ilen)
	packet[chunk_offset + i++] = image[offset++];

      if (debug_level >= 2)
	{
	  hexprint(packet);
	  display(format("len %s\n", string_length(packet)));
	}

      if (write_sf_packet(fd, broadcast, 0x20, packet) < 0)
	{
	  display(format("\n program send FAILED on packet %d\n", piece));
	  return false;
	}
      else if (debug_level < 2)
	display("+");
      if (offset == ilen)
	{
	  newline();
	  return true;
	}
    }
}

any read_mate_version(sf)
{
  any version_msg;

  if (write_sf_packet(sf, broadcast, 0x22, "") == 0 &&
      vector?(version_msg = read_sf_packet(sf, 2000)))
    {
      version = read32(version_msg[fm_body], 0) + 1;
      return true;
    }
  return false;
}

any get_mate_version(sf)
{
  for (any i = 0; i < 3; i++)
    if (read_mate_version(sf))
      return;
  display("timeout reading version, ");
}

any injector(compile, s)
{
  any sf = -1, ok = false;

  handle_error(fn ()
    {
      any compile_errors = make_string_oport();
      any olderr = set_stderr!(compile_errors);
      any olddisp = set_display_error!(display_error);
      any compiled = false;

      handle_error(fn () compiled = mate_compile(compile, s),
		   fn (e) 0);

      set_display_error!(olddisp);
      set_stderr!(olderr);

      if (compiled)
	{
	  display("compile successful, ");
	  any host = getenv("MOTLLEHOST");
	  if (!host) host = "localhost";
	  sf = open_sf_source(host, 9001);
	  if (sf)
	    {
	      get_mate_version(sf);
	      ok = inject(sf, compiled, 0x40);
	    }
	  else
	    display("transmission FAILED:\ncould not contact serial forwarder.\n");
	}
      else
	display(port_string(compile_errors));
    },
	       fn (error)
		 pformat(stdout(), "unexpected ERROR %s\n", error));
  if (sf)
    unix_close(car(sf));

  ok;
};

any qi(s) injector(string_compile, s);
any fi(f) injector(file_compile, f);
