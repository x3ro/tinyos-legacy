for = fn (s, e, f)
  while (s <= e) f(s++);

repeat = fn (n, f) 
  while (n-- > 0) f();

hexchar = fn (int n)
  {
    if (n < 10)
      ?0 + n
    else
      (?a - 10) + n
  };

hexbyte_string = fn (int n)
  {
    s = make_string(2);
    s[1] = hexchar(n & 0xf);
    s[0] = hexchar((n >> 4) & 0xf);
    s
  };

int12s = string fn (int n)
  {
    any s;

    s = make_string(1);
    s[0] = n & 0xff; 
    s
  };

int22s = string fn (int n)
  {
    any s;

    s = make_string(2);
    s[0] = n & 0xff; n >>= 8;
    s[1] = n & 0xff; n >>= 8;
    s
  };

int42s = string fn (int n)
  {
    any s;

    s = make_string(4);
    s[0] = n & 0xff; n >>= 8;
    s[1] = n & 0xff; n >>= 8;
    s[2] = n & 0xff; n >>= 8;
    s[3] = n & 0xff;
    s
  };

report_error = fn ()
  {
    display("error " + itoa(unix_errno()));
    newline();
  };

pc_motlle_connect = fn ()
  {
    any fd;

    fd = unix_stream_connect("/tmp/smotlle-socket");
    if (fd == -1)
      {
	report_error();
	-1 . false
      }
    else
      fd . true
  };

avr_motlle_connect = fn ()
  {
    any fd;

    fd = unix_tcp_connect("localhost", 9000);
    if (fd == -1)
      {
	report_error();
	-1 . false
      }
    else
      fd . true
  };

smotlle_send = fn (conn, string s)
  {
    if (cdr(conn))
      {
	if (unix_write(car(conn), s) != string_length(s))
	  {
	    report_error();
	    set_cdr!(conn, false);
	  };
      };
  };

smotlle_close = fn (conn)
  {
    if (car(conn) != -1)
      if (unix_close(car(conn)) == -1)
	report_error();
  };

pc_send_req = fn (int req, string str)
  {
    any conn;

    conn = pc_motlle_connect();
    smotlle_send(conn, int42s(req));
    smotlle_send(conn, str);
    smotlle_close(conn);
  };

avr_packet_length = 36;
avr_packet_data_length = avr_packet_length - 7;

packet_display = fn (p)
  {
    for(0, avr_packet_length - 1,
	fn (i) display(hexbyte_string(p[i]) + " "));
    newline();
  };

avr_broadcast = 0xffff;
avr_group = 0x2a;

avr_crc = fn (string packet)
  {
    any crc;

    crc = 0;
    for(0, string_length(packet) - 1,
	fn (index)
	{
	  crc = crc ^ (packet[index] << 8);
	  repeat(8, fn ()
		 { 
		   if ((crc & 0x8000) != 0)
		     crc = (crc << 1) ^ 0x1021
		   else
		     crc = crc << 1;
		   crc = crc & 0xffff; // could be removed
		 });
	});

    crc
  };

avr_send = fn (conn, int dest, int amid, string data)
  {
    any packet, dlen;

    dlen = string_length(data);
    packet = int22s(dest) + int12s(amid) + int12s(avr_group) +
      int12s(dlen) + data;
    packet = packet + make_string(avr_packet_data_length - dlen) +
      int22s(avr_crc(packet));
    sleep(500);
    packet_display(packet);
    smotlle_send(conn, packet);
  };

avr_packetized_send = fn (conn, string s)
  {
    any i, slen, packet_len;

    i = 0;
    slen = string_length(s);
    // we need even-length packets
    packet_len = avr_packet_data_length & ~1;
    while (i < slen)
      {
	any packet, this_packet_length;

	this_packet_length = slen - i;
	if (this_packet_length > packet_len)
	  this_packet_length = packet_len;

	packet = substring(s, i, this_packet_length);

	avr_send(conn, avr_broadcast, 42, packet);

	i += this_packet_length;
      };
  };

avr_send_req = fn (int req, string str)
  {
    any conn, command;

    command = int12s(req) + str;

    conn = avr_motlle_connect();
    avr_packetized_send(conn, command);
    smotlle_close(conn);
  };

pc_reset = fn ()
{
  pc_state = new_pc_state();
  pc_send_req(1, "");
};

avr_reset = fn ()
  {
    avr_state = new_avr_state();
    avr_send_req(?p, "lease reset now! thanks." + [ | s | s = make_string(1); s[0] = 0; s ]);
  };

pc_compile = fn (compiler, s) 
{
  any cfn, saved_fn;

  cfn = compiler(pc_state[0], s);
  examine(cfn);
  saved_fn = remote_save(pc_state, cfn);
  // there were reasons for this format at one time
  pc_send_req(0, int42s(string_length(saved_fn[0]) + string_length(saved_fn[1])) +
	      int42s(string_length(saved_fn[0])) +
	      saved_fn[0] + saved_fn[1]);
};

pc_exec = fn (s) pc_compile(string_compile, s);
pc_fexec = fn (s) pc_compile(file_compile, s);

avr_compile = fn (compiler, s)
{
  any cfn;

  cfn = compiler(avr_state[0], s);
  examine(cfn);
  saved_fn = remote_save(avr_state, cfn);

  avr_send_req(0, "x" + int22s(string_length(saved_fn[1]) / 2) + 
	          int22s(string_length(saved_fn[0])) +
	          saved_fn[1] +
	          saved_fn[0]);
};

avr_exec = fn (s) avr_compile(string_compile, s);
avr_fexec = fn (s) avr_compile(file_compile, s);

avr_debug = fn (n)
{
  avr_send_req(2, int12s(n));
}
