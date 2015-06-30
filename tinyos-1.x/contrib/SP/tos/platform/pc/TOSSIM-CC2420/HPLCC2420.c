#include "HPLCC2420.h"

void* alloc(size_t size) {
	// XXX BUG:
	// ==11928==  Address 0x1BC84094 is 0 bytes after a block of size 28 alloc'd
	// ==11928==    at 0x1B903D1C: malloc (vg_replace_malloc.c:131)
	// ==11928==    by 0x804E413: HPLCC2420M$alloc (HPLCC2420M.nc:361)
	// ==11928==    by 0x8050473: HPLCC2420M$createFrame (HPLCC2420M.nc:2205)
	// ==11928==    by 0x80604D6: HPLCC2420M$handlePreambleSentEvent (HPLCC2420M.nc:1950)
	void* pointer = malloc(size);
	assert(pointer != NULL);
	return pointer;
}

//// Converts symbol periods to seconds.
//// 1 symbol period = 16 microsecond.
//double symbolsToSeconds(double syms) {
//	return (syms * 16.0) / 1000000.0;
//}
//
//// Converts seconds to TinyOS units of time (ticks).
//// 1 second = 4,000,000 ticks.
//uint64_t secondsToTicks(double seconds) {
//	return (uint64_t) (seconds * 4000000.0);
//}
//
//// Converts symbol periods to TinyOS units of time (ticks).
//uint64_t symbolsToTicks(double syms) {
//	return secondsToTicks(symbolsToSeconds(syms));
//}
//
//// Converts jiffies to seconds.
//double jiffiesToSeconds(double jiffies) {
//	return jiffies * (1.0 / 32768.0);
//}
//
//// Converts jiffies to TinyOS units of time (ticks).
//uint64_t jiffiesToTicks(double jiffies) {
//	return secondsToTicks(jiffiesToSeconds(jiffies));
//}
//
//// Converts seconds to jiffies.
//double secondsToJiffies(double seconds) {
//	return seconds * 32768.0;
//}
//
//// Converts TinyOS units of time (ticks) to seconds.
//double ticksToSeconds(uint64_t ticks) {
//	return ((double) ticks) / 4000000.0;
//}
//
//// Converts TinyOS units of time (ticks) to jiffies.
//double ticksToJiffies(uint64_t ticks) {
//	return secondsToJiffies(ticksToSeconds(ticks));
//}
//
//// Returns the current time in jiffies.
//uint32_t getCurrentTimeInJiffies() {
//	double jiffies = ticksToJiffies(tos_state.tos_time -
//			tos_state.node_state[NODE_NUM].time);
//	uint32_t castedJiffies = (uint32_t) jiffies;
//	assert( tos_state.tos_time >= tos_state.node_state[NODE_NUM].time
//			&& "the current time is less than the bootup time" );
//	assert( jiffies >= 0 && jiffies <= UINT32_MAX
//			&& "double cannot safely be converted into uint32_t" );
//	assert( floor(jiffies) == (double) castedJiffies
//			&& "the number of jiffies has overflowed our 32-bit number" );
//	return castedJiffies;
//}
