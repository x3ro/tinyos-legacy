#ifndef __SPSIMDBG_H
#define __SPSIMDBG_H

#define DEBUG

#include "SPSimDbgCommon.h"

//#define assert(w) ((!(w)) ? (*((int*) 0) = 1) : 0)
#define assert(w) ((!(w)) ? assert2() : 0)
#define fail(reason) assert(FALSE && reason)

static uint64_t lastTime = 0;

void assert2() {
	printf("");
}

// Converts symbol periods to seconds.
// 1 symbol period = 16 microsecond.
double symbolsToSeconds(double syms) {
	return (syms * 16.0) / 1000000.0;
}

// Converts seconds to TinyOS units of time (ticks).
// 1 second = 4,000,000 ticks.
uint64_t secondsToTicks(double seconds) {
	return (uint64_t) (seconds * 4000000.0);
}

// Converts symbol periods to TinyOS units of time (ticks).
uint64_t symbolsToTicks(double syms) {
	return secondsToTicks(symbolsToSeconds(syms));
}

// Converts jiffies to seconds.
double jiffiesToSeconds(double jiffies) {
	return jiffies * (1.0 / 32768.0);
}

// Converts jiffies to TinyOS units of time (ticks).
uint64_t jiffiesToTicks(double jiffies) {
	return secondsToTicks(jiffiesToSeconds(jiffies));
}

// Converts seconds to jiffies.
double secondsToJiffies(double seconds) {
	return seconds * 32768.0;
}

// Converts TinyOS units of time (ticks) to seconds.
double ticksToSeconds(uint64_t ticks) {
	return ((double) ticks) / 4000000.0;
}

// Converts TinyOS units of time (ticks) to jiffies.
double ticksToJiffies(uint64_t ticks) {
	return secondsToJiffies(ticksToSeconds(ticks));
}

// Returns the current time in jiffies.
uint32_t getCurrentTimeInJiffies() {
	double jiffies = ticksToJiffies(tos_state.tos_time -
			tos_state.node_state[NODE_NUM].time);
	uint32_t castedJiffies = (uint32_t) jiffies;
	assert( tos_state.tos_time >= tos_state.node_state[NODE_NUM].time
			&& "the current time is less than the bootup time" );
	assert( jiffies >= 0 && jiffies <= UINT32_MAX
			&& "double cannot safely be converted into uint32_t" );
	assert( floor(jiffies) == (double) castedJiffies
			&& "the number of jiffies has overflowed our 32-bit number" );
	return castedJiffies;
}

// Convenience function for outputting debug information.
void ppp(TOS_dbg_mode mode, const char *fmt, ...) {
	va_list argp;
	static char str[MAX_BUF];
	static char timeStr[TIME_BUF];

	va_start(argp, fmt);
	vsnprintf(str, MAX_BUF, fmt, argp);
	va_end(argp);

	printTime(timeStr, TIME_BUF);
	dbg(mode, "(%s): %s\n", timeStr, str);
}

//#define SLOW_SCROLL 250000
#define SLOW_SCROLL 0

// Convenience function for outputting debug information.
void pppp(DebugMode mode, const char * fmt, ...) {
	if (mode.isOn && dbg_active(mode.mode)) {
		va_list argp;
		static char str[MAX_BUF];
		static char timeStr[TIME_BUF];

		uint64_t currTime = tos_state.tos_time;
		if (lastTime != 0) {
			int lastPeriod = lastTime / MARKER_INTERVAL;
			int currPeriod = currTime / MARKER_INTERVAL;
			int i;
			for (i = lastPeriod; i < currPeriod; i++) {
				if (i % 10 == 9) {
					if (PRINT_MAJOR_TIME_MARKERS) {
						printf("=====\n");
					}
				} else {
					if (PRINT_TIME_MARKERS) {
						printf("-\n");
					}
				}
			}
		}
		lastTime = currTime;

		va_start(argp, fmt);
		vsnprintf(str, MAX_BUF, fmt, argp);
		va_end(argp);

		//printTime(timeStr, TIME_BUF);
		printf( "%s%hd (G%f, L%f) %s%s : %s%s\n",
				mode.mode == DBG_USR3 ? "" : NODE_COLORS[NODE_NUM % NODE_COLOR_COUNT],
				NODE_NUM, //timeStr,
				ticksToSeconds(tos_state.tos_time),
				ticksToSeconds(tos_state.tos_time - tos_state.node_state[NODE_NUM].time),
				mode.mode == DBG_USR3 ? "" : mode.color,
				mode.label, str,
				mode.mode == DBG_USR3 ? "" : DbgNormal);
	}

	if (SLOW_SCROLL) {
		usleep(SLOW_SCROLL);
	}
}

#define printd(mode,fmt,...) pppp(mode,fmt , ## __VA_ARGS__ )

#endif // __SPSIMDBG_H
