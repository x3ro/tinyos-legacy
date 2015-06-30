#include <jsw.h>

class Joystick {

  js_data_struct jsd;
  int initDone;

 public:
  Joystick();
  int init();
  double getAxis(int axisNum);
  int getButton(int buttonNum);
  int update();

};
