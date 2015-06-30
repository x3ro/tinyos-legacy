/*
  Count (and other commands) program that utilizes the Assembly
  interface and component.
  
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

includes assembly;

/** 
 * Assembly interface based count program.
 * 
 * <p>This component can answer a query that counts the number of
 * nodes in the network. The approach is very basic and is only meant
 * as a proof-of-concept.</p>
 *
 * <p>You should send the root node an ACL packet with the payload
 * "cttl", where ttl is the number of seconds the query should go on,
 * which must be between 1 and 4 seconds. So "c2" is a valid
 * request. Because each level in the connection tree uses a second,
 * the number should be one larger than the depth of the tree.</p>
 * 
 * <p>The answer to the query is a single packet on the form "Cnum"
 * where num is the number of nodes that were able to answer. This
 * is limited to 1-9.</p>
 * 
 * <p>For debugging purposes, this component also supports the
 * commands "l" and "L" for turning off and on the leds, and "t" and
 * "T" for "talking" back to you, "t" will send two packets with ascii
 * data towards the parent, "T" will send 4. Each of these commands
 * are automatically send to all children.</p> */
configuration Count {
}
implementation {
  components Main,
    CountM,
    LedDebugC,
    ClockC,
    AssemblyC; /* Normally AssemblyC */
  
  /* Connect Main with other components */
  Main.StdControl -> CountM.StdControl;
  Main.StdControl -> ClockC.StdControl;
  CountM.Clock    -> ClockC.Clock;
  CountM.Assembly -> AssemblyC.AssemblyI;
  CountM.Debug    -> LedDebugC.LedDebugI;
}
