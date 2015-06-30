/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * Defines constants, structures, etc. for the MIRDetector package.
 *
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */

// The largest legal ADC value that can be produced by the MIR analog output.
#define MIR_MAX_VAL                 1023

// The MIR analog sampling frequency in Hertz.
#define MIR_SAMPLING_FREQUENCY      128

// The MIR analog sampling period in milliseconds.
#define MIR_SAMPLING_PERIOD_MILLIS  1000/MIR_SAMPLING_FREQUENCY

// The number of the data points over which to compute moving statistics.
#define MIR_STATS_WINDOW_SIZE       128

// The number of "bins" to use when organizing the data into a histogram.
#define MIR_STATS_HIST_BINS         16

// The number historical variance values used for the variance estimator.
#define MIR_CFAR_HIST_SIZE          5

// Sets the smallest period (1/highest frequency) that a signal can change.
// The units are: (MIR_STATS_WINDOW_SIZE/MIR_SAMPLING_FREQUENCY) * seconds.
// So, a value of MIR_CFAR_HYSTERESIS = 3, MIR_STATS_WINDOW_SIZE = 250 and
// MIR_SAMPLING_FREQUENCY = 125 will give: 3*(250/125) = 6 seconds hysteresis.
#define MIR_CFAR_HYSTERESIS         3

// 1000 x the constant false alarm rate threshold for a standard normal curve.
// This value is computed by first selecting a false alarm rate PFA, and then
// finding the value of the upper limit of integration (x*) such that 1 (one)
// minus the integral of (area under) the standard normal curve from negative
// infinity to x* is equal to PFA.  Unfortunately, there is no closed from
// approach to computing PFA given x*.  A simple approach to determining PFA
// given x* is to use Microsoft Excel's standard normal distribution function
// as follows: PFA=1-NORMSDIST(x*) for a X = N(0,1) (read X is distributed
// normally with a mean of zero and variance of 1).  The NORMSDIST(Z) function
// returns the area under the standard normal distribution curve from negative
// infinity to Z.  Some useful PFA and x* values:
//
// x*   NORMDIST(Z) PFA     CFAR_THRESHOLD = 1000*(x*)
// ==== =========== ======  ==============
// 2.33 0.990       0.01    2330
// 3.10 0.9990      0.001   3100
// 3.72 0.99990     0.0001  3720
#define MIR_CFAR_THRESHOLD  25000


// Macro that assigns MIR_DIN (MIR Digital Input) to PORTE, bit 2.
TOSH_ASSIGN_PIN(MIR_DIN, E, 2);


/*
typedef struct
{
    uint16_t id;
    uint32_t t0;
    uint32_t t1;
    uint16_t minmax;
    uint32_t energy;
} halfwave_t;
*/


