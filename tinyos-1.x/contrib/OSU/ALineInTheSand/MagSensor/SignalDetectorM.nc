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
 * Implements the SignalDetector interface.  The output of the SignalDetectorM
 * module is true during the interval in which a target passes by the sensor
 * and false otherwise.  The module implements a Neyman-Pearson detector that
 * works by building a histogram, initially offline, (the histogram serves as a
 * proxy for the probability density function) of the variance in the noise (the
 * noise is assumed to be Gaussian) over a long period of time and comparing it
 * to the (nearly) instantaneous signal variance as reported by the
 * MovingStatistics module.  The module is susceptible to Type I (false alarm
 * or false positive) or Type II (miss or false negative) errors if the noise
 * is not Gaussian or if the signal does not satisfy a minimum signal-to-noise
 * ratio, respectively.  It is possible to reduce the Type I error probability
 * at the expense of the Type II error probability.  It is not possible to
 * simultaneously reduce both types of error probabilities.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

// TODO Comment out the following line to disbale LED display of detector state.
#define SIG_DETECT_USE_LEDS

module SignalDetectorM
{
    provides
    {
        interface StdControl;
        interface SignalDetector;
    }
    uses
    {
        interface Leds;
        interface MovingStatistics;
    }
}

implementation
{
    // Flag variables used to indicate that a detection has occurred on
    // x-axis and/or the y-axis.  Assume no event has occurred.
    Pair_bool_t detected = {FALSE, FALSE};

    // The monotonically increasing event id.
    uint16_t id = 0;

    // The state of the x-axis and y-axis detector state machines.
    Pair_uint8_t state = {NOISE, NOISE};

    // The average background noise.  These values are updated when new moving
    // statistics are reported.
    Pair_int32_t noise = {0, 0};

    // This is the previous value of variance (e.g. y(n-1)).
    Pair_int32_t varhist = {0, 0};

    // A countdown timer used to determine that enough time had passed in the
    // presense of the DC signal to call a detection complete.  The value of
    // this timer determines the slowest moving target that the system can
    // detect.
    Pair_uint16_t countdown = {COUNTDOWN_TIME, COUNTDOWN_TIME};

    // Signal-Noise-Difference Threshold.  This threshold determines when a DC
    // signal presence is detected.  That is, when the magnitude of the
    // difference between the signal and noise exceeds this threshold.  This
    // threshold should be determined dynamically and experimentally.
    // TODO Adjust this threshold.
    Pair_int32_t snd_threshold = {5, 5};

    // Variance Threshold.
    // TODO Adjust this threshold.
    Pair_int32_t variance_threshold = {VARIANCE_THRESHOLD, VARIANCE_THRESHOLD};

    /**
     * Called one or more times to initialize this component.
     */
    command result_t StdControl.init()
    {
        // TODO initialize any subcomponents.
        #ifdef SIG_DETECT_USE_LEDS
            call Leds.init();
        #endif
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
     * The event handler that is called whenever the MovingVariance has new
     * statistics to report.  The following logic is used to determine if an
     * event of interest has occurred.  If the moving variance exceeds a given
     * threshold, then the detector signals an event.  However, this approach
     * either tends to work poorly with smaller windows near regions where the
     * signal's derivative changes sign or requires a longer window causing a
     * delay in detection and resulting in poor energy estimation unless the
     * signal chain leading into the EnergyEstimator is buffered.  Here a
     * state machine based detector is used that combines a variance change
     * detector and a DC signal level detector.
     *
     * <pre>
     * Let:
     *   N = constant
     *   x = signal (filtered)
     *   s = variance
     *   m = signal mean (very long window)
     *   s* = variance threshold
     *   x* = signal threshold
     * We have the following states:
     *   w1: NOISE: no change or offset (bias) in signal
     *   w2: AC: change in signal
     *   w3: DC: offset or bias in signal
     * The state transitions are as follow where we use the notation:
     *   <present state> -> <next state> : <transition predicate> : <state variables>
     *   w1 -> w1:   s <= s*                         :   d = 0
     *   w1 -> w2:   s > s*                          :   d = 1
     *   w2 -> w1:   (s <= s*) ^ (|x-m| <= x*)       :   d = 0
     *   w2 -> w2:   s > s*                          :   d = 1
     *   w2 -> w3:   (s <= s*) ^ (|x-m| > x*)        :   d = 0, countdown = N
     *   w3 -> w1:   (|x-m| <= x*) V (countdown = 0) :   d = 0
     *   w3 -> w2:   s > s*                          :   d = 1
     *   w3 -> w3:   (|x-m| > x*) ^ (countdown = >)  :   d = 1, countdown -= 1
     * </pre>
     * For each sensor and axis.
     *
     * @param   average     The average in the recent MOVING_WINDOW_SIZE
     *          magnetometer readings.
     * @param   variance    The variance in the recent MOVING_WINDOW_SIZE
     *          magnetometer readings.
     */
    event result_t MovingStatistics.statistics
    (
        Pair_int32_t* average,
        Pair_int32_t* variance
    )
    {
        // A flag variable used for housekeeping/tracking state changes.
        bool alreadDetected = FALSE;

        // The Signal-Noise-Difference.
        Pair_int32_t snd;

        // Compute the Signal-Noise-Difference.
        snd.x = (int32_t)(average->x) - noise.x;
        snd.y = (int32_t)(average->y) - noise.y;

        // Compute the magnitude of the Signal-Noise-Difference.
        snd.x = snd.x < 0 ? (-snd.x) : snd.x;
        snd.y = snd.y < 0 ? (-snd.y) : snd.y;

        if ( (detected.x == TRUE) || (detected.y == TRUE) )
        {
            alreadDetected = TRUE;
        }
        else
        {
            alreadDetected = FALSE;
        }

        // Apply an IIR LPF to the variance to "smooth out the moving variance"
        // and lower false positives and multiple detections of a single target.
        varhist.x = (variance->x + 7*varhist.x)/8;
        varhist.y = (variance->y + 7*varhist.y)/8;

        // Run through the x-axis detector state machine.
        switch (state.x)
        {
            case NOISE:
            {
                if (varhist.x <= variance_threshold.x)
                {
                    state.x = NOISE;
                    detected.x = FALSE;
                }
                if (varhist.x > variance_threshold.x)
                {
                    state.x = AC;
                    detected.x = TRUE;
                }
                break;
            }
            case AC:
            {
                if ((varhist.x <= variance_threshold.x) && (snd.x <= snd_threshold.x))
                {
                    state.x = NOISE;
                    detected.x = FALSE;
                }
                if (varhist.x > variance_threshold.x)
                {
                    state.x = AC;
                    detected.x = TRUE;
                }
                if ((varhist.x <= variance_threshold.x) && (snd.x > snd_threshold.x))
                {
                    state.x = DC;
                    detected.x = TRUE;
                    countdown.x = COUNTDOWN_TIME;
                }
                break;
            }
            case DC:
            {
                if ((snd.x <= snd_threshold.x) || (countdown.x == 0))
                {
                    state.x = NOISE;
                    detected.x = FALSE;
                }
                if (varhist.x > variance_threshold.x)
                {
                    state.x = AC;
                    detected.x = TRUE;
                }
                if ((snd.x > snd_threshold.x) && (countdown.x > 0))
                {
                    state.x = DC;
                    detected.x = TRUE;
                    countdown.x = countdown.x - 1;
                }
                break;
            }
        }
        // Run through the y-axis detector state machine.
        switch (state.y)
        {
            case NOISE:
            {
                if (varhist.y <= variance_threshold.y)
                {
                    state.y = NOISE;
                    detected.y = FALSE;
                }
                if (varhist.y > variance_threshold.y)
                {
                    state.y = AC;
                    detected.y = TRUE;
                }
                break;
            }
            case AC:
            {
                if ((varhist.y <= variance_threshold.y) && (snd.y <= snd_threshold.y))
                {
                    state.y = NOISE;
                    detected.y = FALSE;
                }
                if (varhist.y > variance_threshold.y)
                {
                    state.y = AC;
                    detected.y = TRUE;
                }
                if ((varhist.y <= variance_threshold.y) && (snd.y > snd_threshold.y))
                {
                    state.y = DC;
                    detected.y = TRUE;
                    countdown.y = COUNTDOWN_TIME;
                }
                break;
            }
            case DC:
            {
                if ((snd.y <= snd_threshold.y) || (countdown.y == 0))
                {
                    state.y = NOISE;
                    detected.y = FALSE;
                }
                if (varhist.y > variance_threshold.y)
                {
                    state.y = AC;
                    detected.y = TRUE;
                }
                if ((snd.y > snd_threshold.y) && (countdown.y > 0))
                {
                    state.y = DC;
                    detected.y = TRUE;
                    countdown.y = countdown.y - 1;
                }
                break;
            }
        }


        if ( ( (detected.x == TRUE) || (detected.y == TRUE) ) &&
             (alreadDetected == FALSE) )
        {
            // Monotonically increment the event id if either axis detects new.
            id += 1;
        }

        // Update noise using the filter: y(n) = 0.96875*y(n-1) + 0.03125*x(n)
        noise.x = (31*(noise.x) + average->x)/32;
        noise.y = (31*(noise.y) + average->y)/32;

        // Signal the detection status.
        signal SignalDetector.detected(id, &detected);

        #ifdef SIG_DETECT_USE_LEDS
            // Turn off all the LEDs
            //call Leds.greenOff();
            //call Leds.yellowOff();
            call Leds.redOff();

            if (state.x == AC || state.y == AC)
            {
                call Leds.redOn();
            }
            else if (state.x == DC || state.y == DC)
            {
            //    call Leds.yellowOn();
            }
            else if (state.x == NOISE && state.y == NOISE)
            {
            //    call Leds.greenOn();
            }
        #endif

        return SUCCESS;
    }
}
