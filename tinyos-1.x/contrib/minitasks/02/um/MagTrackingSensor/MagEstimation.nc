/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Cory Sharp
// $Id: MagEstimation.nc,v 1.1 2003/06/02 12:34:14 dlkiskis Exp $

// Description: Sensor magnitude measurement announcing and aggregation.

includes MagHood;
includes TickSensor;
includes NestArch;

configuration MagEstimation
{
}
implementation
{
  components Main
	, MagEstimationM
	, NestArchStdControlC
	, EstimationCommC
	, MagU16C as U16SensorC
	//, PhotoC as U16SensorC
	, TickSensorC
	, TimedLedsC
	, TimerC
	, ConfigC
	, NeighborhoodC
	, PotC
	, QueryProcessorC
	, QueryIndexC
	, IntervalTreeC
	, LedsC
	;

#ifdef PC_DEBUG
  components DebugC, UARTComm;
#endif

  Main.StdControl -> MagEstimationM;
  Main.StdControl -> NestArchStdControlC;
  Main.StdControl -> EstimationCommC;
  Main.StdControl -> U16SensorC;
  Main.StdControl -> TickSensorC;
  Main.StdControl -> TimedLedsC;
  Main.StdControl -> TimerC;

  MagEstimationM.U16Sensor      -> U16SensorC;
  MagEstimationM.TickSensor     -> TickSensorC;
  MagEstimationM.Timer          -> TimerC.Timer[unique("Timer")];
  MagEstimationM.Config_mag_movavg_timer_period -> ConfigC;
  MagEstimationM.Neighbor_mag   -> NeighborhoodC;
  MagEstimationM.TupleStore     -> NeighborhoodC;
  MagEstimationM.TimedLeds      -> TimedLedsC;
  MagEstimationM.EstimationComm -> EstimationCommC;
  MagEstimationM.Pot            -> PotC;
  MagEstimationM.QueryProcessor -> QueryProcessorC;
  MagEstimationM.Leds           -> LedsC;


  QueryProcessorC.QueryIndex -> QueryIndexC;
  QueryIndexC.IntervalTree -> IntervalTreeC;
  QueryProcessorC.Leds -> LedsC;

  QueryIndexC.Leds ->LedsC;

#ifdef PC_DEBUG
  MagEstimationM.UARTCommControl -> UARTComm;
  DebugC.SendMsg -> UARTComm.SendMsg[16];
  DebugC.Timer-> TimerC.Timer[unique("Timer")];
#endif

#ifdef PC_DEBUG_QP
  QueryProcessorC.Debug -> DebugC;
#endif
#ifdef PC_DEBUG_ME
  MagEstimationM.Debug -> DebugC;
#endif
#ifdef PC_DEBUG_QI
  QueryIndexC.Debug -> DebugC;
#endif
#ifdef PC_DEBUG_INT
  IntervalTreeC.Debug -> DebugC;
#endif


}

