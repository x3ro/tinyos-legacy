/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

includes Msg;

configuration McTorrentC {
    provides interface StdControl;
}

implementation {
    components McTorrentM, 
        TimerC, RandomLFSR, GenericComm as Comm, LedsC,
#ifdef HW_DEBUG
        DebugLogM,
#endif
        UARTFramedPacket,
        CrcC, 
        BlockStorageC, FlashWPC,
#ifndef PLATFORM_PC
        InternalFlashC,
        NetProgM,
#endif
        BitVecUtilsM, 
        SystemTimeC, ChannelStateC,
        ChannelSelectM, DataManagementM, ControlPlaneM, DataPlaneM;

    StdControl =  McTorrentM;

    McTorrentM.TimerControl -> TimerC;
    McTorrentM.UARTControl -> UARTFramedPacket;
    McTorrentM.ChannelStateControl -> ChannelStateC;
    McTorrentM.ChannelSelectControl -> ChannelSelectM;
    McTorrentM.ControlPlaneControl -> ControlPlaneM;
    McTorrentM.DataPlaneControl -> DataPlaneM;
    McTorrentM.FlashWPControl -> FlashWPC;
    McTorrentM.Leds -> LedsC;

    ChannelSelectM.Random -> RandomLFSR;
    ChannelSelectM.SystemTime -> SystemTimeC;
    
    ControlPlaneM.BitVecUtils -> BitVecUtilsM;
    ControlPlaneM.DataPlane -> DataPlaneM;
    ControlPlaneM.DataManagement -> DataManagementM;
    ControlPlaneM.ChannelSelect -> ChannelSelectM;
    ControlPlaneM.ChannelState -> ChannelStateC;
    ControlPlaneM.Random -> RandomLFSR;
    ControlPlaneM.ReceiveAdvMsg -> Comm.ReceiveMsg[AM_ADVMSG];
    ControlPlaneM.SendAdvMsg -> Comm.SendMsg[AM_ADVMSG];
    ControlPlaneM.ReceiveReqMsg -> Comm.ReceiveMsg[AM_REQMSG];
    ControlPlaneM.SendReqMsg -> Comm.SendMsg[AM_REQMSG];
    ControlPlaneM.ReceiveChnMsg -> Comm.ReceiveMsg[AM_CHNMSG];
    ControlPlaneM.SendChnMsg -> Comm.SendMsg[AM_CHNMSG];
    ControlPlaneM.SystemTime -> SystemTimeC;
    ControlPlaneM.AdvTimer -> TimerC.Timer[unique("Timer")];
    ControlPlaneM.ReqCollectTimer -> TimerC.Timer[unique("Timer")];
    ControlPlaneM.ReqTimer -> TimerC.Timer[unique("Timer")];
    ControlPlaneM.ChnWaitTimer -> TimerC.Timer[unique("Timer")];
    ControlPlaneM.RebootTimer -> TimerC.Timer[unique("Timer")];
    ControlPlaneM.Leds -> LedsC;
#ifndef PLATFORM_PC
    ControlPlaneM.NetProg-> NetProgM;
#endif

    DataPlaneM.BitVecUtils -> BitVecUtilsM;
    DataPlaneM.Random -> RandomLFSR;
    DataPlaneM.DataManagement -> DataManagementM;
    DataPlaneM.ReceiveDataMsg -> Comm.ReceiveMsg[AM_DATAMSG];
    DataPlaneM.SendDataMsg -> Comm. SendMsg[AM_DATAMSG];
    DataPlaneM.TxTimer -> TimerC.Timer[unique("Timer")];
    DataPlaneM.RetxTimer -> TimerC.Timer[unique("Timer")];
    DataPlaneM.RxTimer -> TimerC.Timer[unique("Timer")];

    DataManagementM.FlashWP -> FlashWPC;
    DataManagementM.Mount -> BlockStorageC.Mount[BLOCKSTORAGE_ID_0];
    DataManagementM.BlockRead -> BlockStorageC.BlockRead[BLOCKSTORAGE_ID_0];
    DataManagementM.BlockWrite -> BlockStorageC.BlockWrite[BLOCKSTORAGE_ID_0];
    DataManagementM.Crc -> CrcC;
    DataManagementM.Leds -> LedsC;

#ifndef PLATFORM_PC
    NetProgM.Crc -> CrcC;
    NetProgM.IFlash -> InternalFlashC;
#endif


#ifdef HW_DEBUG
    ControlPlaneM.DebugLog -> DebugLogM;
    DataPlaneM.DebugLog -> DebugLogM;
    DataPlaneM.ChannelState -> ChannelStateC;
    DebugLogM.SendDebugMsg -> Comm.SendMsg[200];
    DebugLogM.SystemTime -> SystemTimeC;
#endif
}


