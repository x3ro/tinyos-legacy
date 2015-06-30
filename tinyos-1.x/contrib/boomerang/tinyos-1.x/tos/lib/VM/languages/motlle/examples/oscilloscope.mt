// A motlle version of the standard TinyOS OscilloscopeRF application: 
// collect 10 sensor (light) readings and broadcast them over the radio.

// The mote on your base station should have id 0, all other nodes should
// have different, non-zero ids.

// You can use the java net.tinyos.oscope.oscilloscope application to
// display these readings if you apply the patch at the end of this file.

// NOTE: you will want to change the call to light() below to a sensor
// included in your VM.

////// CODE STARTS HERE //////

// The current set of readings. Change samples to collect more or less
// readings at a time
any samples = 10, current = 0, readings = make_vector(samples);

// Start timer0 at 5Hz except on node 0.
settimer0(if (id()) 2 else 0);
any timer0()
{
  // get a reading, and send a message over the radio if the buffer is full
  readings[current++ % samples] = light();
  if (current % samples == 0)
    send_data(readings);
}

any send_data(data)
{
  led(l_blink | l_yellow);
  // encode builds a message (string) from a vector
  // by default, each integer becomes 2 bytes
  send(bcast_addr, encode(vector(id(), current, 0, encode(readings))));
}

// Define receive handler, which forwards received messages to
// the serial port, only on node 0
any receive;
if (!id())
  receive = fn() send(uart_addr, received_msg());



/* Patch for net.tinyos.oscope.oscilloscope:
   save the patch below to a file (e.g., /tmp/GP-patch), then change to the 
   tinyos-1.x/tools/java/net/tinyos/oscope directory, and apply the
   patch with:
     patch </tmp/GP-patch

START OF PATCH
--- GraphPanel.java	17 Mar 2004 19:25:28 -0000	1.8
+++ GraphPanel.java	19 Nov 2004 18:08:21 -0000
@@ -149,6 +149,9 @@
 	// OK, connect to the serial forwarder and start receiving data
 	mote = new MoteIF(PrintStreamMessenger.err, oscilloscope.group_id);
 	mote.registerListener(new OscopeMsg(), this);
+	OscopeMsg otherId = new OscopeMsg();
+	otherId.amTypeSet(42);
+	mote.registerListener(otherId, this);
     }
     int big_filter;
     int sm_filter;
END OF PATCH
*/
