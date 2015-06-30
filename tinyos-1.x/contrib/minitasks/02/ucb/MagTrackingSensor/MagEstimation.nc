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
// $Id: MagEstimation.nc,v 1.3 2003/02/04 00:47:51 cssharp Exp $

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
	   ;

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
}

