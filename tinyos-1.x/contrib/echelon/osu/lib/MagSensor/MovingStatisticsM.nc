/**
 * The MovingStatistics module recomputes the variance (and mean) over the
 * previous n data samples every time a new sample is available.  Every
 * recomputation results in an event, MovingStatistics.statistics, that
 * propagates the mean and variance values.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

module MovingStatisticsM
{
    provides
    {
        interface StdControl;
        interface MovingStatistics;
    }
    uses
    {
        interface MagSampler;
    }
}

implementation
{
    // The current index into the samples circular buffer.
    uint16_t index = 0;

    // Holds the last MOVING_WINDOW_SIZE samples of the B.x and B.y
    // values.
    Pair_int16_t samples[VARIANCE_WINDOW_SIZE];

    Pair_int32_t average = {0, 0};
    Pair_int32_t variance = {0, 0};

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
     * The event handler that is called whenever the MagSampler has new data to
     * present.  Extracts the B.x and B.y values, adds to the variance history,
     * recomputes the variance, and signals a newData event.  TODO make the
     * implementation more efficient.
     *
     * @param   The most recent x- and y-axis magnetometer readings.
     */
    event result_t MagSampler.newData(Pair_int16_t* B)
    {
        // Loop counters.
        uint16_t i;

        // Local variables.
        Pair_int32_t sum = {0, 0};

        // Increment the data pointer, modulo the window size.
        index = (index + 1) % VARIANCE_WINDOW_SIZE;

        // Add the new data element to the samples.
        samples[index].x = (B->x);
        samples[index].y = (B->y);

        // Compute the average across all of the samples.
        for (i = 0; i< VARIANCE_WINDOW_SIZE; i++)
        {
            sum.x += samples[i].x;
            sum.y += samples[i].y;
        }
        average.x = sum.x / VARIANCE_WINDOW_SIZE;
        average.y = sum.y / VARIANCE_WINDOW_SIZE;

        // Compute the variance.  Does *not* normalize the variance with a
        // 1/(N-1) factor as would normally be done computing a sample variance.
        variance.x = 0;
        variance.y = 0;
        for (i = 0; i< VARIANCE_WINDOW_SIZE; i++)
        {
            // variance.x = (samples[i].x - average.x)*(samples[i].x - average.x);
            variance.x += average.x > samples[i].x ?
            (average.x - samples[i].x) * (average.x - samples[i].x) :
            (samples[i].x - average.x) * (samples[i].x - average.x) ;

            // variance.y = (samples[i].y - average.y)*(samples[i].y - average.y);
            variance.y += average.y > samples[i].y ?
            (average.y - samples[i].y) * (average.x - samples[i].y) :
            (samples[i].y - average.y) * (samples[i].y - average.y) ;
        }

        // Signal the event.
        return signal MovingStatistics.statistics(&average, &variance);
    }
}
