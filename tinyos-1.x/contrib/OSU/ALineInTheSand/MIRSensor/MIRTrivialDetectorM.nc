/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * Implements a trivially simple MIR detector module that determines target
 * presence based directly on the probability mass function of the sampled
 * data.
 *
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
includes MIR;

#define FALSE_STATE         0
#define TRUE_STATE          1
#define HYSTERESIS_STATE    2


module MIRTrivialDetectorM
{
    provides
    {
        interface StdControl;
        interface MIRSignalDetector;
    }
    uses
    {
        interface MIRSampler;
        interface Time;
    }
}

implementation
{
    // The monotonically increasing interval id.
    uint16_t interval = 0;

    // Keeps track of the number of data points that have been collected in
    // the current window.
    uint16_t count = 0;

    // The histogram is an normalized approximate estimator of the probability
    // mass function over the data points collected during the current window.
    uint16_t histogram[MIR_STATS_HIST_BINS];

    // The timesync data structure
    timeSync_t currentTime;

    // The start, end, and duration time of the event.
    uint32_t timestamp;


    /**
     * Put the datum into a circular buffer for later processing.
     *
     * @param   datum The most recent data point.
     */
    inline void putData(int16_t datum)
    {
        // Holds the bin number into which a datum will be deposited.
        uint16_t bin;

        // Possibly clip the datum to fit the max value of the current window.
        datum = datum > MIR_MAX_VAL ? MIR_MAX_VAL : datum;

        // Compute the bin into which this data point goes.
        bin = (datum * MIR_STATS_HIST_BINS)/MIR_MAX_VAL;
        bin = bin < MIR_STATS_HIST_BINS ? bin : MIR_STATS_HIST_BINS - 1;

        // Increment the correct bin in the histogram given this data point.
        histogram[bin]++;

        // Update the count of data points that have been seen in this period.
        count++;
    }


    /**
     * This task determines whether a signal is likely to be present by:
     * dividing the histogram into thirds and determining if the two
     * outside thirds together have more data points than the middle third.
     * TODO First find the min and max values, and then scale appropriately.
     */
    void task processData()
    {
        int16_t i;
        static uint16_t id;
        static bool output;
        static bool detected;
        static int16_t state;
        static int8_t hysteresis;

        // These thresholds can be changed to improve performance.
        static int16_t MIN;
        static int16_t MID;
        static int16_t MAX;

        uint16_t minmass = 0;
        uint16_t midmass = 0;
        uint16_t maxmass = 0;

        // Auto-detect input range during the first 20 seconds.
        if (interval < 20)
        {
            int key = 0;
            for (i = 0; i < MIR_STATS_HIST_BINS ; i++)
            {
                if (histogram[i] > 0)
                {
                    key = i;
                }
            }
            // Set MAX to the larger of key and MAX.
            MAX = key > MAX ? key : MAX;

            // Auto-calibrate remaining thresholds.
            MID = (2*MAX+1)/3 + 1;
            MIN = (1*MAX+1)/3 + 1;
        }

        for (i = 0; i < MIN; i++)
        {
            minmass += histogram[i];
        }
        for (i = MIN; i < MID; i++)
        {
            midmass += histogram[i];
        }
        for (i = MID; i < MAX; i++)
        {
            maxmass += histogram[i];
        }

        detected = (minmass + maxmass) > midmass ? TRUE : FALSE;

        // Implement the hysteresis algorithm.
        switch (state)
        {
            case FALSE_STATE:
            {
                if (detected)
                {
                    state = TRUE_STATE;
                    id++;
                    output = TRUE;
                }
                break;
            }
            case TRUE_STATE:
            {
                if (!detected)
                {
                    state = HYSTERESIS_STATE;
                    hysteresis = MIR_CFAR_HYSTERESIS;
                }
                break;
            }
            case HYSTERESIS_STATE:
            {
                hysteresis--;
                if (detected)
                {
                    state = TRUE_STATE;
                }
                else if ( (!detected) & (hysteresis <= 0) )
                {
                    state = FALSE_STATE;
                    output = FALSE;
                }
                break;
            }
        }

        // Get global time.
        call Time.getGlobalTime(&currentTime);
        timestamp = currentTime.clock;

        // Signal the event.
        signal MIRSignalDetector.detected
        (
            0x0a,
            output,
            interval,
            ((MID << 4) & 0xf0) + (MIN & 0x0f),
            ((MID << 4) & 0xf0) + (MIN & 0x0f),
            histogram,
            timestamp
        );

        // Clear/update the state variables for the next window.
        interval++;
        count = 0;

        // Clear the histogram data for the next window.
        for (i = 0; i < MIR_STATS_HIST_BINS; i++)
        {
            histogram[i] = 0;
        }
    }


    /**
     * The event handler that is called whenever the MIRSampler has a new datum
     * to present.
     *
     * @param   datum The most recent data point.
     */
    event result_t MIRSampler.newData(int16_t datum)
    {
        // Put the data in a circular buffer.
        putData(datum);

        // If the window has been filled.
        if (count >= MIR_STATS_WINDOW_SIZE)
        {
            // Post a task for delayed processing of the data.
            post processData();
        }

        return SUCCESS;
    }


    /**
     * Called exactly once to initialize this component.
     */
    command result_t StdControl.init()
    {
        // TODO initialize any subcomponents.
        return SUCCESS;
    }

    /**
     * Called one or more times to to start this component.
     */
    command result_t StdControl.start()
    {
        // Loop variable.
        int i;

        // Clear/update state variables.
        count = 0;
        for (i = 0; i < MIR_STATS_HIST_BINS; i++)
        {
            histogram[i] = 0;
        }
        return SUCCESS;

    }

    /**
     * Called one or more times to to stop this component.
     */
    command result_t StdControl.stop()
    {
        return SUCCESS;
    }
}
