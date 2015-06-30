This directory contains a variety of source files designed to test the
operation of the Radio.  You must specify the particular test you wish
to compile by putting a "CODE=Name" on your make command line.  For
example:

  make CODE=Noise IP=16.11.5.50 LONG_ADDRESS=50 HOST_IP=16.11.5.51 telos

Most of these tests are configured to provide wired TCP/IP Telnet support
over the USB port of the Telos mote.  To telnet to the target, you
must run the AccessPoint daemon software first.

For example (using the above "Noise" case):

  insmod apps/AccessPoint/kernel/telos_ap.ko
  sudo apps/AccessPoint/daemon/zattach -n -v /dev/ttyUSB0
  telnet 16.11.5.50


----------------
Test Application
----------------

RadioNoise

   Generates an endless stream of 802.15.4 DATA_REQUEST packets as
   fast as possible.  The packets are sent to the Pan Coordinator.


RadioSend

   Sends approximately two 802.15.4 DATA_REQUEST packets per second to
   the Pan coordinator.  Between packets the radio is completely
   powered down.


RadioTest

   Acts as Pan coordinator and accepts packets.  Generates ACK
   responses as required.


RadioUART

   Acts as Pan coordinator and accepts packets.  Generates ACK
   responses as required. 

   Does NOT open a wired TCP/IP connection on the UART.  Instead, each
   packet received on the UART is sent back out the UART (rather like
   a ping response).  Run the "test_uart.py" script against this
   program to see if we are getting any packet corruption (which was a
   major problem until we re-enabled interrupts in the FIFO handler).


==========================================
Andrew Chrisitan <andrew.christian@hp.com>
June 2005