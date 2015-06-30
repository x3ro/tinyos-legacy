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
 * The MagSamplerM module implements the MagSampler interface.  This module has
 * an event handler named that accepts a parameter of type Mag_t* and adjusts
 * and/or normalizes these data points based on bias values.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

module MagSamplerM
{
    provides
    {
        interface StdControl;
        interface MagSampler;
    }
    uses
    {
        interface Timer;
        interface MagSensor;
    }
}

implementation
{
    // The sampling period in milliseconds.
    uint32_t Ts = SAMPLING_PERIOD_MILLIS;

    // The current index into the samples circular buffer.
    uint16_t index = 0;

    // The sample buffer.
    Pair_int16_t samples[LPF_WINDOW_SIZE];

    /**
     * Called one or more times to initialize this component.
     */
    command result_t StdControl.init()
    {
        // TODO initialize any subcomponents.
        return SUCCESS;
    }

    /**
     * Called once to start this component.
     */
    command result_t StdControl.start()
    {
        // Start the timer with the specified sampling period and return
        // the result value.
        return call Timer.start(TIMER_REPEAT, Ts);
    }

    /**
     * Called once to stop this component.
     */
    command result_t StdControl.stop()
    {
        // Stop the timer.  Note that the timer can be restarted with another
        // call to the StdControl.start.
        return call Timer.stop();
    }


    /**
     * The Timer event handler that is called whenever the Timer fires.  This
     * starts the process of reading data from the MagSensor.
     * @return  the results of the MagSensor read call.
     */
    event result_t Timer.fired()
    {
        return call MagSensor.read();
    }


    /**
     * The MagSensor event handler that is called whenever the MagSensor
     * completes a reading.
     * @param   A structure pointer
     */
    event result_t MagSensor.readDone(Mag_t* mag)
    {
        // Loop variables.
        int i;

        // Holds the x- and y-components of the magnetic field B.
        Pair_int16_t B;

        // Holds the sum - a local variable for computing the moving average.
        Pair_int32_t sum = {0, 0};

        // Increment the data pointer, modulo the window size.
        index = (index + 1) % LPF_WINDOW_SIZE;

        // Convert to signed int and add the new reading to the samples.
        samples[index].x = (int16_t)(mag->rawx);
        samples[index].y = (int16_t)(mag->rawy);

        // Low pass filter the data by using n-point (n=LPF_WINDOW_SIZE) moving
        // average across all of the samples.
        for (i = 0; i< LPF_WINDOW_SIZE; i++)
        {
            sum.x += samples[i].x;
            sum.y += samples[i].y;
        }
        // Divide by the number of samples.
        B.x = sum.x / LPF_WINDOW_SIZE;
        B.y = sum.y / LPF_WINDOW_SIZE;

        // Signal the event.
        return signal MagSampler.newData(&B);
    }
}
