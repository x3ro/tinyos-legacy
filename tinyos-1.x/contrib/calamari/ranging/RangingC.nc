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
	     UC Berkeley
 * Date:     8/20/2002
 *
 */

//!! RangingHood = CreateNeighborhood( 25, MostRecentNeighbors, BroadcastBackend, 149 );

//!! RangingAttr = CreateAttribute( distance_t = {distance:0, stdv:65534u} );

//--!! RangingRefl = CreateReflection(RangingHood, RangingAttr, FALSE, 251, 252 );
//--!! RangingRefl = CreateReflection[VUTOFReflection](RangingHood, RangingAttr, FALSE, 251, 252 );
//--!! RangingRefl = CreateReflection[DebugTOFReflection](RangingHood, RangingAttr, FALSE, 251, 252 );
//--!! RangingRefl = CreateReflection[UltrasoundReflection](RangingHood, RangingAttr, FALSE, 251, 252 );
//!! RangingRefl = CreateReflection[RangingReflection](RangingHood, RangingAttr, FALSE, 251, 252 );
//--!! RangingRefl = CreateReflection[TinyVizRangingReflection:Distance_ADC_channel=131,Distance_stdv_ADC_channel=132]( RangingHood, RangingAttr, FALSE, 251, 252 );

//!! RangingCountAttr = CreateAttribute( uint8_t = 0 );
//!! RangingCountRefl = CreateReflection(RangingHood, RangingCountAttr, FALSE, 249, 250 );


// !! EWMARangingAttr = CreateAttribute( ewma_t = {mean:0, alpha:0.95, initialized:FALSE} );
// !! EWMARangingRefl = CreateReflection(RangingHood, EWMARangingAttr, FALSE, 253, 254 );

//!! RangingMovingWindowAttr = CreateAttribute( moving_window_t ={begin:0, end:0, current:0, n:0, size:0} );
//!! RangingMovingWindowRefl = CreateReflection(RangingHood, RangingMovingWindowAttr, FALSE, 247, 248 );

//!! RangingWindowBufferAttr = CreateAttribute( rangingBuffer_t = {} );
//!! RangingWindowBufferRefl = CreateReflection(RangingHood, RangingWindowBufferAttr, FALSE, 245, 246 );


configuration RangingC
{
	provides interface StdControl;
}
implementation
{
	components RangingHoodC, RangingAttrC;

	StdControl = RangingHoodC;
	StdControl = RangingAttrC;
}





