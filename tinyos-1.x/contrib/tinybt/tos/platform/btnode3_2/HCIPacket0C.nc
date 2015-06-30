/*
  HCIPacket interface collects bytes from an Ericsson ROK 101 007 modules
  and provides a packet-oriented 
  Copyright (C) 2002 Martin Leopold <leopold@diku.dk>

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

includes btpackets;

configuration HCIPacket0C {
     provides interface HCIPacket;
}
implementation {
  components HCIPacket0M,
    StdNullC,
    HPLInterrupt,
    IntToLeds,
    HPLBTUART0C;

  HCIPacket = HCIPacket0M;
  HCIPacket0M.BTUART    -> HPLBTUART0C;
  HCIPacket0M.StdOut    -> StdNullC;
  HCIPacket0M.Interrupt -> HPLInterrupt;
  HCIPacket0M.IntOutput -> IntToLeds.IntOutput;

//  BTUART = HPLBTUARTM;
}
