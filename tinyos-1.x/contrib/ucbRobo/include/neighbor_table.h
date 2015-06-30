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
// $Id: neighbor_table.h,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/** 
 * This file contains the data structures and functions necessary to
 * implement the data table storing sensor data from neighboring
 * nodes.
 *
 * @author Phoebus Chen
 * @modified 9/2/2004 First Implementation
 */


#include "MagSensorTypes.h" //for Mag_t
#include "MagAggTypes.h" //for MagWeightPos_t
#include "LocationTypes.h"


/**************** Supporting  Code ****************/
#define checkInRangeA(time,currentTime,staleTime) ((time <= currentTime) \
						   && (time > staleTime))
#define checkInRangeB(time,currentTime,staleTime) ((time <= currentTime) \
						   || (time > staleTime))
/**************************************************/



/** The table is represented by:
 *  <OL>
 *   <LI> Array of <CODE> NeighborTableEntry_t </CODE> </LI>
 *   <LI> Clock for time stamping entries and table access </LI>
 *   <LI> <CODE> staleAge </CODE>, a variable to store how long before
 *        a table entry is considered invalid </LI>
 *   <LI> <CODE> accessFlag </CODE>, a variable to ensure that the
 *        table is not being read/written at the same time </LI>
 *  </OL>
 *
 * Clock Requirements: <BR>
 *  The clock would need to spit out <CODE> uint32_t </CODE> values
 *  for time instead of, for example, <CODE> tos_time_t </CODE> which
 *  requires <CODE> TimeUtilC.nc </CODE>.
 *
 * Table Entry Representation: <BR> The <CODE> timeStamp </CODE> in
 * conjunction with the <CODE> valid </CODE> flag determines if an
 * entry is valid.  A valid entry must
 *  <OL>
 *   <LI> have the <CODE> valid </CODE> flag set to valid </LI>
 *   <LI> have a <CODE> timeStamp </CODE> that lies between the
 *        current time of table access, <CODE> currentTime </CODE>,
 *        and <CODE> staleTime </CODE>.  Of course, since the counter
 *        wraps around, "lies between" actually means one of two
 *        things: 1) <CODE> staleTime < timeStamp < currenTime </CODE>
 *        and 2) <CODE> timeStamp < currenTime || timeStamp >
 *        staleTime </CODE>, depending on <CODE> staleTime >? <?
 *        currentTime </CODE> </LI>
 *  </OL>
 *
 *  DESIGN DECISION: We choose to implement a table with an eviction
 *  policy instead of a queue to minimize the opportunity for one
 *  malfunctioning node that reports too often to flush out the
 *  entries from other motes. See the comments for <CODE>
 *  addTable(...) </CODE> for details about the eviction policy.<P>
 *
 */


typedef struct NeighborTableEntry_t {
  uint16_t sourceMoteID;
  bool valid;
  uint32_t timeStamp;
  Mag_t magData;
  location_t loc;
} NeighborTableEntry_t;



/********************FUNCTIONS********************/

/*
//Paste the code below into your TinyOS component containing the
//lock on the table.  It is the user's responsibility to unlock the
//table only if you were the one locking it.  But in actuality,
//tables should only be accessed in tasks, so locking should not be
//an issue.

result_t getTableLock(uint8_t lock) {
  atomic {
    if (lock == LOCKED) {
      return FAIL;
    } else {
      lock = LOCKED;
      return SUCCESS;
    }
  }
}

void releaseTableLock(uint8_t lock) {
  lock = UNLOCKED;
}
*/ 




/**
 * Initializes the table to contain only invalid entries. <BR>
 *
 * PRECONDITION: DOESN'T need to obtain lock to operate on table.
 *
 * @param endAddr the address after the last valid entry
 */
void initTable(NeighborTableEntry_t* baseAddr, NeighborTableEntry_t* endAddr) {
  NeighborTableEntry_t *i; 
  for (i = baseAddr; i != endAddr ; i++) {
    i->valid = 0;
  }
}


