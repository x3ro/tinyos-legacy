#include <iostream>
#include <Joystick.h>

int main () {

  Joystick joystick;

  std::cout << joystick.init();

  while(1) {

    std::cout << "Update:";
    std::cout << joystick.update();

    std::cout << "  Axis0:";
    std::cout << joystick.getAxis(0);

    std::cout << "  Axis1:";
    std::cout << joystick.getAxis(1);

    std::cout << "  Button0:";
    std::cout << joystick.getButton(0);

    std::cout << "\n";
  }

  return 0;

}
