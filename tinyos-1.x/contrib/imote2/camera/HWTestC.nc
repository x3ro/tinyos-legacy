/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
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
 */
/**                                         
 * Description - IMote2 Hardware integration test module.
 *
 * @author Konrad Lorincz
 * @version 1.0, July 11, 2005
 */
includes pxa27x_registers;
includes HWTest;
includes KAC9648;
includes RegUtils;
includes Image;
includes PrintfUART;

configuration HWTestC 
{
}
implementation 
{
    components Main, HWTestM, TimerC, LedsC;
    components GenericComm;
    components PXA27XI2CM;
    components I2CTransactionM;
    components PXA27XInterruptM;
    components PXA27XGPIOIntC;
    components KAC9648C;
    components ImageC;

    Main.StdControl -> TimerC;
    Main.StdControl -> HWTestM;
    Main.StdControl -> PXA27XI2CM;
    Main.StdControl -> GenericComm.Control;
    Main.StdControl -> KAC9648C;
    Main.StdControl -> ImageC;


    HWTestM.Timer      -> TimerC.Timer[unique("Timer")];
    HWTestM.Leds       -> LedsC;
    HWTestM.SendMsg    -> GenericComm.SendMsg[AM_HWTESTMSG];
    HWTestM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_HWTESTMSG];
    HWTestM.Image      -> ImageC;
                              
    HWTestM.KAC9648        -> KAC9648C;                               
    HWTestM.I2CTransaction -> I2CTransactionM.I2CTransaction[1];
    HWTestM.I2CIrq         -> PXA27XInterruptM.PXA27XIrq[PPID_I2C];

    I2CTransactionM.I2C    -> PXA27XI2CM;
}