/** This function is called when the clock time for timestamps has
 *  overflowed/wrapped around and we must tag the entries that are too
 *  old as invalid. <P>
 *
 *  In operation,
 *  <OL>
 *   <LI> the clock for the timestamps needs to fire when the
 *        clock counter counts halfway to the overflow value and when
 *        the clock counter counts to the overflow value, and </LI>  
 *   <LI> the age before an entry becomes invalid <CODE> staleAge
 *        </CODE> must be less than half the cycle time of the
 *        counter </LI>
 *  </OL>
 *  for this algorithm to work properly. <BR>
 *
 * PRECONDITION: obtained lock to operate on table.
 * @param endAddr the address after the last valid entry
 * @param staleAge all entries older than staleAge are marked as
 *        invalid.
 */
void invalidFromStale(NeighborTableEntry_t* baseAddr, NeighborTableEntry_t* endAddr,
		      uint32_t staleAge, uint32_t currentTime) {
  uint32_t staleTime;
  NeighborTableEntry_t *i;

  staleTime = currentTime - staleAge;
  if (staleTime < currentTime) {
    for (i = baseAddr; i != endAddr ; i++) {
      if (!checkInRangeA(i->timeStamp, currentTime, staleTime)) {
	i->valid = 0;
      }
    }
  } else { //staleTime > currentTime, meaning wraparound
    for (i = baseAddr; i != endAddr ; i++) {
      if (!checkInRangeB(i->timeStamp, currentTime, staleTime)) {
	i->valid = 0;
      }
    }
  } //if(staleTime < currentTime)
}


/** Function to add an entry into the neighborhood table.  The table
 *  eviction policy, by priority, is as follows:
 *  <OL>
 *   <LI> If a previous report by that node is already present in the
 *        table, the old report is overwritten by the new report. </LI>
 *   <LI> An empty slot or "stale" slots (<CODE> timeStamp </CODE> is older
 *        than staleTime) are overwritten. </LI>
 *   <LI> The oldest report is overwritten. (hopefully this doesn't
 *        happen) </LI>
 *  </OL>
 *
 * @param endAddr the address after the last valid entry
 * @param staleAge all entries older than staleAge are considered
 *        invalid.  Typically, <B> this </B> staleAge = the
 *        staleAge used in the function <CODE> invalidFromStale(...)
 *        </CODE>.
 * @param entry a pointer to a fully populated <CODE>
 *        NeighborTableEntry_t </CODE> that will be <B> copied </B> verbatim
 *        into the table.  The <CODE> valid </CODE> flag must already be set.
 *
 * PRECONDITION: obtained lock to operate on table.
 */
void addTable(NeighborTableEntry_t* baseAddr, NeighborTableEntry_t* endAddr, 
	      uint32_t staleAge, uint32_t currentTime, NeighborTableEntry_t* entry) {
  uint32_t staleTime;
  uint32_t maxAge;
  NeighborTableEntry_t *i, *oldest;

  //evict old report policy
  for (i = baseAddr; i != endAddr ; i++) {
    if (i->sourceMoteID == entry->sourceMoteID) {
      *i = *entry;
      return;
    }
  }

  staleTime = currentTime - staleAge;
  if (staleTime < currentTime) {
    //evict stale policy
    for (i = baseAddr; i != endAddr ; i++) {
      if (!i->valid || 
	  !checkInRangeA(i->timeStamp, currentTime, staleTime)) {
	*i = *entry;
	return;
      }
    }
  } else { //staleTime > currentTime, meaning wraparound
    //evict stale policy
    for (i = baseAddr; i != endAddr ; i++) {
      if (!i->valid || 
	  !checkInRangeB(i->timeStamp, currentTime, staleTime)) {
	*i = *entry;
	return;
      }
    }
  }

  //evict oldest policy (already checked that all are valid.  not
  //preferred method)
  oldest = baseAddr;
  maxAge = 0;
  for (i = baseAddr; i != endAddr ; i++) {
    if ((currentTime - i->timeStamp) > maxAge) {
      oldest = i;
      maxAge = currentTime - i->timeStamp;
    }
  }
  *oldest = *entry;
  return;
}


