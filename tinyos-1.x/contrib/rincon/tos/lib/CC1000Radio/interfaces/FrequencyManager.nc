
/**
 * Frequency manager for the CC1000 radio
 * @author David Moss
 */
 
interface FrequencyManager {

  /**
   * Tune to a preset frequency located in the preset array in the
   * CC1000Const.h file
   * @param presetFreqIndex - the index in the preset array to tune to
   * @return SUCCESS if the frequency is adjusted
   */
  command void tunePreset(uint8_t presetFreqIndex);
  
  /**
   * Tune to a manual frequency
   * @param freqHz - the frequency, in hertz, to tune to. i.e. 914077076
   * @return SUCCESSS if the frequency is adjusted
   */
  command uint32_t tuneManual(uint32_t freqHz);

  /** 
   * Auto-Recalibration is on by default.
   *
   * Enable or disable the automatic recalibrations. Temperature and
   * voltage variations will cause the frequency to drift over time.
   * Recalibrating the radio frequencies every few hours will prevent this
   * @param on - TRUE if recalibration should be on, FALSE if it shouldn't
   * @param hours - the delay, in hours, after which to auto recalibrate
   */
  command void setAutoRecalibration(bool on, uint8_t hours);  

  /**
   * Calibrate the CC1000 radio
   * @return SUCCESS if the radio is recalibrated
   */
  command result_t calibrate();
  
}

