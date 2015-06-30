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

//!! ShortestPathAttr = CreateAttribute( distance_t = {distance:0, stdv:65535} ); 
//!! ShortestPathRefl = CreateReflection( AnchorHood, ShortestPathAttr, FALSE, 213, 214 );

includes common_structs;
includes polynomial;
includes moving_average;
includes Localization;
includes Rssi;


module RssiShortestPathM
{
	provides
	{
		interface StdControl;
		interface RssiShortestPath;
		interface Rssi;
	}
	uses
	{
		interface RssiRxrCoeffsAttr;
		interface RssiAttrReflection as RssiRefl;
		interface RssiTxrCoeffsAttrReflection as RssiTxrCoeffsRefl;
		interface DistanceAttrReflection as DistanceRefl;
		interface ShortestPathAttrReflection as ShortestPathRefl;

		interface StdControl as ShortestPathAttrControl;
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
	    call ShortestPathAttrControl.init();
	    call RssiTxrCoeffsAttrControl.init();
	    call RssiRxrCoeffsAttrControl.init();
	    call DistanceAttrControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	    call ShortestPathAttrControl.start();
	    call RssiTxrCoeffsAttrControl.start();
	    call RssiRxrCoeffsAttrControl.start();
	    call DistanceAttrControl.start();
		return SUCCESS;
	}

	command result_t StdControl.stop()
        {
	    call ShortestPathAttrControl.stop();
	    call RssiTxrCoeffsAttrControl.stop();
	    call RssiRxrCoeffsAttrControl.stop();
	    call DistanceAttrControl.stop();
		return SUCCESS;
	}

	void convertRssiToDistance(uint16_t rssi, polynomial_t* txrCoeffs, distance_t *distance){
		polynomialD2_t rxrCoefficients = call RssiRxrCoeffsAttr.get();
		distance->distance = (uint16_t)polynomialEval((float)rssi, (polynomial_t*)txrCoeffs);
		distance->distance += (uint16_t)polynomialEval((float)rssi, (polynomial_t*)&rxrCoefficients);
//		distance->stdv=distance->distance>900 ? 65535 : 300;//??fix this

#ifdef MAKEPC

		distance->stdv=generic_adc_read(TOS_LOCAL_ADDRESS,132,0);                            //uncomment for simulation

dbg(DBG_USR3, "phoebus: degree = %d, coefficient1 = %d, coefficient2 = %d \n", rxrCoefficients.degree, rxrCoefficients.coefficients[0], rxrCoefficients.coefficients[1]); //@@
dbg(DBG_USR3, "phoebus: distance: distance = %d, standardD = %d \n", distance->distance, distance->stdv); //@@
dbg(DBG_USR3, "phoebusRssi: rssi for %d - %d\n", TOS_LOCAL_ADDRESS, rssi);

#else
		distance->stdv= 30;

#endif
	}

	command void Rssi.estimateDistance(uint16_t rssi, ewma_t *movingAvg, polynomial_t *txrCoeffs, distance_t *distance){
		addToEWMA((float)rssi, movingAvg);
		convertRssiToDistance(movingAvg->mean, txrCoeffs, distance);
	}

    command void RssiShortestPath.estimateDistance(uint16_t rssi, ewma_t *movingAvg, polynomial_t *txrCoeffs, distance_t *distance, distance_t *shortestPath){
		call Rssi.estimateDistance(rssi,movingAvg,txrCoeffs,distance);
		distance->distance+=shortestPath->distance;
		distance->stdv+=shortestPath->stdv;
	}

    event void RssiRefl.updated( nodeID_t id, ewma_t value ){
		distance_t distanceEstimate;
		polynomialD1_t txrCoefficients = call RssiTxrCoeffsRefl.get(id);
		distance_t distance = call DistanceRefl.get(id);
		distance_t shortestPath = call ShortestPathRefl.get(id);
		call RssiShortestPath.estimateDistance(value.mean, &value, (polynomial_t*)&txrCoefficients, &distance, &shortestPath);
		call DistanceRefl.scribble(id, distance);
	}


    event void RssiRxrCoeffsAttr.updated(){}

    event void ShortestPathRefl.updated( nodeID_t id, distance_t value ){}

    event void DistanceRefl.updated( nodeID_t id, distance_t value ){}

    event void RssiTxrCoeffsRefl.updated( nodeID_t id, polynomialD1_t value ){}

}





