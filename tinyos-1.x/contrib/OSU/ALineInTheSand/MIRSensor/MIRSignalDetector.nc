/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * The MIRSignalDetector defines an interface for notifying, through an event
 * callback, a listner whenever a signal is present.  Modules implementing
 * this interface can determine how best to detect such a signal.
 *
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
interface MIRSignalDetector
{
    /**
     * Indicates that signal has been detected.
     *
     * @param   id The monotonically increasing event id.
     * @param   true if a signal is present, false otherwise.
     * @param   interval the monotonically increasing interval id.
     * @param   mean the approximate mean of the data during the
     *          previous sample window.
     * @param   variance the approximate variance of the data during the
     *          previous sample window.
     * @param   histogram a pointer to the histogram over which the mean
     *          and median were computed.
     */
    event result_t detected
    (
        uint16_t id,
        bool detected,
        uint16_t interval,
        int32_t mean,
        uint32_t variance,
        uint16_t* histogram,
	  uint32_t t
    );
}
