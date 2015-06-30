New I2C interfaces and implementations.

Rationale:
- the old interfaces did not support using the hardware I2C on the
ATmega128
- the old interfaces did not provide enough error reporting
- there are new implementations of I2C using the hardware support provided
on various Atmel platforms
- there is an interface and implementation of I2C slave behaviour for
platforms with I2C hardware support

Details:
- the I2C interface commands and events are now async to support hardware
I2C implementations
- the I2CSlave interface is new, for implementing I2C slave behaviour
- the I2CPacketSlave interface is new, for receiving I2C r/w requests
  as a slave
- The slave interfaces are supported on the mica2 only

This code will require minor changes to components using I2C. These changes
will be made (and tested...) before this gets incorporated into the core 
of TinyOS.

Contact: David Gay, dgay@intel-research.net
