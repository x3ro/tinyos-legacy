/**
 * The MovingStatistics interface provides the mean and variance values of a
 * data stream through an event MovingStatistics.statistics.
 *
 * @author  Prabal Dutta
 */
includes common_structs;

interface MovingStatistics
{
    event result_t statistics(Pair_int32_t* average, Pair_int32_t* variance);
}
