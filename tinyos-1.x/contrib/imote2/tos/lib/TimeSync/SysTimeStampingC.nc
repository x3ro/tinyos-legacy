/*
 * @author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: jan05
 *
 * provides timestamping on transmitting/receiving SFD interrupt,uses 
 * SysTime (Timer3) to get local time 
 *
 */

configuration SysTimeStampingC
{
	provides
	{
		interface TimeStamping;
	}
}

implementation
{
	components SysTimeStampingM, CC2420RadioM, SysTimeC, LedsC, HPLCC2420M;

	TimeStamping = SysTimeStampingM;
	
	SysTimeStampingM.RadioSendCoordinator -> CC2420RadioM.RadioSendCoordinator;
	SysTimeStampingM.RadioReceiveCoordinator -> CC2420RadioM.RadioReceiveCoordinator;
	SysTimeStampingM.SysTime64		 -> SysTimeC;
	SysTimeStampingM.Leds   -> LedsC;
	SysTimeStampingM.HPLCC2420RAM    -> HPLCC2420M;
}
