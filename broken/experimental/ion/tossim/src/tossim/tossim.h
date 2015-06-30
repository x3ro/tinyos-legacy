/**
 *  @file tossim.hh
 *
 *  The bridge between the parts of TOSSIM written in C++ and the
 *  parts written in NesC.  The declarations here are #included
 *  by tossim.cc and included in Simulator.nc.
 *
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_TOSSIM_H
#define TOS_SIM_TOSSIM_H

#if defined(__cplusplus)
extern "C" {
#endif // __cplusplus

// tos.h needs to be protected by any extern "C" section.
#include <tos.h>

// These functions are implemented in C++ in tossim.cc
void TosSim_Main(int argc, char ** argv);

// These functions are implemented in NesC in Simulator.nc
void TosSim_Mote_start(tossim_mote_t mote_id);
void TosSim_Mote_stop(tossim_mote_t mote_id);

// Move to tossim/radio.h
TOS_MsgPtr       TosSim_Radio_received(TOS_MsgPtr packet);
void             TosSim_Radio_transmit_done(TOS_MsgPtr packet);

// Move to tossim/uart.h
TOS_MsgPtr       TosSim_UArt_received(TOS_MsgPtr packet);


#if defined(__cplusplus)
} // extern "C"
#endif // __cplusplus


#endif // TOS_SIM_TOSSIM_H
