/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang
 * Date last modified: 06/27/03
 */

configuration ReceiverAppC{}

implementation {
	components Main, ReceiverServiceC, SystemC;

	Main.StdControl -> SystemC;
	SystemC.Service[20] -> ReceiverServiceC;
}
