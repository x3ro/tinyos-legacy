/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

any debug_level;

any saferead(fd, s)
{
  any actual = 0, count = string_length(s);

  while (count > 0)
    {
      any n = unix_read(fd, s, actual, count);
      if (n <= 0)
	return false;
      count -= n;
      actual += n;
    };
  return s;
}

any safewrite(fd, s)
{
  any actual= 0, count = string_length(s);

  while (count > 0)
    {
      any n = unix_write(fd, s, actual, count);
      if (n <= 0)
	return false;
      count -= n;
      actual += n;
    };
  return s;
}

any hexchar(n)
  if (n <= 9) '0' + n
  else 'a' + n - 10;

any hex8(n)
{
  any s = make_string(2);
  s[0] = hexchar((n & 0xf0) >> 4);
  s[1] = hexchar(n & 0xf);
  s;
}

any hexprint(s)
{
  for (any i = 0; i < string_length(s); i++)
    display(format("%s ", hex8(s[i])));
  newline();
}

any write16(s, offset, n)
{
  s[offset] = n;
  s[offset + 1] = n >> 8;
}

any write32(s, offset, n)
{
  s[offset] = n;
  s[offset + 1] = n >> 8;
  s[offset + 2] = n >> 16;
  s[offset + 3] = n >> 24;
}

any read16(s, offset)
  s[offset] | s[offset + 1] << 8;

any read32(s, offset)
  s[offset] | s[offset + 1] << 8 | s[offset + 2] << 16 | s[offset + 3] << 24;


int broadcast = 0xffff;
int platform_mica = 1, platform_telos = 2, platform_micaz = 3,
  platform_eyes = 4;
vector platforms;
int fp_read_header = 0, fp_write_header = 1, fp_data_offset = 2;
int fm_addr = 0, fm_id = 1, fm_body = 2;

{
  // Encode and decode headers for each platform. The encoders leave
  // space for 1 byte for the total packet length.
  any read_mica_header(string msg) 
    vector(read16(msg, 0), msg[2], msg[4]);

  any write_mica_header(string msg, int addr, int id, int length)
  {
    write16(msg, 1, addr);
    msg[3] = id;
    msg[5] = length;
  }

  any read_cc2420_header(string msg) 
    vector(read16(msg, 6), msg[8], msg[0]);

  any write_cc2420_header(string msg, int addr, int id, int length)
  {
    write16(msg, 7, addr);
    msg[9] = id;
    msg[1] = length;
  }

  platforms =
    vector(false,
	   vector(read_mica_header, write_mica_header, 5),
	   vector(read_cc2420_header, write_cc2420_header, 10),
	   vector(read_cc2420_header, write_cc2420_header, 10));
}

any make_packet(platform, dest, id, s)
{
  int length = string_length(s);
  int offset = 1 + platforms[platform][fp_data_offset];
  string p = make_string(offset + length);

  platforms[platform][fp_write_header](p, dest, id, length);
  for (int i = 0; i < length; i++)
    p[offset + i] = s[i];

  return p;
}

any unmake_packet(platform, packet)
{
  vector header = platforms[platform][fp_read_header](packet);
  int length = header[fm_body];
  int offset = platforms[platform][fp_data_offset];
  string body = make_string(length);

  for (int i = 0; i < length; i++)
    body[i] = packet[offset + i];
  header[fm_body] = body;

  return header;
}

any open_sf_source(host, port)
"s n1 -> n2. Open connection to serial forwarder at \n\
s:n1, returning the new file descriptor.\n\
Returns -1 for failed connections"
{
  any fd = unix_tcp_connect(host, port);
  if (fd < 0)
    return false;

  any sf = init_sf_source(fd);
  if (!sf)
    {
      unix_close(fd);
      return false;
    }

  return sf;
}

any init_sf_source(fd)
"n1 -> sf. Initialise connection to serial forwarder on fd n1.\n\
Return a serial forwarder descriptor if successful, false if serial\n\
forwarder not recognised"
{
  any version = make_string(2);
  int platform = platform_mica; // default

  if (!(safewrite(fd, "T!") && saferead(fd, version) &&
	version[0] == 'T' && version[1] >= ' '))
    return false;

  if (version[1] >= '!') 
    {
      any platformid = saferead(fd, make_string(4));

      if (!platformid || !safewrite(fd, make_string(4)))
	return false;
      platform = read32(platformid, 0);
    }

  return fd . platform;
}

any read_sf_packet(sf, timeout)
"n1 n2 -> [n3, n4, s]. Read a packet from serial forwarder on fd n1, with\n\
timeout n2 (null for infinite).\n\
Return -1 for failure, 0 for time out, packet for success. A packet has\n\
a from address (n3), and id (n4) and a body (s)"
{
  any length = make_string(1), packet, ok;
  int fd = car(sf);

  ok = unix_select(fd . null, null, null, timeout);
  if (!vector?(ok))
    return ok;
  if (saferead(fd, length))
    {
      packet = make_string(length[0]);
      if (saferead(fd, packet))
	{
	  if (debug_level >= 3)
	    {
	      display("received ");
	      hexprint(packet);
	    }
	  return unmake_packet(cdr(sf), packet);
	}
    }
  return -1;
}

any write_sf_packet(sf, dest, id, body)
"sf n2 n3 s -> n4. Writes packet s to serial forwarder on fd n1. The header\n\
is constructed from the destination address (n2), id (n3) and body (s).\n\
Returns -1 for failure, 0 for success"
{
  string packet = make_packet(cdr(sf), dest, id, body);

  packet[0] = string_length(packet) - 1;
  if (debug_level >= 3)
    {
      display(format("sending(sf %s) ", sf));
      hexprint(packet);
    }
  if (safewrite(car(sf), packet))
    0;
  else
    -1;
}
