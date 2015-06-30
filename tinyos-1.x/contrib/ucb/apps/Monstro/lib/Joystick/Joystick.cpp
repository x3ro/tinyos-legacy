#include <jsw.h>
#include <Joystick.h>


Joystick::Joystick() {
  initDone = 0;
}


int Joystick::init( void ) { 

  const char *device = JSDefaultDevice;
  const char *calib = JSDefaultCalibration;

  int status = JSInit( &jsd , device , calib , JSFlagNonBlocking );

  if(status != JSSuccess) {
    JSClose(&jsd);
    initDone = 0;
    return 0;
  } else {
    initDone = 1;
    return 1;
  }
}


int Joystick::update( void ) {
  if(JSUpdate(&jsd) == JSGotEvent)
    return 1;
  else
    return 0;
}


double Joystick::getAxis(int axisNum) {
  if( axisNum < jsd.total_axises )
    return JSGetAxisCoeffNZ( &jsd , axisNum );
  else
    return 0.0;
}

int Joystick::getButton(int buttonNum) {
  if( buttonNum < jsd.total_buttons )
    return JSGetButtonState( &jsd , buttonNum );
  else
    return 0;
}

