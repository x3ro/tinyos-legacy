 #include "runtime/runtime.h"
#include "call.h"

TYPEDOP("led!", ledb, "n -> . Do cmd n (led_{r,g,y}_{on,off,toggle} on the leds", 1, (value cmd),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.")
{
  ivalue c = intval(cmd);

  ISINT(cmd);
  if (c < led_y_toggle || c > led_g_off)
    RUNTIME_ERROR(error_bad_value);

  motlle_req_leds(c);

  undefined();
}

TYPEDOP("sleep", sleep, "n -> . Sleep for n milliseconds", 1, (value time),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, "n.")
{
  ivalue n = intval(time);

  ISINT(time);
  if (n < 0)
    RUNTIME_ERROR(error_bad_value);

  if (n > 0)
    motlle_req_sleep(n);

  undefined();
}

TYPEDOP("msg_send", msg_send, "", 1, (struct string *msg), 0, "s.b")
{
  TYPEIS(msg, type_string);

  return makebool(motlle_req_send_msg((u8 *)msg->str, string_len(msg)));
}

TYPEDOP("msg_data", msg_data, "", 0, (void), 0, ".s")
{
  struct string *msg = alloc_string_n(PACKET_SIZE);

  msg->str[PACKET_SIZE] = '\0';

  motlle_req_msg_data((u8 *)msg->str);

  return msg;
}

TYPEDOP("set_msg_receiver!", set_msg_receiverb, "", 1, (value handler), 1, "f.")
{
  TYPEIS(handler, type_function);
  motlle_req_receive(handler);
  undefined();
}

#if DEFINE_GLOBALS
GLOBALS(mote)
{
  system_define("led_y_toggle", makeint(led_y_toggle));
  system_define("led_y_on", makeint(led_y_on));
  system_define("led_y_off", makeint(led_y_off));
  system_define("led_r_toggle", makeint(led_r_toggle));
  system_define("led_r_on", makeint(led_r_on));
  system_define("led_r_off", makeint(led_r_off));
  system_define("led_g_toggle", makeint(led_g_toggle));
  system_define("led_g_on", makeint(led_g_on));
  system_define("led_g_off", makeint(led_g_off));
}
#endif
