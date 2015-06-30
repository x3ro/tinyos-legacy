bcast -- Sample command broadcast program used in the tutorial.

bless_test -- This application is a simple test of the BLESS 
protocol for non-base-station motes. It demonstrates how one would use
the protocol.

bless_base -- A simple BLESS base station that transmits a zero-hop
data message to itself every 5 seconds, allowing other BLESS motes to
associate.

bless_uart -- A BLESS base station that forwards RF packets sent
to it over the UART. Transmits a zero-hop data message to itself every 5
seconds, allowing other BLESS motes to associate.

blink --  Example application that handles clock events to update
the LEDs like a counter

chirp -- example appliation that sends out periodic radio messages
containg sensor readings.

cnt_to_leds -- a demonstration application that is indended to
show how to use description files to modify application behavior.
It has the same behavior as blink.

cnt_to_leds_prog -- Same as above, except the mote is also
network reprogrammable. Very useful for testing if network
reprogramming works; you can easily see the results and get ready for
your real program.

cnt_to_rfm -- Using the same application level code as cnt_to_leds,
this application send the counter value to the RFM.

cnt_to_leds_and_rfm -- Pretty obvious given the previous
two. An easy way to see if RFM communication is working well.

dotid -- Running this program causes the mote's local ID
(TOS_LOCAL_ADDRESS) to be written to the EEPROM where it can later be
fetched. This provides a persistent mote name independent of the code
image loaded. This is very useful when using network multiprogramming.

experiment_test -- Demonstration of a variety of components useful
when performing networking experiments with motes.

generic_base -- This generic base station listens to packet and
forwards ANYTHING that is recieved to the UART without modification.
Additionally, it forwards messages received on the UART to the radio.

generic_base_high_speed -- Just like generic_base except that it is
designed for the Mica platform and will only run the Mica platform
and Mica high speed radio stack.

mica_hardware_verify -- a diagnostic program for Mica nodes and should
only be run on the Mica platform.  A java application interfaces with
the serial port to query the mote and test its functionality.

netprog -- Description file demonstrating what's necessary for network
reprogramming..

oscilliscope -- Takes a series of sensor readings then sends them out
in a packet. Useful for demonstrating the wave form of sensor readings
a mote has, as the values can be mapped to a simple GUI.

oscilliscope_RF -- just like oscilliscope except the readings are taken
by a remote mote and transferred back to the base station via the RF radio.

rfm_to_leds -- Take the first short of data in RFM packets and display
its lowest 3 bits on the LEDs in a manner similar to cnt_to_leds.

router -- A basic multihop routing application.  Router allows any
application to include multihop functionality in their application.
Included are router--the basic client, router_base--the base station
which initiates the beacon-based routing, and router_test--an application
that periodically sends data packets back to the base station.

sens_to_leds -- a demonstration applicaton that send sensor reading
to the LEDS.

sens_to_rfm -- Using the same application level code as
sens_to_leds, this application send the sensor value to the RFM.

sense_and_log -- A sensor application that takes readings from the 
sensor and then stores the results in the log.  When queried, the mote
broadcasts all data logged since the last query.

sense -- Part of the TinyOS tutorial.

sense2 -- Part of the TinyOS tutorial.

test_logger -- A simple test of the logging facility.  It will
periodically take samples from the ADC, time stamp them, and write them
to the log.  It handles an active message which will cause it to go and
retreive data from the log and send it out onto the UART.

wave - Utilizes TOS tasks within an asynchronous interface to a photo
sensor.
