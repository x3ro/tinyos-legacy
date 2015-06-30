/**
 * Implements the Classifier interface.  Perform target classification based on
 * variety of signal parameters.
 *
 * @author  Prabal Dutta
 */
includes MagConstants;
includes common_structs;
includes OTime;

module ClassifierM
{
    provides
    {
        interface StdControl;
        interface Classifier;
    }
    uses
    {
        interface EnergyEstimator;
        interface SignalDetector;
        interface OTime;
	  interface StdControl as TsyncControl;
	  //interface Xnp;
	  //interface StdControl as GenericCommCtl;
    }
}

implementation
{
    // A flag that is true if the ClassifierM is in the process of measuring
    // the duration of an event.
    bool measuring;

    // The timesync data structure
    //timeSync_t currentTime;

    // The start, end, and duration time of the event.
    uint32_t startTime, endTime, duration;

    // Event ID as reported by the SignalDetector.
    uint16_t did = 0;

    // Event ID as reported by the EnergyEstimator.
    uint16_t eid = 0;

    // The energy content in the event identified by eid.
    Pair_int32_t energy = {0, 0};

    // A stucture to keep track of the targets.
    TargetInfo_t targets;


    /**
     * Called one or more times to initialize this component.
     */
    command result_t StdControl.init()
    {
        TOSH_MAKE_PW0_OUTPUT();
        TOSH_SET_PW0_PIN();

        TOSH_MAKE_PW1_OUTPUT();
        TOSH_SET_PW1_PIN();

	  return call TsyncControl.init();
//        return rcombine(call Xnp.NPX_SET_IDS(), call //GenericCommCtl.init());    
    }

    /**
     * Called once to start this component.
     */
    command result_t StdControl.start()
    {
        // Reset the measuring state.
        measuring = FALSE;

        // Reset targets and probabilities.
        targets.target_1 = 0;
        targets.target_2 = 0;
        targets.target_3 = 0;
        targets.probability_1 = 0;
        targets.probability_2 = 0;
        targets.probability_3 = 0;

        return call TsyncControl.start();
    }

    /**
     * Called once to stop this component.
     */
    command result_t StdControl.stop()
    {
        return call TsyncControl.stop();
    }

    /**
     * The event handler that is called when the SignalDetector detects the
     * presence of a signal of interest.  Measures the length of the signal
     * detection event.
     *
     * @param   id The monotonically increasing event id.
     * @param   true if a signal is likely present, false otherwise.
     */
    event result_t SignalDetector.detected(uint16_t id, Pair_bool_t* detected)
    {
        // Set the detection id.
        did = id;

        // Log the current time as a start time and send a message if we're not
        // currently measuring (i.e. the first time we see detected message with
        // the given id.
        if ((measuring == FALSE) && ((detected->x == TRUE) || (detected->y == TRUE)))
        {
            // Go into the measuring state.
            measuring = TRUE;

            // Get the global time.
            //call Time.getGlobalTime(&currentTime);
            startTime = call OTime.getGlobalTime32();

            // Signal an event start detected.
            signal Classifier.detection(id, startTime);
        }

        // Log the current time as an end time if appropriate.
        if ((measuring == TRUE) && ((detected->x == FALSE) && (detected->y == FALSE)))
        {
            // Exit the measuring state.
            measuring = FALSE;

            // Get global time.
            //call Time.getGlobalTime(&currentTime);
            endTime = call OTime.getGlobalTime32();
            //duration = endTime - startTime;

            // Check if the EnergyEstimator has already reported.  If so, then
            // report the classification.
            if (did == eid)
            {
                // TODO Classify the signal.
                // call classify();

                // Signal the target information.
                signal Classifier.classification
                (
                    id,
			  endTime,
                    &energy,
                    &targets
                );
            }
        }
        return SUCCESS;
    }


    /**
     * The event handler that is called when the EnergyEstimator outputs the
     * energy content in an event of interest.
     *
     * @param   id The monotonically increasing event id.
     * @param   e   The energy content of the signal during an event.
     */
    event result_t EnergyEstimator.energy(uint16_t id, Pair_int32_t* e)
    {
        // Set the detection id for the energy.
        eid = id;

        // Save the energy.
        energy.x = e->x;
        energy.y = e->y;

        // Check if the SignalDetector has already reported.  If so, then
        // report the classification.
        if (did == eid)
        {
            // TODO Classify the signal.
            // call classify();

            // Signal the target information.
            signal Classifier.classification
            (
                id,
		    endTime,
                &energy,
                &targets
            );
        }
        return SUCCESS;
    }


    /**
     * TODO Classify the target.
     */
/*TODO - flesh out
    command result_t classify()
    {
        return SUCCESS;
    }
*/
/*
 event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP){
    return call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP){
    return SUCCESS;
  }
*/
}
