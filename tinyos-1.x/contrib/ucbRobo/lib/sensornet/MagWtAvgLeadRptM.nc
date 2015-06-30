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
// $Id: MagWtAvgLeadRptM.nc,v 1.2 2005/04/15 20:10:07 phoebusc Exp $
/**  
 * MagWtAvgLeadRptM performs two functions.
 * <OL>
 *  <LI> On a sensor reading report, This component decides whether
 *       the sensor node is the leader node amongst its neighbors.  The
 *       leader node is the node that reports the aggregated readings to
 *       the basestation/"the rest of the world".<P>
 *       The leader election policy is: The sensor node with the
 *       maximum combined X and Y axis magnetometer reading within a
 *       time period is the leader.  (See documentation for task
 *       <CODE> reportIfLeader() </CODE> for more details) </LI>
 *  <LI> Performs the data aggregation of its reading and its
 *       neighbor's readings when making "leader" reports. <P>
 *       The data aggregation policy is to take the weighted average
 *       of the positions of the neighboring nodes using the sensing
 *       magnitudes in the X and Y directions as the respective
 *       weights. </LI> 
 * </OL>
 *
 * To perform these functions, this component maintains a table <CODE>
 * neighborTable </CODE> to store the sensing values reported by its
 * neighbors.<BR>
 *
 * Read the comments for the tasks in this component for algorithm details.
 *
 * @author Phoebus Chen
 * @modified 9/30/2004 Changed File Name
 * @modified 9/13/2004 First Implementation
 */

includes MagWtAvgLeadRptM;
includes neighbor_table;

module MagWtAvgLeadRptM {
  provides {
    interface StdControl;
    interface ConfigAggProcessing;
    interface CompComm;
  }
  uses {
    interface StdControl as MagProcessingControl;
    interface SenseUpdate;
    interface Timer as AggTimer;
    interface Location;

    //for table management
    interface TimeStamp;
  }
}


