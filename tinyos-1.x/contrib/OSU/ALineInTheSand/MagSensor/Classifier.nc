/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

/**
 * The Classifier interface provides detection and classification related event
 * callbacks.
 *
 * @author  Prabal Dutta
 */
includes common_structs;
includes MagConstants;

interface Classifier
{
    /**
     * The event handler that is called whenever the Classifier first detects
     * a target.
     *
     * @param   id The monotonically increasing event id.
     * @param   ts The start time of the event in milliseconds.
     */
    event result_t detection
    (
        uint16_t id,
        uint32_t t0
    );

    /**
     * The event handler that is called whenever the Classifier completes
     * a target classification after a detection event has completed.
     *
     * @param   id The monotonically increasing event id.
     * @param   ts The start time of the event in milliseconds.
     * @param   te The end time of the event in milliseconds.
     * @param   energy The enegy content in the signal.
     */
    event result_t classification
    (
        uint16_t id,
        //uint32_t t0,
        uint32_t t1,
        Pair_int32_t* energy,
        TargetInfo_t* targets
    );
}
