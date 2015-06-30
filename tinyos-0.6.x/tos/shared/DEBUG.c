/*
 * debug.c - simple mote-level debugging support
 *
 * Authors: David Gay
 * History: created 12/21/01
 *	    add flashing 1/10/02
 */

#include "tos.h"
#include "dbg.h"
#include "DEBUG.h"


//Frame Declaration
#define TOS_FRAME_TYPE DEBUG_frame
TOS_FRAME_BEGIN(DEBUG_frame) {
  char flash_red;
  char flash_green;
  char flash_yellow;
}
TOS_FRAME_END(DEBUG_frame);

void TOS_COMMAND(DEBUG_INIT)(void)
{
  VAR(flash_green) = VAR(flash_red) = VAR(flash_yellow) = 0;
  TOS_CALL_COMMAND(SUB_TIMERS_REGISTER)(7, 1);
  TOS_CALL_COMMAND(LEDS_INIT)();
}

void TOS_COMMAND(NFLASH_LEDS)(unsigned char act)
{
}

void TOS_COMMAND(FLASH_LEDS)(unsigned char act)
{
  switch (act)
    {
    case led_y_toggle: case led_y_on:
      VAR(flash_yellow) = 1;
      break;
    case led_r_toggle: case led_r_on:
      VAR(flash_red) = 1;
      break;
    case led_g_toggle: case led_g_on:
      VAR(flash_green) = 1;
      break;
    }
}

void TOS_EVENT(LEDS_FLASH)(short port)
{
  if (VAR(flash_yellow) == 1)
    {
      VAR(flash_yellow)++;
      TOS_CALL_COMMAND(LEDy_on)();
    }
  else if (VAR(flash_yellow) == 2)
    {
      VAR(flash_yellow) = 0;
      TOS_CALL_COMMAND(LEDy_off)();
    }

  if (VAR(flash_green) == 1)
    {
      VAR(flash_green)++;
      TOS_CALL_COMMAND(LEDg_on)();
    }
  else if (VAR(flash_green) == 2)
    {
      VAR(flash_green) = 0;
      TOS_CALL_COMMAND(LEDg_off)();
    }

  if (VAR(flash_red) == 1)
    {
      VAR(flash_red)++;
      TOS_CALL_COMMAND(LEDr_on)();
    }
  else if (VAR(flash_red) == 2)
    {
      VAR(flash_red) = 0;
      TOS_CALL_COMMAND(LEDr_off)();
    }

}

void TOS_COMMAND(LEDS)(unsigned char act)
{
  switch (act)
    {
    case led_y_toggle:
      TOS_CALL_COMMAND(LEDy_toggle)();
      break;
    case led_y_on:
      TOS_CALL_COMMAND(LEDy_on)();
      break;
    case led_y_off:
      TOS_CALL_COMMAND(LEDy_off)();
      break;
    case led_r_toggle:
      TOS_CALL_COMMAND(LEDr_toggle)();
      break;
    case led_r_on:
      TOS_CALL_COMMAND(LEDr_on)();
      break;
    case led_r_off:
      TOS_CALL_COMMAND(LEDr_off)();
      break;
    case led_g_toggle:
      TOS_CALL_COMMAND(LEDg_toggle)();
      break;
    case led_g_on:
      TOS_CALL_COMMAND(LEDg_on)();
      break;
    case led_g_off:
      TOS_CALL_COMMAND(LEDg_off)();
      break;
    }
}

void TOS_COMMAND(NLEDS)(unsigned char act)
{
}
