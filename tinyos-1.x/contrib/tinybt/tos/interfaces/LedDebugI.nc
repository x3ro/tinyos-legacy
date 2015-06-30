/*
  LedDebug interface - provides an interface to "debugging" with 
  the leds.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
/**
 * Define an interface for displaying debug output on the Leds, and
 * also fail while repeating a pattern. */
interface LedDebugI {
  /** 
   * Set the leds.
   *
   * Will set the leds (all four for the btnode) in the pattern of the
   * low four bits of the parameter.  
   *
   * @param code The pattern to set the leds, in the least significant four bits. */
  async command void debug(int code);
  
  /**
   * Fail hard, while flashing a pattern.
   * 
   * <p>This functions first clears all the leds, then waits for
   * approximately 2 seconds, then displays the 4 lowermost bits from
   * the first parameter, then waits approximately 0.5 second, the
   * displays the 4 lowermost bits of the second parameter, then waits
   * 0.5 seconds, then starts all over.</p>
   *
   * <p>Please note that for any parameter, only the lowest 4 bits are used.</p>
   * 
   * <p>This function never returns.</p>
   *
   * @param a The first pattern to flash
   * @param b The second pattern to flash */
  async command void fail2(uint8_t a, uint8_t b);

  /**
   * Fail hard, while flashing a pattern.
   * 
   * <p>This function works as <code>fail2</code> but takes 3
   * arguments.</p>
   *
   * @param a The first pattern to flash
   * @param b The second pattern to flash
   * @param c The third pattern to flash */
  async command void fail3(uint8_t a, uint8_t b, uint8_t c);

  /**
   * Fail hard, while flashing a pattern.
   * 
   * <p>This function works as <code>fail2</code> but takes 4
   * arguments.</p>
   *
   * @param a The first pattern to flash
   * @param b The second pattern to flash
   * @param c The third pattern to flash 
   * @param d The fourth pattern to flash */
  async command void fail4(uint8_t a, uint8_t b, uint8_t c, uint8_t d);

  /**
   * Fail hard, while flashing a pattern.
   * 
   * <p>This function works as <code>fail2</code> but takes 5
   * arguments.</p>
   *
   * @see fail4, fail3 and fail2
   *
   * @param a The first pattern to flash
   * @param b The second pattern to flash
   * @param c The third pattern to flash 
   * @param d The fourth pattern to flash 
   * @param e The fifth pattern to flash */
  async command void fail5(uint8_t a, uint8_t b, uint8_t c, uint8_t d, uint8_t e);
}
