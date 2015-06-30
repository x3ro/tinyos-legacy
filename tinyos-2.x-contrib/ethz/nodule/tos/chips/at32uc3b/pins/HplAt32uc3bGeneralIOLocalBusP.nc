/* $Id: HplAt32uc3bGeneralIOLocalBusP.nc,v 1.6 2008/03/09 16:36:17 yuecelm Exp $ */

/**
 * HPL for the Atmel AT32UC3B microcontroller. This provides an
 * implementation for general-purpose I/O.
 *
 * Mapping registers on the local bus allows cycle-deterministic
 * toggling of GPIO  pins since the CPU and GPIO are the only
 * modules connected to this bus. Also, since the local bus runs
 * at CPU speed, one write or read operation can be performed
 * per clock cycle to the local busmapped GPIO registers.
 *
 * @author Mustafa Yuecel <mustafa.yuecel@alumni.ethz.ch>
 */

#include "at32uc3b_gpio.h"

generic module HplAt32uc3bGeneralIOLocalBusP(uint32_t GPIO)
{
  provides interface GeneralIO as IO;
}
implementation
{
  inline void setBit(uint8_t offset) {
    get_register(get_avr32_gpio_baseport_local(GPIO) + offset) = (uint32_t) 1 << get_avr32_gpio_bit(GPIO);
  }

  inline bool getBit(uint8_t offset) {
    return (get_register(get_avr32_gpio_baseport_local(GPIO) + offset) & ((uint32_t) 1 << get_avr32_gpio_bit(GPIO)));
  }

  async command void IO.set() { setBit(AVR32_GPIO_OVRS0); }
  async command void IO.clr() { setBit(AVR32_GPIO_OVRC0); }
  async command void IO.toggle() { setBit(AVR32_GPIO_OVRT0); }
  async command bool IO.get() { return getBit(AVR32_GPIO_PVR0); }
  async command void IO.makeInput() { setBit(AVR32_GPIO_ODERC0); }
  async command bool IO.isInput() { return !getBit(AVR32_GPIO_ODER0); }
  async command void IO.makeOutput() { setBit(AVR32_GPIO_ODERS0); }
  async command bool IO.isOutput() { return getBit(AVR32_GPIO_ODER0); }
}