implementation {

  //in most situations, the staleAge should be 2X the timeOut (or
  //greater, but there really is no reason to store data you'll never use).
  //timeOut should be smaller than staleAge for proper operation.
  uint32_t timeOut; //time to wait for neighbors' reports

  uint32_t cleanTime; //bookkeeping for cleaning table of stale entries
  uint32_t staleAge; //how long before an entry is effectively invalid
  NeighborTableEntry_t neighborTable[MAX_NEIGHBORS];
  NeighborTableEntry_t *tableEnd = neighborTable+MAX_NEIGHBORS; //serves as constant
  NeighborTableEntry_t newEntry; //temporary storage
  uint8_t tableLock;
  uint8_t dup_report; //Used to signal between tasks whether your
		      //report will be a duplicate
  Mag_t myMagRead;
  uint32_t mySumXY;
  


  /********** Table Functions **********/
  enum {
    LOCKED = 1,
    UNLOCKED = 0
  };

  result_t getTableLock(uint8_t lock) {
    bool result;
    atomic {
      if (lock == LOCKED) {
	result = FAIL;
      } else {
	lock = LOCKED;
	result = SUCCESS;
      }
    }
    return result;
  }

  void releaseTableLock(uint8_t lock) {
    lock = UNLOCKED;
  }
  /*************************************/



  /** Read the documentation under <CODE> addTable(...)  </CODE> in
   * neighborhood_table.h for the table eviction policy.  This task
   * first tries to acquire the lock on the table before operating on
   * it.  If it doesn't acquire the lock, it reposts itself on the task
   * list (should not happen... all table access should be in tasks.
   * The lock is just a safety feature);
   */
  task void updateTable() {
    uint32_t ts;
    if (getTableLock(tableLock)) {
      ts = call TimeStamp.getTimeStamp();
      addTable(neighborTable,tableEnd,staleAge,ts,&newEntry);
      releaseTableLock(tableLock);
    } else {
      post updateTable(); //repost yourself
    }
  }


  /** Performs the data aggregation by taking a weighted average of
   *  the position where we received all the reports, using the
   *  magnitude of the reading as the weights.
   *  
   *  Currently, we do nothing with the bias value of the magnetometer.
   */
  task void weightedPosAvg() {
    uint32_t totalWeightX, totalWeightY, currentTime;
    location_t myPos;
    MagWeightPos_t magAgg;


    currentTime = call TimeStamp.getTimeStamp();
    if (getTableLock(tableLock)) {
      myPos = call Location.getPosition();
      magAgg.posX = myPos.pos.x * myMagRead.val.x;
      magAgg.posY = myPos.pos.y * myMagRead.val.y;
      totalWeightX = myMagRead.val.x;
      totalWeightY = myMagRead.val.y;
      magAgg.numReports = 0;

      magAgg = getWeightPosAvg(neighborTable, tableEnd, 2*timeOut, currentTime,
			       magAgg, totalWeightX, totalWeightY);
      releaseTableLock(tableLock);
      magAgg.dupFlag = dup_report;
      signal CompComm.aggDataReady(magAgg);
    } else {
      post weightedPosAvg();
    }
  }


  /** Checks the table to see if my reading is the strongest
   *  reading. Of the readings <CODE> timeOut </CODE> before and
   *  <CODE> timeOut </CODE> after.  If so, this means I am the leader
   *  and should report (post the task <CODE> weightedPosAvg()
   *  </CODE>).
   *
   *  Note that this means that when we get a series of reports
   *  spanning several <CODE> timeOut </CODE> intervals, one
   *  successively greater than another, it is possible that we
   *  will drop several of the intermediate reports (they think that
   *  a node with a later reading will report, which thinks that
   *  another node with a later reading will report... till the last
   *  guy, who only looks one timeOut period prior to do the aggregate
   *  report.  Hope this is not too common.
   */
  task void reportIfLeader() {
    uint32_t currentTime, maxNeighVal;
    currentTime = call TimeStamp.getTimeStamp();
    if (getTableLock(tableLock)) {
      maxNeighVal = getMaxValidValue(neighborTable, tableEnd,
				     2*timeOut, currentTime);
      if (maxNeighVal <= mySumXY) {
	dup_report = (maxNeighVal > mySumXY) ? NO_DUP_REPORT : DUP_REPORT;
	post weightedPosAvg();
      } //do nothing if you are not the largest report
      releaseTableLock(tableLock);
    } else {
      post reportIfLeader(); //repost yourself
    }
  }


  /** Removes stale elements from the table.  Called from event <CODE>
   *  TimeStamp.signalHalfCycle() </CODE>.  See documentation for <CODE>
   *  invalidFromStale </CODE> for more implementation details.
   */
  task void removeTableStale() {
    invalidFromStale(neighborTable,tableEnd,staleAge,cleanTime);
  }



  command result_t StdControl.init() {
    timeOut = DEFAULT_TIMEOUT;
    staleAge = DEFAULT_STALEAGE;
    return call MagProcessingControl.init();
  }


  command result_t StdControl.start() {
    //note that if GenericComm gets started and we start updating the
    //table before it's ready, that's okay because we'll just
    //invalidate it
    initTable(neighborTable, tableEnd); //want to reinitialize
                                         //every time we restart
    return call MagProcessingControl.start();
  }


  command result_t StdControl.stop() {
    return call MagProcessingControl.stop();
  }


  command result_t ConfigAggProcessing.setTimeOut(uint32_t newTimeOut) {
    timeOut = newTimeOut; //used by a one-shot timer,so we don't need
			  //to restart the timer
    return SUCCESS;
  }


  command result_t ConfigAggProcessing.setStaleAge(uint32_t newStaleAge) {
    staleAge = newStaleAge;
    return SUCCESS;
  }


  command uint32_t ConfigAggProcessing.getTimeOut() {
    return timeOut;
  }


  command uint32_t ConfigAggProcessing.getStaleAge() {
    return staleAge;
  }



  /** Asks the a clock for a timestamp, storing the received reading
   *  into the <CODE> neighborTable </CODE> along with the timestamp.
   */
  command result_t CompComm.passReports(uint16_t sourceMoteID, Mag_t magReport,
					location_t location) {
    uint32_t ts;

    ts = call TimeStamp.getTimeStamp();

    newEntry.sourceMoteID = sourceMoteID;
    newEntry.valid = 1; //must be 1
    newEntry.timeStamp = ts;
    newEntry.magData = magReport;
    newEntry.loc = location;

    post updateTable();
    return SUCCESS;
  }


  /** This event is assumed to be triggered only if a sensor reading
   * of significance occured. <CODE> value </CODE> is stored, and a
   * one-shot timer is triggered to measure an interval of time where
   * other nodes may report their sensor readings to be aggregated.
   * The task performing the actual data aggregation/processing occurs
   * after the timer fires, if this nodes decides that it is the
   * leader and should report.
   */
  event result_t SenseUpdate.senseFired(Mag_t value) {
    myMagRead = value;
    mySumXY = myMagRead.val.x + myMagRead.val.y;
    //no need to timeStamp my reading in this component.  The AggTimer
    //serves as a "timeStamp"
    return call AggTimer.start(TIMER_ONE_SHOT,timeOut);
  }


  /** Fired when all sensor readings from neighbors should have been
   *  reported.  Posts <CODE> reportIfLeader </CODE> to determine if
   *  should aggregate data and report.
   */
  event result_t AggTimer.fired() {
    post reportIfLeader();
    return SUCCESS;
  }


  event result_t TimeStamp.signalHalfCycle(uint32_t clockCounter) {
    cleanTime = clockCounter;
    post removeTableStale();
    return SUCCESS;
  }

}
