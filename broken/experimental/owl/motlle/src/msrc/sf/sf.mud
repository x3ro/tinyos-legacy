saferead = fn (fd, s)
  {
    any actual, count;

    actual = 0;
    count = string_length(s);
    while (count > 0)
      {
	any n;

	n = unix_read(fd, s, actual, count);
	if (n <= 0)
	  exit<function> false;
	count -= n;
	actual += n;
      };
    true
  };

safewrite = fn (fd, s)
  {
    any actual, count;

    actual = 0;
    count = string_length(s);
    while (count > 0)
      {
	any n;

	n = unix_write(fd, s, actual, count);
	if (n <= 0)
	  exit<function> false;
	count -= n;
	actual += n;
      };
    true
  };

open_sf_source = fn "s n1 -> n2. Open connection to serial forwarder at \n\
s:n1, returning the new file descriptor.\n\
Returns -1 for failed connections" (host, port)
  {
    any fd;

    fd = unix_tcp_connect(host, port);
    if (fd >= 0)
      if (init_sf_source(fd) < 0)
	{
	  unix_close(fd);
	  fd = -1;
	};
    fd
  };

init_sf_source = fn "n1 -> n2. Initialise connection to serial forwarder on fd n1.\n\
Return 0 if successful, -1 if serial forwarder not recognised" (fd)
  {
    any version;

    version = make_string(2);
    if (safewrite(fd, "T ") && saferead(fd, version) &&
	version[0] == ?T && version[1] >= ? )
      0
    else
      -1
  };

read_sf_packet = fn "n -> s. Return a packet read from serial forwarder on fd n, or -1 for failure" (fd)
  {
    any length, packet;

    length = make_string(1);
    if (saferead(fd, length))
      {
	packet = make_string(length[0]);
	if (saferead(fd, packet))
	  exit<function> packet;
      };
    -1
  };

write_sf_packet = fn "n1 s -> n2. Writes packet s to serial forwarder on fd n1.\n\
Returns -1 for failure, 0 for success" (fd, packet)
  {
    any length;

    length = make_string(1);
    length[0] = string_length(packet);
    if (safewrite(fd, length) && safewrite(fd, packet))
      0
    else
      -1
  };
