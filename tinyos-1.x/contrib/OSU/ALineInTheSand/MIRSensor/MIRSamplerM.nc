/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * Implements the MIRSampler interface.
 *
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
includes MIR;

module MIRSamplerM
{
    provides
    {
        interface StdControl;
        interface MIRSampler;
    }
    uses
    {
        interface Timer;
        interface MIRSensor;
        interface StdControl as TimerControl;
    }
}

implementation
{
    /**
     * The Timer event handler that is called whenever the Timer fires.  This
     * starts the process of reading data from the MIRSensor.
     *
     * @return  the results of the MIRSensor read call.
     */
    event result_t Timer.fired()
    {
        return call MIRSensor.read();
    }


    /**
     * The event that is signaled whenever the MIRSensor completes a reading
     * of the MIR's analog output.
     *
     * @param   datum    The current value of the MIR's analog output.
     */
    event result_t MIRSensor.readDone(uint16_t datum)
    {
        return signal MIRSampler.newData((int16_t)datum);
    }


    /**
     * Called exactly once to initialize this component.
     */
    command result_t StdControl.init()
    {
        // TODO initialize any subcomponents.
        return call TimerControl.init();
    }


    /**
     * Called once to start this component.
     */
    command result_t StdControl.start()
    {
        // Start the TimerC code.
        call TimerControl.start();

        // Start the timer in a repeat mode with the sampling period.
        call Timer.start(TIMER_REPEAT, 1000/MIR_SAMPLING_FREQUENCY);

        return SUCCESS;
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
}
