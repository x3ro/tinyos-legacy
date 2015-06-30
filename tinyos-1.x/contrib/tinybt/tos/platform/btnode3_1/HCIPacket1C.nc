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

configuration HCIPacket1C {
     provides interface HCIPacket;
}
implementation {
  components HCIPacket1M,
    StdNullC,
    HPLInterrupt,
    IntToLeds,
    HPLBTUART1C;

  HCIPacket = HCIPacket1M;
  HCIPacket1M.BTUART    -> HPLBTUART1C;
  HCIPacket1M.StdOut    -> StdNullC;
  HCIPacket1M.Interrupt -> HPLInterrupt;
  HCIPacket1M.IntOutput -> IntToLeds.IntOutput;

//  BTUART = HPLBTUARTM;
}
