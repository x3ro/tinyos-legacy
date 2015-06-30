/*
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * This RandomGen component has an advantage over other Random generator
 * components because it uses non-volatile microcontroller memory
 * to periodically store the seed.  Rebooting the mote will not
 * reset the seed back to the very beginning. 
 *
 * The seed is not stored everytime it is updated because that
 * would waste time and energy.  By default, it is saved every
 * 25 times it is called. If your app will never reboot,
 * you can prevent the periodic flash write by defining
 * RANDOMGEN_STORAGE_PERIOD = 0.
 *
 * It's recommend you don't use the RandomGen component until it has 
 * signaled RandomGen.ready().
 *
 * The standard TinyOS random number generator. If your system requires a 
 * specific random number generator, it should wire to that component
 * directly. 
 *
 * @author Barbara Hohlt 
 * @author Phil Levis 
 * @author David Moss
 */

includes RandomGen;

configuration RandomGenC {
  provides {
    interface RandomGen;
    interface StdControl;
  }
}

implementation {
  components RandomGenM, ConfigurationC;
  
  StdControl = ConfigurationC;
  RandomGen = RandomGenM;
  
  RandomGenM.Configuration -> ConfigurationC.Configuration[unique("Configuration")];
  
} 
