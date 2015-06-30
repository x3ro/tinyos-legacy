/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * Implements the MIRSensor interface.  Based on Hui Cao and Vineet Mittal's
 * original MIRSensor package.
 *
 * @author  Hui Cao <caoh@cis.ohio-state.edu>
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
includes MIR;

module MIRSensorM
{
    provides
    {
        interface StdControl;
        interface MIRSensor;
    }
    uses
    {
        interface ADC;
        interface ADCControl;
    }
}


implementation
{
    /**
     * Reads the MIR's digital output.
     *
     * @return  TRUE if the digital output is low (target detected), FALSE if
     *          if the digital output is high (no target detected).
     */
    command bool MIRSensor.isTrue()
    {
        // The MIR DIN is asserted low, hence the inverted logic.
        return !(TOSH_READ_MIR_DIN_PIN());
    }


    /**
     * Initiates a reading of the analog output of the MIR sensor.
     */
    command result_t MIRSensor.read()
    {
        return call ADC.getData();
    }


    /**
     * The event that is signaled whenever the ADC completes an analog-to-
     * digital conversion.
     *
     * @param   data    The current value of the MIR's analog output.
     */
    event result_t ADC.dataReady(uint16_t data)
    {
        return signal MIRSensor.readDone(data);
    }


    /**
     * Called exactly once to initialize this component.
     */
    command result_t StdControl.init()
    {
        // Initialize the ADC controller.
        return call ADCControl.init();
    }


    /**
     * Called once to start this component.
     */
    command result_t StdControl.start()
    {
        // Turn on the power control pins for Mica Power Board.
        TOSH_SET_PW0_PIN();
        TOSH_SET_PW1_PIN();

        // Turn on the power control pin for MIR Sensor.
        TOSH_SET_PW4_PIN();

        return SUCCESS;
    }


    /**
     * Called once to stop this component.
     */
    command result_t StdControl.stop()
    {
        // Turn off the power control pins for Mica Power Board.
        TOSH_CLR_PW0_PIN();
        TOSH_CLR_PW1_PIN();

        // Turn off the power control pin for MIR Sensor.
        TOSH_CLR_PW4_PIN();

        return SUCCESS;
    }
}
