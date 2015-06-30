/*
 * "Copyright (c) 2007 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
/**
 * 
 * @author Greg Hackmann,Mo Sha
 * @version $Revision: 1.3 $
 * @date $Date: 2011/12/21 17:55:07 $
 */

#define DUTY_CYCLE

uint32_t vDutyCycle = 0;
uint32_t oscDutyCycle = 0;
uint32_t radioDutyCycle = 0;

norace uint32_t radioStartCount = 0;
norace uint32_t radioStopCount = 0;

configuration LatencyBenchmarkAppC
{
}
implementation
{
	components MainC;
	components ActiveMessageC;
	
	components LatencyBenchmarkC as App;
	components new AMSenderC(240) as AMSender;
	components new AMReceiverC(240) as AMReceiver;
	
	components LedsC;
	components new TimerMilliC() as SendTimer;
	components new TimerMilliC() as StartTimer;
//	components new TimerMilliC() as LedTimer;
	components CounterMilli32C as Counter;
	
	App.Boot -> MainC;
	App.Packet -> ActiveMessageC;
	App.AMPacket -> ActiveMessageC;
	App.SplitControl -> ActiveMessageC;
	App.AMSender -> AMSender;
	App.AMReceiver -> AMReceiver;
	App.Leds -> LedsC;
	App.SendTimer -> SendTimer;
	App.StartTimer -> StartTimer;
//	App.LedTimer -> LedTimer;
	
	App.Counter -> Counter;
	
#ifdef UPMA
	components MacControlC;
#ifndef TDMA
	App.LowPowerListening -> MacControlC;
#endif
#ifdef SCP
	App.SyncInterval -> MacControlC;
#endif /* SCP */
#else
	App.LowPowerListening -> ActiveMessageC;
#endif /* UPMA */
}