/** Gets the maximum value of all valid entries.  By maximum value, we
 *  mean the entry with the maximum sum of the X and Y sensor
 *  readings.  See the comments at the top of the file for what
 *  defines a valid entry.
 *
 * @param endAddr the address after the last valid entry
 *  @param currentTime current time returned by the Table Clock.
 *  @param prevPeriod amount of time before <CODE> currentTime </CODE>
 *         constituting the relevant time period.
 *  @return maxSumXY is the maximum value
 *
 * PRECONDITION: obtained lock to operate on table.
 */
uint32_t getMaxValidValue(NeighborTableEntry_t* baseAddr,
			  NeighborTableEntry_t* endAddr, 
			  uint32_t prevPeriod, uint32_t currentTime) {
  uint32_t prevTime, maxSumXY = 0;
  NeighborTableEntry_t *i;

  prevTime = currentTime - prevPeriod;
  if (prevTime < currentTime) {
    for (i = baseAddr; i != endAddr ; i++) {
      if ((i->valid) && 
	  checkInRangeA(i->timeStamp,currentTime,prevTime) && //checks for validity
	  (((uint32_t)(i->magData.val.x + i->magData.val.y)) >= maxSumXY)) {
	maxSumXY = i->magData.val.x + i->magData.val.y;
      }
    }
  } else { //prevTime > currentTime, meaning wraparound
    for (i = baseAddr; i != endAddr ; i++) {
      if ((i->valid) && 
	  checkInRangeB(i->timeStamp,currentTime,prevTime) && //checks for validity
	  (((uint32_t)(i->magData.val.x + i->magData.val.y)) >= maxSumXY)) {
	maxSumXY = i->magData.val.x + i->magData.val.y;
      }
    }
  } //if (prevTime < currentTime)
  return maxSumXY;
}


//////////////////// Table Aggregation Method(s) ////////////////////


/**
 * @param magAgg
 * @param totalWeightX
 * @param totalWeightY
 */
MagWeightPos_t getWeightPosAvg(NeighborTableEntry_t* baseAddr,
			       NeighborTableEntry_t* endAddr, 
			       uint32_t prevPeriod, uint32_t currentTime,
			       MagWeightPos_t magAgg,
			       uint32_t totalWeightX, uint32_t totalWeightY) {
  uint32_t prevTime;
  NeighborTableEntry_t *i;

  prevTime = currentTime - prevPeriod;

  //loop through table
  if (prevTime < currentTime) {
    for (i = baseAddr; i != endAddr ; i++) {
      if ((i->valid) && 
	  checkInRangeA(i->timeStamp,currentTime,prevTime)) {
	magAgg.posX += i->loc.pos.x * i->magData.val.x;
	magAgg.posY += i->loc.pos.y * i->magData.val.y;
	totalWeightX += i->magData.val.x;
	totalWeightY += i->magData.val.y;
	magAgg.numReports++;
      }
    }
  } else { //prevTime > currentTime, meaning wraparound
    for (i = baseAddr; i != endAddr ; i++) {
      if ((i->valid) && 
	  checkInRangeB(i->timeStamp,currentTime,prevTime)) {
	magAgg.posX += i->loc.pos.x * i->magData.val.x;
	magAgg.posY += i->loc.pos.y * i->magData.val.y;
	totalWeightX += i->magData.val.x;
	totalWeightY += i->magData.val.y;
	magAgg.numReports++;
      }
    }
  } //if (prevTime < currentTime)
      
  magAgg.posX = magAgg.posX/totalWeightX;
  magAgg.posY = magAgg.posY/totalWeightY;
  magAgg.magSum = totalWeightX + totalWeightY;

  return magAgg;
}







