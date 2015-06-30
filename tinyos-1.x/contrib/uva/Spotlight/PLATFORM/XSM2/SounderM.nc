/*
 *
 * Authors:  Mike Grimmer
 * Revision:		$Rev$
 *
 */

includes sensorboard;
module SounderM 
{
  provides interface Sounder;
}
implementation 
{
  uint16_t soundtime;

  command result_t Sounder.twoTone(uint16_t first, uint16_t second, uint16_t interval)
  {
    uint16_t i;

/*
	TOSH_CLR_YELLOW_LED_PIN();
    TOSH_uwait(1000);
	TOSH_uwait(1000);
    TOSH_uwait(1000);
	TOSH_SET_YELLOW_LED_PIN();
*/


    TOSH_CLR_PW2_PIN();  // xscale enable
	TOSH_uwait(1000);
	TOSH_CLR_PWM1B_PIN();
    TOSH_MAKE_PWM1B_OUTPUT();  // enable the timer output
    outp(first>>8, OCR1AH);
	outp(first&0x00ff, OCR1AL);
    outp(0x09, TCCR1B); // enable counter 1
    for (i=0;i<interval;i++)
      TOSH_uwait(1);
    outp(second>>8, OCR1AH);
	outp(second&0x00ff, OCR1AL);
    for (i=0;i<interval;i++)
      TOSH_uwait(1);
    outp(0x08, TCCR1B); // disable counter 1
	TOSH_CLR_PWM1B_PIN();
	TOSH_uwait(1000);

    TOSH_SET_PW2_PIN();  // xscale disable
	TOSH_CLR_PWM1B_PIN();
	return SUCCESS;
  }


  command result_t Sounder.setInterval(uint16_t val)
  {
    outp(0x10, TCCR1A); // toggle on compare match 1b
    outp(0x08, TCCR1B); // disable counter 1
    outp(0x00, TCCR1C); 
    outp(0x00, TCNT1H);  // initialize counter
    outp(0x00, TCNT1L);  // initialize counter
    outp(val>>8, OCR1AH);
	outp(val&0x00ff, OCR1AL);

    return SUCCESS;
  }

  command result_t Sounder.Beep(uint16_t interval)
  {
    uint16_t i;


    TOSH_CLR_PW2_PIN();  // xscale enable
	TOSH_uwait(100);
    TOSH_MAKE_PWM1B_OUTPUT();  // enable the timer output
    outp(0x09, TCCR1B); // enable counter 1

    for (i=0;i<interval;i++)
      TOSH_uwait(1);
    outp(0x08, TCCR1B); // disable counter 1
    TOSH_SET_PW2_PIN();  // xscale disable

	return SUCCESS;
  }

  command result_t Sounder.Off()
  {
    TOSH_SET_PW2_PIN();

    return SUCCESS;
  }

}

