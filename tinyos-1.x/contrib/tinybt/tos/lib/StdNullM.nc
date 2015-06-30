/*
    StdNull module - module that has a StdOut interface but just throw
    stuff away.
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
/*
 * Simple StdNull component
 */

/**
   This component provides an implementation of the StdOut interface
   that throws any message away.
*/
module StdNullM
{
  provides interface StdOut;
}

implementation
{

  command result_t StdOut.init() {
    return SUCCESS;
  }

  command result_t StdOut.done() {
    return SUCCESS;
  }
  
  async command int StdOut.print(const char * str) {
    return 0;
  }

  async command int StdOut.printHex(uint8_t c) {
    return 0;
  }

  async command int StdOut.printHexword(uint16_t c) {
    return 0;
  }

  async command int StdOut.printHexlong(uint32_t c) {
    return 0;
  }

  async command result_t StdOut.dumpHex(uint8_t ptr[], uint8_t countar, char * sep) {
    return 0;
  }
  
  /* Default handler for the benefit of our users */
  default async event result_t StdOut.get(uint8_t data) { return SUCCESS; }
}
