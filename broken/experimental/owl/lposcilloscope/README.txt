Low-power version of oscilloscope for mica2s.

For lowest power, set the low fuse byte to c4 (using uisp or
your favourite tool), which makes the mote use an internal
8MHz oscillator. Remember to set the low fuse byte back to ff
for regular use.
