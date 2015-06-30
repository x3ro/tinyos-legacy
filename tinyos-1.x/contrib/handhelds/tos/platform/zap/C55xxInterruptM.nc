//$Id: C55xxInterruptM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Joe Polastre

module C55xxInterruptM
{
  provides interface C55xxInterrupt as Port10;
  provides interface C55xxInterrupt as Port11;
  provides interface C55xxInterrupt as Port12;
  provides interface C55xxInterrupt as Port13;
  provides interface C55xxInterrupt as Port14;
  provides interface C55xxInterrupt as Port15;
  provides interface C55xxInterrupt as Port16;
  provides interface C55xxInterrupt as Port17;

}
implementation
{

  default async event void Port10.fired() { call Port10.clear(); }
  default async event void Port11.fired() { call Port11.clear(); }
  default async event void Port12.fired() { call Port12.clear(); }
  default async event void Port13.fired() { call Port13.clear(); }
  default async event void Port14.fired() { call Port14.clear(); }
  default async event void Port15.fired() { call Port15.clear(); }
  default async event void Port16.fired() { call Port16.clear(); }
  default async event void Port17.fired() { call Port17.clear(); }

  async command void Port10.enable() { }
  async command void Port11.enable() { }
  async command void Port12.enable() { }
  async command void Port13.enable() { }
  async command void Port14.enable() { }
  async command void Port15.enable() { }
  async command void Port16.enable() { }
  async command void Port17.enable() { }
    
  async command void Port10.disable() { }
  async command void Port11.disable() { }
  async command void Port12.disable() { }
  async command void Port13.disable() { }
  async command void Port14.disable() { }
  async command void Port15.disable() { }
  async command void Port16.disable() { }
  async command void Port17.disable() { }

  async command void Port10.clear() { }
  async command void Port11.clear() { }
  async command void Port12.clear() { }
  async command void Port13.clear() { }
  async command void Port14.clear() { }
  async command void Port15.clear() { }
  async command void Port16.clear() { }
  async command void Port17.clear() { }

  async command void Port10.edge(bool l2h) { 
  }
  async command void Port11.edge(bool l2h) { 
  }
  async command void Port12.edge(bool l2h) { 
  }
  async command void Port13.edge(bool l2h) { 
  }
  async command void Port14.edge(bool l2h) { 
  }
  async command void Port15.edge(bool l2h) { 
  }
  async command void Port16.edge(bool l2h) { 
  }
  async command void Port17.edge(bool l2h) { 
  }
    
}

