/* Copyright (c) 2007 ETH Zurich.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the copyright holders nor the names of
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*
*  For additional information see http://www.btnode.ethz.ch/
*
*  $Id: DSNC.nc,v 1.5 2007/08/28 13:06:19 rlim Exp $
* 
*/

/**
 * Configuration of the DSN Component for TinyOS.
 *
 * This component gives the facility to easily log messages to the Deployment Support Network
 * and receive commands.
 *
 * @author Roman Lim <rlim@ee.ethz.ch>
 * @modified 10/3/2006 Added documentation.
 *
 **/

#include <AM.h>
#include <msp430usart.h>
#include "DSN.h"

configuration DSNC
{
	provides interface DSN;	
	provides interface DsnSend;
	provides interface DsnReceive;
}
implementation
{
#ifdef NODSN
	components noDSNC;
	
	DSN = noDSNC;
	DsnSend = noDSNC;
	DsnReceive = noDSNC;
#else
	components DSNP;
	components DsnPlatformC;
	
	components RealMainP, MainC;
	RealMainP.PlatformInit -> DSNP.NodeIdInit;
	
	DSN = DSNP.DSN;
	DsnSend = DSNP.DsnSend;
	DsnReceive = DSNP.DsnReceive;
	MainC.SoftwareInit->DSNP.Init;
		
	// wire uart stuff
	DSNP.DsnPlatform -> DsnPlatformC;
	DSNP.UartStream -> DsnPlatformC;
	DSNP.Resource -> DsnPlatformC;
#endif	
}

