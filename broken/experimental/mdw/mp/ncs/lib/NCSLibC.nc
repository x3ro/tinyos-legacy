/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/** 
 * NCSLib is a set of "blocking" wrappers to various useful library 
 * routines.
 */

configuration NCSLibC {
  provides interface NCSLib;
  provides interface NCSLocation;
  provides interface NCSNeighborhood as NCSRadioNeighborhood;
  provides interface NCSNeighborhood as NCSYaoNeighborhood;
  provides interface NCSNeighborhood as NCSGeoNeighborhood;
  provides interface NCSSensor[uint8_t type];
  provides interface NCSSharedVar[uint8_t key];

} implementation {
  components Main, NCSLibM, FiberM, TimerC, LedsC, Photo,
    RadioNeighborhood, YaoNeighborhood, GeoNeighborhood,
    FakeLocation, SharedVarOneHop;

  NCSLib = NCSLibM;
  NCSLocation = NCSLibM;
  NCSRadioNeighborhood = NCSLibM.NCSRadioNeighborhood;
  NCSYaoNeighborhood = NCSLibM.NCSYaoNeighborhood;
  NCSGeoNeighborhood = NCSLibM.NCSGeoNeighborhood;
  NCSSensor = NCSLibM;
  NCSSharedVar = NCSLibM;

  Main.StdControl -> NCSLibM;
  Main.StdControl -> TimerC;
  Main.StdControl -> Photo;

  NCSLibM.Timer -> TimerC.Timer;
  NCSLibM.Fiber -> FiberM;
  NCSLibM.Leds -> LedsC;
  NCSLibM.PhotoADC -> Photo;
  NCSLibM.RadioNeighborhood -> RadioNeighborhood;
  NCSLibM.YaoNeighborhood -> YaoNeighborhood;
  NCSLibM.GeoNeighborhood -> GeoNeighborhood;
  NCSLibM.Location -> FakeLocation;
  NCSLibM.SharedVar -> SharedVarOneHop;
}
