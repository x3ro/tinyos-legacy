/**
 * Configuration for ECC module.
 *
 * @author  David Malan <malan@eecs.harvard.edu>
 *
 * @version 2.0
 *
 * Copyright (c) 2004
 *  The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *      may be used to endorse or promote products derived from this software
 *      without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


// include module's header file
includes Ecc;


// configuration
configuration Ecc
{}


// implementation
implementation
{
    // use these components
    components
          Main
        , EccM
        , GenericComm
        , LedsC
        , RandomLFSR
        , SysTimeC
        , TimerC
        ;

    // wire up module
    Main.StdControl -> EccM;

    // wire up GenericComm
    Main.StdControl -> GenericComm.Control;

    // wire up LEDs
    EccM.Leds -> LedsC;

    // wire up PRNG
    EccM.Random -> RandomLFSR;

    // wire up GenericComm.ReceiveMsg for receiving Bob's public key
    EccM.ReceiveMsg ->GenericComm.ReceiveMsg[AM_KEYMSG];

    // wire up GenericComm.SendMsg for sending debugging messages to UART
    EccM.SendDbgMsg -> GenericComm.SendMsg[AM_DBGMSG];

    // wire up GenericComm.SendMsg for broadcasting key messages 
    EccM.SendKeyMsg -> GenericComm.SendMsg[AM_KEYMSG];

    // wire up clock
    EccM.SysTime -> SysTimeC;

    // wire up debugging timer
    EccM.DbgTimer -> TimerC.Timer[unique("Timer")];

    // wire up key-generating timer
    EccM.GenTimer -> TimerC.Timer[unique("Timer")];

    // wire up key-sending timer
    EccM.SendTimer -> TimerC.Timer[unique("Timer")];
}
