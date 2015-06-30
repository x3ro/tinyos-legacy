/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: Wmewma.nc,v 1.4 2003/03/21 06:53:58 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Alec Woo, Terence Tong
 */
/*////////////////////////////////////////////////////////*/
includes RoutingStackShared;

configuration Wmewma {
  provides {
    interface Estimator;
  }

}
implementation {
  components SimpleWmewmaM as EstimatorM, LedsC, VirtualComm;
  Estimator = EstimatorM;
  EstimatorM.VCSend -> VirtualComm.VCSend[RS_ESTIMATOR_DEBUG];
  EstimatorM.Leds -> LedsC.Leds;
}