//////////////////////////////USELESS CODE //////////////////////////////

/*  I realized that I didn't need any of the code below because the
    readings I wanted to add and compare were 16-bit, not 32-bit. */


/* //since we do not have uint64_t types.  This is slightly overkill for */
/* //our application, but we're not optimizing for space here. */
/* typedef struct uint64_struct_t { */
/*   uint32_t hi; */
/*   uint32_t lo; */
/* } uint64_struct_t; */


/* uint64_struct_t sum64(uint32_t x, uint32_t y) { */
/*   uint64_struct_t retVal = {hi:0, lo:0}; */
/*   retVal.lo = x+y; */
/*   if ((retVal.lo < x) || (retVal.lo < y)) { //overflow */
/*     retVal.hi = 1; */
/*   } //else retVal.hi = 0 */
/*   return retVal; */
/* } */


/* /\* @return 1 if x >= y, 0 otherwise. */
/*  *\/ */
/* uint8_t compareGTE64(uint64_struct_t x, uint64_struct_t y) { */
/*   if (x.hi > y.hi) { */
/*     return 1; */
/*   } else if (x.hi != y.hi) { */
/*     return 0; */
/*   } */
/*   if (x.lo >= y.lo) { */
/*     return 1; */
/*   } */
/*   return 0; */
/* } */


/* Old code for 32-bit Magnetic reading values... I don't need this,
   but since I wrote it anyways, I didn't want to delete it.  If you
   want to use it, make sure to test it first */
/* /\** Gets the maximum value of all valid entries.  By maximum value, we */
/*  *  mean the entry with the maximum sum of the X and Y sensor */
/*  *  readings.  See the comments at the top of the file for what */
/*  *  defines a valid entry. */
/*  * */
/*  *  @param currentTime current time returned by the Table Clock. */
/*  *  @param prevPeriod amount of time before <CODE> currentTime </CODE> */
/*  *         constituting the relevant time period. */
/*  *  @return maxSumXY is the maximum value, of type <CODE> */
/*  *          uint64_struct_t </CODE> */
/*  * */
/*  * PRECONDITION: obtained lock to operate on table. */
/*  *\/ */
/* uint64_struct_t getMaxValidValue(NeighborTableEntry_t* baseAddr, uint8_t numEntries,  */
/* 				 uint32_t prevPeriod, uint32_t currentTime) { */
/*   uint32_t prevTime; */
/*   uint64_struct_t maxSumXY = {hi:0, lo:0}; */
/*   NeighborTableEntry_t *i, *endAddr; */
/*  //endAddr is the address after the last valid entry */
/*   endAddr = baseAddr+numEntries; //pointer arithmetic! */

/*   prevTime = currentTime - prevPeriod; */
/*   if (prevTime < currentTime) { */
/*     for (i = baseAddr; i != endAddr ; i++) { */
/*       if ((i->valid) &&  */
/* 	  checkInRangeA(i->timeStamp,currentTime,prevTime) && //checks for validity */
/* 	  compareGTE64(sum64(i->magData.val.x,i->magData.val.y),maxSumXY)) { */
/* 	maxSumXY = sum64(i->magData.val.x, i->magData.val.y); */
/*       } */
/*     } */
/*   } else { //prevTime > currentTime, meaning wraparound */
/*     for (i = baseAddr; i != endAddr ; i++) { */
/*       if ((i->valid) &&  */
/* 	  checkInRangeB(i->timeStamp,currentTime,prevTime) && //checks for validity */
/* 	  compareGTE64(sum64(i->magData.val.x,i->magData.val.y),maxSumXY)) { */
/* 	maxSumXY = sum64(i->magData.val.x, i->magData.val.y); */
/*       } */
/*     } */
/*   } //if (prevTime < currentTime) */
/*   return maxSumXY; */
/* } */
