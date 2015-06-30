SysClock Beta Project

This directory houses the new SysClock components.

GOALS:

1. Define the HPLSysClock abstraction layer and implement 
it in the current platforms. The assumption is that
each platform provides a free running 16-bit or 32-bit 
counter and one compare register. The time resolution 
is platform dependent and should be between 0.1 and 
10 MHz.

2. On top of the HPLSysClock abstraction layer build a
platform independent SysClock module that provides one
32-bit SysTime interface to query the current time,
and a few 32-bit SysAlarm interface to schedule events
with SysTime precision.

3. Develop simple test applications to verify that
HPLSysClock and SysClock works on each platform.

4. Transform existing application and other components,
such as HighFrequencySampling and SysTimeStamping 
to the new interfaces.

PROJECT MEMBERS:

	VU (Miklos Maroti)
	UCB (Joe Polastre, Philip Levis, Cory Sharp)

TIMING:

	All components should be written and fully tested 
	by mid March, 2004. The components will be folded back
	to the core tree and released in tinyos-1.1.6.
