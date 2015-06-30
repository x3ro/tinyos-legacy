/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 * 	     UC Berkeley
 * Date:     8/20/2002
 *
 */

includes common_structs;
includes polynomial;
includes moving_average;
includes Localization;
includes Rssi;


module RssiEstimateDistanceM
{
	provides
	{
		interface StdControl;
		interface Rssi;
	}
	uses
	{
		interface RssiRxrCoeffsAttr;
//		interface RssiTxrCoeffsAttrRefl as  RssiTxrCoeffsRefl;
//		interface RssiAttrRefl as  RssiRefl;
//		interface DistanceAttrRefl as  DistanceRefl;

		interface StdControl as RssiTxrCoeffsAttrControl;
		interface StdControl as RssiRxrCoeffsAttrControl;
		interface StdControl as DistanceAttrControl;

		interface Leds;
	}
}

implementation
{

	command result_t StdControl.init()
	{
	    call RssiTxrCoeffsAttrControl.init();
	    call RssiRxrCoeffsAttrControl.init();
	    call DistanceAttrControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	    call RssiTxrCoeffsAttrControl.start();
	    call RssiRxrCoeffsAttrControl.start();
	    call DistanceAttrControl.start();
		return SUCCESS;
	}

	command result_t StdControl.stop()
        {
	    call RssiTxrCoeffsAttrControl.stop();
	    call RssiRxrCoeffsAttrControl.stop();
	    call DistanceAttrControl.stop();
		return SUCCESS;
	}

    event void RssiRxrCoeffsAttr.updated(){}

    command distance_t Rssi.estimateDistance(ewma_t movingAvg, polynomial_t *calibrationCoeffs){
		distance_t distanceEstimate;
		polynomialD2_t rxrCoefficients = call RssiRxrCoeffsAttr.get();
		distanceEstimate.distance = (uint16_t)polynomialEval((float)(movingAvg.mean), calibrationCoeffs);
		distanceEstimate.distance += (uint16_t)polynomialEval((float)(movingAvg.mean), (polynomial_t*)&rxrCoefficients);
		distanceEstimate.stdv = 600;//??fix this
		return distanceEstimate;
	}

}





