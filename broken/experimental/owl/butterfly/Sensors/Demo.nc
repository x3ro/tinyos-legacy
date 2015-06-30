module Demo {
  provides interface StdControl;
  uses {
    interface LCD;
    interface Timer;
    interface Joystick;
    interface ADC as Photo;
    interface ADC as Temp;
  }
}
implementation {
  enum {
    TEMP1, TEMP2,
    PHOTO1, PHOTO2,
    OWLS
  };

  uint8_t sensor = TEMP1;
  uint16_t data;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void display();

  event result_t Timer.fired() {
    switch (sensor)
      {
      case TEMP1: case TEMP2: call Temp.getData(); break;
      case PHOTO1: case PHOTO2: call Photo.getData(); break;
      }
    return SUCCESS;
  }

  event result_t Joystick.fire() {
    sensor = OWLS;
    post display();
    return SUCCESS;
  }

  event result_t Joystick.move(uint8_t direction) {
    switch (direction)
      {
      case 0: sensor = TEMP1; break;
      case 2: sensor = TEMP2; break;
      case 1: sensor = PHOTO1; break;
      case 3: sensor = PHOTO2; break;
      }
    return SUCCESS;
  }

  float temperature(uint16_t sample) {
    return 4250 / (log(sample / (float )(1024 - sample)) + 4250.0 / 298) - 273;
  }

  float fahrenheit(float celsius) {
    return celsius * 1.8 + 32;
  }

  float fakelux(uint16_t sample) {
    // This is an attempt to divine lux from a skimpy datasheet
    // Seems to produce vaguely plausible results
    // (As far as I can tell, the CdS sensors have wide sample and
    // temperature variations anyway, so precise results probably don't
    // matter much)
    return pow(125000.0 * (float)(1024 - sample) / (3300.0 * sample), 1/0.7);
  }

  task void display() {
    uint16_t d;
    static char msg[20];
    float val;

    atomic d = data;

    switch (sensor)
      {
      case TEMP1: 
	val = temperature(d);
	if (val >= 1000) // hell?
	  val = 999;
	if (val <= -1000) // some other universe
	  val = -999;
	sprintf(msg, "%dC%d", (int)val, (int)((val - (int)val) * 10));
	break;
      case TEMP2:
	val = fahrenheit(temperature(d));
	if (val >= 1000) // hell?
	  val = 999;
	if (val <= -1000) // some other universe
	  val = -999;
	sprintf(msg, "%dF", (int)(val + 0.5));
	break;
      case PHOTO1: 
	sprintf(msg, "P %d", (int)d);
	break;
      case PHOTO2:
	val = fakelux(d);
	if (val >= 1e6)
	  val = 999999;
	sprintf(msg, "%dLX", (int)val);
	break;
      default:
	strcpy(msg, "owls");
      }
    call LCD.display(msg);
  }

  async event result_t Temp.dataReady(uint16_t d) {
    atomic data = d;
    post display();
    return SUCCESS;
  }

  async event result_t Photo.dataReady(uint16_t d) {
    atomic data = d;
    post display();
    return SUCCESS;
  }
}
