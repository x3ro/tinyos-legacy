#ifndef MOTLLE_INTERFACE
#define MOTLLE_INTERFACE

enum {
  led_y_toggle, led_y_on, led_y_off, 
  led_r_toggle, led_r_on, led_r_off, 
  led_g_toggle, led_g_on, led_g_off };

/* provided */
void motlle_init(void);
void motlle_exec(mvalue entry);
void motlle_global_set(uvalue n, mvalue v);
uvalue motlle_globals_reserve(uvalue extra_globals);
mvalue motlle_data_init(uvalue size);
mvalue motlle_data(uint8_t *data, uvalue len);
void motlle_run1(void);

/* used */
void motlle_req_leds(uint8_t cmd);
void motlle_req_exit(uint8_t exitcode);
void motlle_req_sleep(ivalue time);
uint8_t motlle_req_send_msg(uint8_t *data, uint8_t len);
void motlle_req_msg_data(uint8_t *data);
void motlle_req_receive(mvalue newreceiver);
void motlle_req_dbg(uint8_t x);

enum {
  dbg_throw = 0xe0,		/* 1: error number */
  dbg_ins = 0xe1,		/* 1: op */
  dbg_exec = 0xe2,		/* 1: nargs, 2: called value */
  dbg_push_closure = 0xe3,	/* 2: closure value */
  dbg_gc = 0xe4,		/* 0 */

  dbg_start = 0xf0,		/* 2: fn */
  dbg_nomemory  = 0xf1,		/* 0 */
  dbg_reset = 0xf2,		/* 0 */
  dbg_exit = 0xf3,		/* 1: exit code */
};

#endif
