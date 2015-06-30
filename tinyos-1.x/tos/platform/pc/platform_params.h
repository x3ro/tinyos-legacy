/* Author: Victor Shnayder
 *
 * TOSSIM has hardwired CPU frequency (4Mhz, which is correct on the
 * mica, but not mica2)
 *
 * Need to fix it...
 */

#ifndef PLATFORM_PARAMS_H
#define PLATFORM_PARAMS_H

/* Uncomment the following to simulate the original mica */
#define CPU_FREQ 4000000

/* Uncomment the following to simulate the mica2 */
// FIXME!!!!!!!  Not all of tossim is changed to respect CPU_FREQ yet,
// so can't use this yet (in particular, hpl.c, EEPROM timings, some stuff in
// Nido.nc)
// #define CPU_FREQ 7370000

#endif
