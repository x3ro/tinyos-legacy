/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * MIRSensor provides an interface to the Advantaca Micropower Impulse Radar
 * and the OSU Mica Power Board.  Both asynchronous (analog) and synchronous
 * (digital) commands are available to query the MIR sensor.  Based on Hui
 * Cao and Vineet Mittal's original MIRSensor package.
 *
 * @author  Hui Cao <caoh@cis.ohio-state.edu>
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
interface MIRSensor
{
    /**
     * Reads the MIR's digital output.
     *
     * @return  TRUE if the digital output is low (target detected), FALSE if
     *          if the digital output is high (no target detected).
     */
    command bool isTrue();

    /**
     * Initiates a reading of the analog output of the MIR sensor.
     */
    command result_t read();


    /**
     * The event that is signaled whenever the MIRSensor completes a reading
     * of the MIR's analog output.
     *
     * @param   data    The current value of the MIR's analog output.  This
     *                  should be centered
     */
    event result_t readDone(uint16_t data);
}
