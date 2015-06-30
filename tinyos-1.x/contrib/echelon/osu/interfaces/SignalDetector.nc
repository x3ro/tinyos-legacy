/**
 * The SignalDetector defines an interface for notifying, through event
 * callbacks, a listner whenever an sufficient change in the signal exists to
 * claim that a target is present.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;

interface SignalDetector
{
    /**
     * Indicates that a signal has been detected.
     *
     * @param   id The monotonically increasing event id.
     * @param   true if a signal is likely present, false otherwise.
     */
    event result_t detected(uint16_t id, Pair_bool_t* detected);
}
