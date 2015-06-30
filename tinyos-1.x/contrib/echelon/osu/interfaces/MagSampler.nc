/**
 * The MagSampler interface can abstraction and encapsulate of any component
 * that provides the MagSensor interface.
 *
 * @author  Prabal Dutta
 */
interface MagSampler
{
    /**
     * The MagSampler event.  Called when a new reading is available.
     * @param   B the magnetometer values. B.x is the x-axis reading and B.y is
     *          the y-axis reading.
     */
    event result_t newData(Pair_int16_t* B);
}
