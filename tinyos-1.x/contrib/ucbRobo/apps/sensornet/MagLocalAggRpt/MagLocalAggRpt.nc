/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 */
// $Id: MagLocalAggRpt.nc,v 1.2 2005/04/15 20:10:06 phoebusc Exp $
/**
 * MagLocalAggRpt is the sensor network application used for testing a
 * basic control feedback loop. The sensor network acts as the
 * <I> Observer </I> in the loop, sensing magnetic disturbances,
 * aggregating readings to form an estimate of the position of the
 * disturbance, and then single-hop broadcasting the result. <P>
 * 
 * Theory of Operation (per sensor node):<BR>
 * The magnetometer is constantly polled for magnetic readings.  When
 * the pattern of readings signifies a magnetic disturbance (as
 * determined by the subcomponent <CODE> DetectAndReportM </CODE>), the
 * component <CODE> CoreCompM </CODE> begins processing to determine if
 * it is the leader of its group of neighboring nodes.  If this node
 * determines that it is indeed the leader/reporting node for its
 * neighbors, <CODE> CoreCompM </CODE> aggregates the readings into a
 * report which is then one-hop broadcasted. <P>
 *
 * More details of the algorithms used can be found in the comments
 * for each of the subcomponents and interfaces. <P>
 *
 * This application assumes that the radio communication range is more
 * than twice as great as the magnetometer sensing range.  If not, we
 * may get multiple reports for the same magnetic disturbance. <P>
 *
 * Note that this application is basically a stripped down version of
 * PEGSensor.  Particularly, it does not contain Neighborhood and
 * Config, and does not use any fancy routing algorithms to
 * communicate to the robot (as the robot is suppose to be the only
 * object causing magnetic disturbances in the network, so we can
 * one-hop broadcast the result).  Because this application is easier
 * to read than PEGSensor, it should be read before trying to
 * understand the full PEG application demoed in the summer of
 * 2003. (For clarity, most "parallel" modules between this
 * application and PEG do not have the same name.) <P>
 *
 * NOTE: This application is written to use the magsensor stack in the
 * RobotTestbed suite, not that from PEGSensor, because Config is
 * stripped out of the code.
 * 
 * @author Phoebus Chen
 * @modified 9/30/2004 File Name Changed
 * @modified 9/13/2004 First Implementation
 */

includes MagSNMsgs;

configuration MagLocalAggRpt {
}

implementation {
  components Main,
             MagLocalAggRptM,
             MagWtAvgLeadRptM as CoreCompM,
             MovAvgDetect_DiffRptM as DetectAndReportM,
             HDMagMagC as MagC,
             GenericComm as Comm,
             TimeStampClockC,
             TimerC,
             LedsC;

  Main.StdControl -> MagLocalAggRptM; //this starts CoreCompM which then
				    //starts DetectAndReportM, which
				    //then starts MagC
  Main.StdControl -> Comm;
  Main.StdControl -> TimerC;
  Main.StdControl -> TimeStampClockC;


  MagLocalAggRptM.Leds -> LedsC;
  MagLocalAggRptM.FadeTimer -> TimerC.Timer[unique("Timer")];

  MagLocalAggRptM.CoreCompControl -> CoreCompM;
  MagLocalAggRptM.CompComm -> CoreCompM;
  MagLocalAggRptM <- CoreCompM.Location;

  // for receiving updates so can broadcast to other nodes
  MagLocalAggRptM.SenseUpdate -> DetectAndReportM;

  //CONFIGURATION INTERFACES
  MagLocalAggRptM.ConfigAggProcessing -> CoreCompM;
  MagLocalAggRptM.ConfigTrigger -> DetectAndReportM;
  MagLocalAggRptM.ConfigMagProcessing -> DetectAndReportM;

  //COMMUNICATION INTERFACES
  MagLocalAggRptM.ReceiveQueryConfigMsg -> Comm.ReceiveMsg[AM_MAGQUERYCONFIGMSG];
  MagLocalAggRptM.ReceiveMagReportMsg -> Comm.ReceiveMsg[AM_MAGREPORTMSG];
  MagLocalAggRptM.SendQueryReportMsg -> Comm.SendMsg[AM_MAGQUERYCONFIGMSG];
  MagLocalAggRptM.SendMagReportMsg -> Comm.SendMsg[AM_MAGREPORTMSG];
  MagLocalAggRptM.SendMagLeaderReportMsg -> Comm.SendMsg[AM_MAGLEADERREPORTMSG];
  //sending over ethernet backchannel for monitoring purposes
  //!!!  MagLocalAggRptM.SendMonMagReportMsg -> Comm.SendMsg[AM_MONMAGREPORTMSG];


  CoreCompM.MagProcessingControl -> DetectAndReportM;
  CoreCompM.AggTimer -> TimerC.Timer[unique("Timer")];
  CoreCompM.SenseUpdate -> DetectAndReportM;
  CoreCompM.TimeStamp -> TimeStampClockC;


  DetectAndReportM.MagControl -> MagC;
  DetectAndReportM.MagSensor -> MagC;
  DetectAndReportM.MagAxesSpecific -> MagC;
  DetectAndReportM.SenseTimer -> TimerC.Timer[unique("Timer")];

} //implementation
