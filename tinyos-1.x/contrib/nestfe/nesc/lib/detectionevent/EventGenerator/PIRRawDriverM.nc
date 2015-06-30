/*
 * @author Cory Sharp, Phoebus Chen
 * @modified 7/21/2005 copied and modified from PirRawEventM.nc
 */

//$Id: PIRRawDriverM.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

module PIRRawDriverM
{
  uses interface PIR;
  uses interface ADC;
  uses interface Timer;
  uses interface Attribute<uint16_t> as PirSampleTimer @registry("PirSampleTimer");
  uses interface Attribute<uint16_t> as PIRRawValue @registry("PIRRawValue");
}
implementation
{
  uint16_t m_data;

  event void PirSampleTimer.updated( uint16_t period )
  {
    if( period == 0 ) {
      call Timer.stop();
      call PIR.PIROff();
    } else {
      call PIR.PIROn();
      call Timer.start( TIMER_REPEAT, period );
    }
  }

  event result_t Timer.fired()
  {
    call ADC.getData();
    return SUCCESS;
  }

  task void adc_data()
  {
    atomic call PIRRawValue.set( m_data );
  }

  async event result_t ADC.dataReady( uint16_t data )
  {
    m_data = data;
    post adc_data();
    return SUCCESS;
  }

  event void PIRRawValue.updated( uint16_t thresh ) { }

  // PIR interface
  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }
  event void PIR.readDetectDone(uint8_t val) { }
  event void PIR.readQuadDone(uint8_t val) { }
  event void PIR.firedPIR() { }

}

