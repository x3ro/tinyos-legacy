/**
 * The Classifier interface provides detection and classification related event
 * callbacks.
 *
 * @author  Prabal Dutta
 */
includes common_structs;
includes MagConstants;

interface Classifier
{
    /**
     * The event handler that is called whenever the Classifier first detects
     * a target.
     *
     * @param   id The monotonically increasing event id.
     * @param   ts The start time of the event in milliseconds.
     */
    event result_t detection
    (
        uint16_t id,
        uint32_t t0
    );

    /**
     * The event handler that is called whenever the Classifier completes
     * a target classification after a detection event has completed.
     *
     * @param   id The monotonically increasing event id.
     * @param   ts The start time of the event in milliseconds.
     * @param   te The end time of the event in milliseconds.
     * @param   energy The enegy content in the signal.
     */
    event result_t classification
    (
        uint16_t id,
        //uint32_t t0,
        uint32_t t1,
        Pair_int32_t* energy,
        TargetInfo_t* targets
    );
}
