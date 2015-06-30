/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: apr06
 *
 * provides timestamping on transmitting/receiving SFD interrupt in CC2420.
 * uses LocalTime interface provided by TimerC: 4 byte local time from TimerB.
 *
 */

configuration TimeStampingC
{
    provides
        interface TimeStamping;
}

implementation
{
    components TimeStampingM, CC2420RadioM, NoLeds as LedsC, HPLCC2420M, 
    #ifdef TIMESYNC_SYSTIME
        LocalTimeMicroC as TimerC;
    #else
        TimerC;
    #endif

    TimeStamping = TimeStampingM;
    
    TimeStampingM.RadioSendCoordinator -> CC2420RadioM.RadioSendCoordinator;
    TimeStampingM.RadioReceiveCoordinator -> CC2420RadioM.RadioReceiveCoordinator;
    TimeStampingM.LocalTime -> TimerC;
    TimeStampingM.Leds   -> LedsC;
    TimeStampingM.HPLCC2420RAM    -> HPLCC2420M;
}
