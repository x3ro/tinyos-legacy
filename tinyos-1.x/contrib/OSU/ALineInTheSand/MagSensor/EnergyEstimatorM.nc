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
 * Implements the EnergyEstimator interface. Determines the energy content of
 * the non-DC component of the magnetometer signal.  The estimator begins the
 * energy computation when the output of the SignalDetector is true and stops
 * when the output of SignalDetector later becomes false.  The component is
 * tolerant to multiple SignalDetector.detected(bool) calls in which the
 * parameter value remains constant (i.e. remains either true or false but
 * does not get toggled).  The interval over which the energy content is
 * computed is called the period of the signal.  The energy is computed by
 * subtracting the moving average, or bias, from the signal and then summing
 * the squares of the resulting values over the period of the signal.  An
 * event is signaled upon completion of the energy content computation.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

module EnergyEstimatorM
{
    provides
    {
        interface StdControl;
        interface EnergyEstimator;
    }
    uses
    {
        interface SignalDetector;
        interface MovingStatistics;
    }
}

implementation
{
    // Keeps track of whether an energy computation is in progress.
    bool computing = FALSE;

    // A monotonically increasing detection event id.
    uint16_t deid = 0;

    // The signal energy content in the samples.
    Pair_int32_t energy = {0, 0};

    // The average noise content in the samples.
    Pair_int32_t noise = {0, 0};

    /**
     * Called one or more times to initialize this component.
     */
    command result_t StdControl.init()
    {
        return SUCCESS;
    }

    /**
     * Called once to start this component.
     */
    command result_t StdControl.start()
    {
        return SUCCESS;
    }

    /**
     * Called once to stop this component.
     */
    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    /**
     * The event handler that is called when the SignalDetector detects the
     * presence of a signal of interest.
     *
     * @param   id      a monotonically increasing detection event id.
     * @param   true    if a signal is likely present, false otherwise.
     */
    event result_t SignalDetector.detected(uint16_t id, Pair_bool_t* detected)
    {
        // Check if a computation is in progress that should be finished.
        if (computing == TRUE && (detected->x == FALSE && detected->y == FALSE))
        {
            // Signal the energy content.
            signal EnergyEstimator.energy(id, &energy);

            // Reset the energy value for the next computation.
            energy.x = 0;
            energy.y = 0;
        }
        computing = detected->x | detected->y;
        return SUCCESS;
    }


    /**
     * The event handler that is called when the MovingVariance has new
     * statistics to report.  The average value of the signal over a small
     * number of samples is used as our signal and our signal+noise, depending
     * on whether or not the signal is present, extracts the B.x and B.y values,
     * subtracts the noise, squares the results, and keeps a running total until
     * the signal is no longer present.  Signal presence is indicated by the
     * computing variable (which is updated by the SignalDetector module).
     *
     * @param   average     The average in the recent MOVING_VARIANCE_WINDOW_SIZE
     *          magnetometer readings.
     * @param   variance    The variance in the recent MOVING_VARIANCE_WINDOW_SIZE
     *          magnetometer readings.
     */
    event result_t MovingStatistics.statistics
    (
        Pair_int32_t* average,
        Pair_int32_t* variance
    )
    {
        // If not computing, then store these value as the statistics for the
        // background noise.
        if (computing == FALSE)
        {
            noise.x = average->x;
            noise.y = average->y;
        }
        // If computing, then add to the growing energy content of the signal.
        if (computing == TRUE)
        {
            energy.x += average->x > noise.x ?
                (average->x - noise.x) * (average->x - noise.x) :
                (noise.x - average->x) * (noise.x - average->x) ;

            energy.y += average->y > noise.y ?
                (average->y - noise.y) * (average->y - noise.y) :
                (noise.y - average->y) * (noise.y - average->y) ;
        }
        return SUCCESS;
    }
}
