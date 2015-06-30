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
 * Centroid finding/Object tracking - find centroid of sensor readings 
 * above a given threshold.
 */
configuration Centroid {
}
implementation {
  components Main, CentroidM, TimerC, FakeADC, Photo,
    RadioNeighborhood, FakeLocation, SharedMemOneHop, 
    Collective;

  Main.StdControl -> CentroidM.StdControl;
  Main.StdControl -> RadioNeighborhood;
  Main.StdControl -> FakeLocation;
  Main.StdControl -> SharedMemOneHop;
  Main.StdControl -> Photo;

  //CentroidM.ADC -> FakeADC;
  CentroidM.ADC -> Photo;
  CentroidM.SM -> SharedMemOneHop;
  CentroidM.Neighborhood -> RadioNeighborhood;
  CentroidM.Location -> FakeLocation;
  CentroidM.Timer -> TimerC.Timer[unique("Timer")];
  CentroidM.Reduce -> Collective;
  CentroidM.Barrier -> Collective;

}

