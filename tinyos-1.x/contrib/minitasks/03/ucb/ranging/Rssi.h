/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Kamin Whitehouse
// $Id: Rssi.h,v 1.5 2003/06/19 06:16:33 kaminw Exp $


#ifndef _H_Rssi_h
#define _H_Rssi_h


//!! RssiTxrCoeffsAttr = CreateAttribute[TinyVizPolynomialAttribute: Coeff_0_ADC_channel=116, Coeff_1_ADC_channel=117]( polynomialD1_t = { degree:1, coefficients:{0.0} } );
// !! RssiTxrCoeffsAttr = CreateAttribute( polynomialD1_t = { degree:1, coefficients:{0.0} } );

//!! RssiTxrCoeffsRefl = CreateReflection( AnchorHood, RssiTxrCoeffsAttr, FALSE , 207, 208);

//!! RssiRxrCoeffsAttr = CreateAttribute[TinyVizPolynomialAttribute: Coeff_0_ADC_channel=118, Coeff_1_ADC_channel=119]( polynomialD2_t = { degree:2, coefficients:{0.0, 1.0} } );
//  !! RssiRxrCoeffsAttr = CreateAttribute( polynomialD2_t = { degree:2, coefficients:{0.0, 1.0} } );

//!! RssiAttr = CreateAttribute( ewma_t = {mean: 0, alpha: 0.95, initialized:FALSE} );

// !! RssiRefl = CreateReflection( AnchorHood, RssiAttr, FALSE, 209, 210 );
//!! RssiRefl = CreateReflection[RssiReflection:TxrCalibCoeffsAttr=RssiTxrCoeffsAttr,TxrCalibCoeffsType=polynomialD1_t,TxrCalibCoeffsRefl=RssiTxrCoeffsRefl,DistanceAttr=DistanceAttr,DistanceType=distance_t,DistanceRefl=DistanceRefl,RssiRanging=RssiEstimateDistance,Rssi_ADC_channel=131]( AnchorHood, RssiAttr, FALSE, 209, 210 );

#endif

