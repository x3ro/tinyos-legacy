chunk_size = 30;
chunk_offset = 6;
data_offset = 5;
version = 1;
mate_handlers = '("Timer0" "Once" "Snoop" "Intercept" "Receive" "Epoch_Change");

write16 = fn (s, offset, n)
  {
    s[offset] = n;
    s[offset + 1] = n >> 8;
  };

write32 = fn (s, offset, n)
  {
    s[offset] = n;
    s[offset + 1] = n >> 8;
    s[offset + 2] = n >> 16;
    s[offset + 3] = n >> 24;
  };

make_packet = fn (dest, id, length)
  {
    any p;

    p = make_string(length + data_offset);
    write16(p, 0, dest);
    p[2] = id;
    p[4] = length;

    p
  };

define_mate_handler = fn (mstate, handler)
  remote_save(mstate, string_compile(mstate[0], handler))[1];
  
mate_compile = fn (compile, s)
  {
    any mstate, compiled, saved, handlervars;

    mstate = new_mate_state();
    handlervars = "";
    lmap(fn (h)
	   handlervars = string_append(handlervars, define_mate_handler(mstate, h)),
	 mate_handlers);
    compiled = closure_code(compile(mstate[0], s));
    saved = remote_save(mstate, compiled);
    saved[1] = string_append(handlervars, saved[1]);
    saved
  };

hexchar = fn (n)
  if (n <= 9) ?0 + n
  else ?a + n - 10;

hex8 = fn (n)
  {
    any s;
    s = make_string(2);
    s[0] = hexchar((n & 0xf0) >> 4);
    s[1] = hexchar(n & 0xf);
    s
  };

for = fn (s, e, f)
  while (s < e)
    f(s++);

inject = fn (fd, compile, s, options)
  {
    any saved, image, capsule, nglobals, packet, offset, ilen;

    // Make the motlle code image & embed in a capsule
    saved = mate_compile(compile, s);
    nglobals = string_length(saved[1]) >> 1;
    for(0, nglobals, fn (i)
	if (saved[1][i + i] != 0 || saved[1][i + i + 1] != 128) 
	{
	  display(format("global %s not null\n", i));
	  error(error_bad_value);
	});
    header = make_string(5);
    // MateCapsule header
    write16(header, 0, options);
    write16(header, 2, string_length(saved[0]) + 1);
    // memory_header
    header[4] = nglobals;
    image = string_append(header, saved[0]);
    ilen = string_length(image);
    display(format("image length %s\n", ilen));
    
    // send image in chunks...
    packet = make_packet(0xffff, 0x20, chunk_size + 6);
    display(format("version %s\n", version));
    write32(packet, data_offset, version++);
    packet[data_offset + 4] = 0;

    piece = 0;
    offset = 0;
    loop
      {
	any i;

	packet[data_offset + 5] = piece++;
	i = 0;
	while (i < chunk_size && offset < ilen)
	  packet[data_offset + chunk_offset + i++] = image[offset++];

	i = 0;
	/*while (i < string_length(packet))
	  display(format("%s ", hex8(packet[i++])));
	newline();
	display(format("len %s\n", string_length(packet)));*/

	if (write_sf_packet(fd, packet) < 0)
	  {
	    display(format("error writing packet %d", piece));
	    exit 0;
	  }
	else
	  display("+");
	if (offset == ilen)
	  exit 0;
      };
    newline();
  };

qi = fn (s)
  {
    if (sf != null)
      unix_close(sf);
    sf=open_sf_source("localhost", 9001);
    inject(sf, string_compile, s, 0x40);
    unix_close(sf);
    sf = null;
  };

fi = fn (f)
  {
    if (sf != null)
      unix_close(sf);
    sf=open_sf_source("localhost", 9001);
    inject(sf, file_compile, f, 0x40); 
    unix_close(sf);
    sf = null;
  };


