/**
 * The EnergyEstimator interface defines an event callback which provides the
 * energy content of a signal.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

interface EnergyEstimator
{
    /**
     * The event handler that is called whenever the EnergyEstimator has
     * completed its computation of the energy content of a signal.
     * @param   id  A monotonically increasing id the corresponds with
     *          the the event id.  Can be used to match outputs of
     *          multiple detectors, estimators, and classifiers.
     * @param   energy  The energy content in the signal.
     */
    event result_t energy(uint16_t id, Pair_int32_t* energy);
}
