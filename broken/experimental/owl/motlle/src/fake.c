#include "mudlle.h"

void motlle_req_leds(u8 cmd) {}
void motlle_req_dbg(u8 x) {}
void motlle_req_exit(u8 exitcode) {}
void motlle_req_sleep(i16 time) {}
u8 motlle_req_send_msg(u8 *data, u8 len) { return 0; }
void motlle_req_msg_data(u8 *data) { }
void motlle_req_receive(value newreceiver) {}
int main(int argc, char **argv) { return 0; }
