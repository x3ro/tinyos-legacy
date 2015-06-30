/**
 * Copyright (c) 2008 - George Mason University
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

includes McCORD;

configuration McCORDC {
    provides {
        interface StdControl;
        interface McCORD;
    }
}

implementation {
    components McCORDM,
               TimerC, RandomLFSR, GenericComm as Comm, LedsC,
               CrcC, BlockStorageC, FlashWPC,
               BitVecUtilsM, SystemTimeC, ChannelStateC, CoreM, 
               MsgBufM, NodeListM, ScheduleM,
               NeighborProbeM, DataManagementM, 
               BaseDataTransferM, DataTransferM;

    StdControl = McCORDM;
    McCORD = McCORDM;

    McCORDM.TimerControl -> TimerC;
    McCORDM.CommControl -> Comm;
    McCORDM.ChannelStateControl -> ChannelStateC;
    McCORDM.FlashWPControl -> FlashWPC;
    McCORDM.Leds -> LedsC;
    McCORDM.Random -> RandomLFSR;
    McCORDM.ChannelState -> ChannelStateC;
    McCORDM.DataManagement -> DataManagementM;
    McCORDM.NeighborProbe -> NeighborProbeM;
    McCORDM.Core -> CoreM;
    McCORDM.DataTransfer -> DataTransferM;
    McCORDM.BaseDataTransfer -> BaseDataTransferM;
    McCORDM.SystemTime -> SystemTimeC;
    McCORDM.Timer -> TimerC.Timer[unique("Timer")];
    McCORDM.SendSchedMsg -> Comm.SendMsg[AM_SCHEDMSG];
    McCORDM.ReceiveSchedMsg -> Comm.ReceiveMsg[AM_SCHEDMSG];
    McCORDM.MsgBuf -> MsgBufM;     
    
    BaseDataTransferM.DataManagement -> DataManagementM;
    BaseDataTransferM.MsgBuf -> MsgBufM;
    BaseDataTransferM.ReceiveMetaMsg -> Comm.ReceiveMsg[AM_UARTMETAMSG];
    BaseDataTransferM.SendMetaMsg -> Comm.SendMsg[AM_UARTMETAMSG];
    BaseDataTransferM.ReceiveDataMsg -> Comm.ReceiveMsg[AM_UARTDATAMSG];
    BaseDataTransferM.SendDataMsg -> Comm.SendMsg[AM_UARTDATAMSG];
    BaseDataTransferM.Leds -> LedsC;

    CoreM.NeighborProbe -> NeighborProbeM;
    CoreM.Timer -> TimerC.Timer[unique("Timer")];
    CoreM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
    CoreM.SystemTime -> SystemTimeC;
    CoreM.Schedule -> ScheduleM; 
    CoreM.SendCoreCompeteMsg -> Comm.SendMsg[AM_CORECOMPETEMSG];
    CoreM.ReceiveCoreCompeteMsg -> Comm.ReceiveMsg[AM_CORECOMPETEMSG];
    CoreM.SendCoreSubscribeMsg -> Comm.SendMsg[AM_CORESUBSCRIBEMSG];
    CoreM.ReceiveCoreSubscribeMsg -> Comm.ReceiveMsg[AM_CORESUBSCRIBEMSG];
    CoreM.SendCoreClaimMsg -> Comm.SendMsg[AM_CORECLAIMMSG];
    CoreM.ReceiveCoreClaimMsg -> Comm.ReceiveMsg[AM_CORECLAIMMSG];
    CoreM.Random -> RandomLFSR;
    CoreM.NodeList -> NodeListM;
    CoreM.ChannelState -> ChannelStateC;
    CoreM.MsgBuf -> MsgBufM;
    CoreM.Leds -> LedsC;

    DataManagementM.FlashWP -> FlashWPC;
    DataManagementM.Mount -> BlockStorageC.Mount[BLOCKSTORAGE_ID_0];
    DataManagementM.BlockRead -> BlockStorageC.BlockRead[BLOCKSTORAGE_ID_0];
    DataManagementM.BlockWrite -> BlockStorageC.BlockWrite[BLOCKSTORAGE_ID_0];
    DataManagementM.Crc -> CrcC;    

    DataTransferM.ChannelState -> ChannelStateC;
    DataTransferM.Core -> CoreM;
    DataTransferM.Schedule -> ScheduleM;
    DataTransferM.SystemTime -> SystemTimeC;
    DataTransferM.DataManagement -> DataManagementM;
    DataTransferM.RxTimer -> TimerC.Timer[unique("Timer")];
    DataTransferM.TxTimer -> TimerC.Timer[unique("Timer")];
    DataTransferM.MsgBuf -> MsgBufM;
    DataTransferM.SendAdvMsg -> Comm.SendMsg[AM_ADVMSG];
    DataTransferM.ReceiveAdvMsg -> Comm.ReceiveMsg[AM_ADVMSG];
    DataTransferM.SendReqMsg -> Comm.SendMsg[AM_REQMSG];
    DataTransferM.ReceiveReqMsg -> Comm.ReceiveMsg[AM_REQMSG];
    DataTransferM.SendDataMsg -> Comm.SendMsg[AM_DATAMSG];
    DataTransferM.ReceiveDataMsg -> Comm.ReceiveMsg[AM_DATAMSG];
    DataTransferM.Random -> RandomLFSR;
    DataTransferM.BitVecUtils -> BitVecUtilsM;
    DataTransferM.Leds -> LedsC;

    NeighborProbeM.IntervalTimer -> TimerC.Timer[unique("Timer")];
    NeighborProbeM.SendTimer -> TimerC.Timer[unique("Timer")];
    NeighborProbeM.SendHelloMsg -> Comm.SendMsg[AM_HELLOMSG];
    NeighborProbeM.ReceiveHelloMsg -> Comm.ReceiveMsg[AM_HELLOMSG];
    NeighborProbeM.SendNeighborsMsg -> Comm.SendMsg[AM_NEIGHBORSMSG];
    NeighborProbeM.ReceiveNeighborsMsg -> Comm.ReceiveMsg[AM_NEIGHBORSMSG];
    NeighborProbeM.Random -> RandomLFSR;
    NeighborProbeM.NodeList -> NodeListM;
    NeighborProbeM.ChannelState -> ChannelStateC;
    NeighborProbeM.MsgBuf -> MsgBufM;
    NeighborProbeM.Leds -> LedsC;
#ifdef HW_DEBUG_N
    NeighborProbeM.DataManagement -> DataManagementM;
#endif

    ScheduleM.SystemTime -> SystemTimeC;
    ScheduleM.Timer -> TimerC.Timer[unique("Timer")];

}
 
