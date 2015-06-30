


#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "libdev/status_dev.h"
#include "libdev/command_dev.h"
#include "libmisc/misc_buf.h"
#include "emrun/emrun.h"


char shaped_cvsid[] = "$Id: shaped.c,v 1.1 2004/12/31 20:08:20 yarvis Exp $";


#define SHAPED_STATUSDEVICE "shaped/shape"
#define SHAPED_COMMANDDEVICE "shaped/settings"
#define MAX_NET_SIZE 16

#define UNKNOWN 0 // like being unshapeed
#define SQUARE 0x01
#define TRIANGLE 0x02
#define HRECTANGLE 0x04
#define VRECTANGLE 0x08
#define PLUS 0x10
// VLINE
// PLUS
// 3DIAG
// 4DIAG



status_context_t *shaped_status = NULL;
command_context_t *shaped_command_ctx = NULL;


typedef struct _shapeData_t {
  uint16_t coveredData; /* bits correspond to the values heard from each of the 16 nodes */
  uint16_t nodeData;   /* bits correspond to 16 nodes */
} shapedData_t;


typedef struct _shapedState_t {
  shapedData_t shapedData; /* compressed state for communication */
  //  uint8_t covered[MAX_NET_SIZE]; /* which nodes are covered */
  //  uint8_t responded[MAX_NET_SIZE]; /* which nodes we've heard from */
  int8_t epochs[MAX_NET_SIZE]; /* how many epochs since nodes last update */
  uint8_t lastShape; /* the shape we know about now */
  uint8_t lastGuess; /* the last shapes we might know about */
  uint8_t epochTimeout;  /* change with cmd device. how long we 'remember' info from a node */
} shapedState_t;





/**************************************
 * SHAPE DATABASE
 **************************************/

#define PATTERN_SIZE 100 /* is total number of pre defined patterns below */

const static uint16_t patterns[] = { 

  /* SQUARES - 14 */
  /*1 2 5 6*/ 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5, SQUARE,
  /*2 3 6 7*/ 1 << 1 | 1 << 2 | 1 << 5 | 1 << 6, SQUARE,
  /*3 4 7 8*/ 1 << 2 | 1 << 3 | 1 << 6 | 1 << 7, SQUARE,
  /*5 6 9 10*/ 1 << 4 | 1 << 5 | 1 << 8 | 1 << 9, SQUARE,
  /*6 7 10 11*/ 1 << 5 | 1 << 6 | 1 << 9 | 1 << 10, SQUARE,
  /*7 8 11 12*/ 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11, SQUARE,
  /*9 10 13 14*/ 1 << 8 | 1 << 9 | 1 << 12 | 1 << 13, SQUARE,
  /*10 11 14 15*/ 1 << 9 | 1 << 10 | 1 << 13 | 1 << 14, SQUARE,
  /*11 12 15 16*/ 1 << 10 | 1 << 11 | 1 << 14 | 1 << 15, SQUARE,
  /*1 2 3 5 6 7 9 10 11*/ 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 8 | 1 << 9 | 1 << 10, SQUARE,
  /*2 3 4 6 7 8 10 11 12*/ 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 11, SQUARE,
  /*5 6 7 9 10 11 13 14 15*/ 1 << 4 | 1 << 5 | 1 << 6 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 13 | 1 << 14, SQUARE,
  /*6 7 8 10 11 12 14 15 16*/ 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 13 | 1 << 14 | 1 << 15, SQUARE,
  /*1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16*/ 0xFFFF, SQUARE,

  /* TRIANGLES - 36 */
  /*1 2 5*/ 1 << 0 | 1 << 1 | 1 << 4, TRIANGLE,
  /*2 5 6*/ 1 << 1 | 1 << 4 | 1 << 5, TRIANGLE,
  /*1 5 6*/ 1 << 0 | 1 << 4 | 1 << 5, TRIANGLE,
  /*1 2 6*/ 1 << 0 | 1 << 1 | 1 << 5, TRIANGLE,
  /*2 3 6*/ 1 << 1 | 1 << 2 | 1 << 5, TRIANGLE,
  /*2 3 7*/ 1 << 1 | 1 << 2 | 1 << 6, TRIANGLE,
  /*3 6 7*/ 1 << 2 | 1 << 5 | 1 << 6, TRIANGLE,
  /*2 6 7*/ 1 << 1 | 1 << 5 | 1 << 6, TRIANGLE,
  /*3 4 7*/ 1 << 2 | 1 << 3 | 1 << 6, TRIANGLE,
  /*3 4 8*/ 1 << 2 | 1 << 3 | 1 << 7, TRIANGLE,
  /*4 7 8*/ 1 << 3 | 1 << 6 | 1 << 7, TRIANGLE,
  /*3 7 8*/ 1 << 2 | 1 << 6 | 1 << 7, TRIANGLE,
  /*5 6 9*/ 1 << 4 | 1 << 5 | 1 << 8, TRIANGLE,
  /*5 6 10*/ 1 << 4 | 1 << 5 | 1 << 9, TRIANGLE,
  /*5 9 10*/ 1 << 4 | 1 << 8 | 1 << 9, TRIANGLE,
  /*6 9 10*/ 1 << 5 | 1 << 8 | 1 << 9, TRIANGLE,
  /*6 7 10*/ 1 << 5 | 1 << 6 | 1 << 9, TRIANGLE,
  /*6 7 11*/ 1 << 5 | 1 << 6 | 1 << 10, TRIANGLE,
  /*6 10 11*/ 1 << 5 | 1 << 9 | 1 << 10, TRIANGLE,
  /*7 10 11*/ 1 << 6 | 1 << 9 | 1 << 10, TRIANGLE,
  /*7 8 11*/ 1 << 6 | 1 << 7 | 1 << 10, TRIANGLE,
  /*7 8 12*/ 1 << 6 | 1 << 7 | 1 << 11, TRIANGLE,
  /*7 11 12*/ 1 << 6 | 1 << 10 | 1 << 11, TRIANGLE,
  /*8 11 12*/ 1 << 7 | 1 << 10 | 1 << 11, TRIANGLE,
  /*9 10 13*/ 1 << 8 | 1 << 9 | 1 << 12, TRIANGLE,
  /*9 10 14*/ 1 << 8 | 1 << 9 | 1 << 13, TRIANGLE,
  /*9 13 14*/ 1 << 8 | 1 << 12 | 1 << 13, TRIANGLE,
  /*10 13 14*/ 1 << 9 | 1 << 12 | 1 << 13, TRIANGLE,
  /*10 11 14*/ 1 << 9 | 1 << 10 | 1 << 13, TRIANGLE,
  /*10 11 15*/ 1 << 9 | 1 << 10 | 1 << 14, TRIANGLE,
  /*10 14 15*/ 1 << 9 | 1 << 13 | 1 << 14, TRIANGLE,
  /*11 14 15*/ 1 << 10 | 1 << 13 | 1 << 14, TRIANGLE,
  /*11 12 15*/ 1 << 10 | 1 << 11 | 1 << 14, TRIANGLE,
  /*11 12 16*/ 1 << 10 | 1 << 11 | 1 << 15, TRIANGLE,
  /*11 15 16*/ 1 << 10 | 1 << 14 | 1 << 15, TRIANGLE,
  /*12 15 16*/ 1 << 11 | 1 << 14 | 1 << 15, TRIANGLE,


  /* PLUS - 4 */
  /*2 5 6 7 10*/ 1 << 1 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 9, PLUS,
  /*3 6 7 8 11*/ 1 << 2 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 10, PLUS,
  /*6 9 10 11 14*/ 1 << 5 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 13, PLUS,
  /*7 10 11 12 15*/ 1 << 6 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 14, PLUS,

  /* VRECTANGLE - 23 */
  /*1 2 3*/ 1 << 0 | 1 << 1 | 1 << 2, VRECTANGLE,
  /*2 3 4*/ 1 << 1 | 1 << 2 | 1 << 3, VRECTANGLE,
  /*5 6 7*/ 1 << 4 | 1 << 6 | 1 << 6, VRECTANGLE,
  /*6 7 8*/ 1 << 5 | 1 << 6 | 1 << 7, VRECTANGLE,
  /*9 10 11*/ 1 << 8| 1 << 9 | 1 << 10, VRECTANGLE,
  /*10 11 12*/ 1 << 9 | 1 << 10 | 1 << 11, VRECTANGLE,
  /*13 14 15*/ 1 << 12 | 1 << 13 | 1 << 14, VRECTANGLE,
  /*14 15 16*/ 1 << 13 | 1 << 14 | 1 << 15, VRECTANGLE,

  /*1 2 3 5 6 7*/ 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6, VRECTANGLE,
  /*2 3 4 6 7 8*/ 1 << 1 | 1 << 2 | 1 << 3 | 1 << 5 | 1 << 6 | 1 << 7, VRECTANGLE,
  /*5 6 7 9 10 11*/ 1 << 4 | 1 << 5 | 1 << 6 | 1 << 8 | 1 << 9 | 1 << 10, VRECTANGLE,
  /*6 7 8 10 11 12*/ 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 11, VRECTANGLE,
  /*9 10 11 13 14 15*/ 1 << 8 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 13 | 1 << 14, VRECTANGLE, 
  /*10 11 12 14 15 16*/ 1 << 9 | 1 << 10 | 1 << 11 | 1 << 13 | 1 << 14 | 1 << 15, VRECTANGLE,

  /*1 2 3 4*/ 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3, VRECTANGLE,
  /*5 6 7 8*/ 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7, VRECTANGLE,
  /*9 10 11 12*/ 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11, VRECTANGLE,
  /*13 14 15 16*/ 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15, VRECTANGLE,
  
  /*1 2 3 4 5 6 7 8*/ 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7, VRECTANGLE,
  /*5 6 7 8 9 10 11 12*/ 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11, VRECTANGLE,
  /*0 10 11 12 13 14 15 16*/ 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15, VRECTANGLE,

  /*1 2 3 4 5 6 7 8 9 10 11 12*/ 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11, VRECTANGLE,
  /*5 6 7 8 9 10 11 12 13 14 15 16*/  1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 |1 << 12 | 1 << 13 | 1 << 14 | 1 << 15, VRECTANGLE, 


  /* HRECTANGLE - 23 */
  /*1 5 9*/ 1 << 0 | 1 << 4 | 1 << 8, HRECTANGLE,
  /*2 6 10*/ 1 << 1 | 1 << 5 | 1 << 9, HRECTANGLE,
  /*3 7 11*/ 1 << 2 | 1 << 6 | 1 << 10, HRECTANGLE,
  /*4 8 12*/ 1 << 3 | 1 << 7 | 1 << 11, HRECTANGLE,
  /*5 9 13*/ 1 << 4 | 1 << 8 | 1 << 12, HRECTANGLE,
  /*6 10 14*/ 1 << 5 | 1 << 9 | 1 << 13, HRECTANGLE,
  /*7 11 15*/ 1 << 6 | 1 << 10 | 1 << 14, HRECTANGLE,
  /*8 12 16*/ 1 << 7 | 1 << 11 | 1 << 15, HRECTANGLE,

  /*1 2 5 6 9 10*/ 1 << 0| 1 << 1| 1 << 4| 1 << 5| 1 << 8| 1 << 9, HRECTANGLE,
  /*2 3 6 7 10 11*/ 1 << 1| 1 << 2| 1 << 5| 1 << 6| 1 << 9| 1 << 10, HRECTANGLE,
  /*3 4 7 8 11 12*/ 1 << 2| 1 << 3| 1 << 6| 1 << 7| 1 << 10| 1 << 11, HRECTANGLE,
  /*5 6 9 10 13 14*/ 1 << 4| 1 << 5| 1 << 8| 1 << 9| 1 << 12| 1 << 13, HRECTANGLE,
  /*6 7 10 11 14 15*/ 1 << 5| 1 << 6| 1 << 9| 1 << 10| 1 << 13| 1 << 14, HRECTANGLE,
  /*7 8 11 12 15 16*/ 1 << 6| 1 << 7| 1 << 10| 1 << 11| 1 << 14| 1 << 15, HRECTANGLE,

  /*1 5 9 13*/ 1 << 0 | 1 << 4 | 1 << 8 | 1 << 12, HRECTANGLE,
  /*2 6 10 14*/ 1 << 1 | 1 << 5 | 1 << 9 | 1 << 13, HRECTANGLE,
  /*3 7 11 15*/ 1 << 2 | 1 << 6 | 1 << 10| 1 << 14, HRECTANGLE,
  /*4 8 12 16*/ 1 << 3 | 1 << 7 | 1 << 11 | 1 << 15, HRECTANGLE,

  /*1 2 5 6 9 10 13 14*/ 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 9 | 1 << 12 | 1 << 13, HRECTANGLE,
  /*2 3 6 7 10 11 14 15*/ 1 << 1 | 1 << 2 | 1 << 5 | 1 << 6 | 1 << 9 | 1 << 10 | 1 << 13 | 1 << 14, HRECTANGLE,
  /*3 4 7 8 11 12 15 16*/ 1 << 2 | 1 << 3 | 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11 | 1 << 14 | 1 << 15, HRECTANGLE,
  
  /*1 2 3 5 6 7 9 10 11 13 14 15*/ 1 << 0 | 1 << 4 | 1 << 8 | 1 << 12 | 1 << 1 | 1 << 5 | 1 << 9 | 1 << 13 | 1 << 2 | 1 << 6 | 1 << 10| 1 << 14, HRECTANGLE,
  /*2 3 4 6 7 8 10 11 12 14 15 16*/ 1 << 1 | 1 << 5 | 1 << 9 | 1 << 13 | 1 << 2 | 1 << 6 | 1 << 10| 1 << 14 | 1 << 3 | 1 << 7 | 1 << 11 | 1 << 15, HRECTANGLE




};



/**************************
 * Misc functions
 **************************/

/**
 * Returns the min number of known shapes needed to make a guess for
 * each shape type. Would be nice if C had hashes.
 */
uint8_t minshapes(uint16_t shape) {
  switch (shape) {
  case 0x01:
    return 3;
  case 0x02:
    return 2;
  case 0x04:
    return 2; // maybe 3?
  case 0x08: 
    return 2; // maybe 3?
  case 0x10:
    return 3;
  default:
    return 2;
  }
}


/**
 * Fills in the current state from the shapedata that was written to
 * the status device. This uses the epochtimeout to determine if data
 * is old. This should be called whenever the status device is written
 * to.
 *
 * !!!! does not handle case where epochTimeout is < 2 !!!!
 *
 *
 * @param ss is the current state
 * @param sd is what to merge into the current state
 * count for the nodes we have heard from and remove them
 */
void update_shape(shapedState_t *ss, shapedData_t* sd) {
  int i = 0;
  uint16_t finalcovered = ss->shapedData.coveredData;
  uint16_t finalvalid = ss->shapedData.nodeData;

  for (i = 0; i < MAX_NET_SIZE; ++i) {
    if (sd->nodeData & (1 << i)) { /* check the valid bit for new data */
      // I'm sure this can eb done in one line
      if (sd->coveredData & (1 << i)) { // set to the nodes data
	finalcovered = finalcovered | (1 << i); // covered
      } else {
	finalcovered = finalcovered & ~(1 << i); // not covered
      }
      finalvalid = finalvalid | (1 << i);  // set that we got data from the node
      ss->epochs[i] = ss->epochTimeout; // reset timeout since we heard from the node
    } else if (ss->epochs[i] == 1) {  /* otherwise we check the existing bit and epoch */
      /* times up, so remove the ith valid bit and data */
      finalcovered = finalcovered & ~(1 << i); 
      finalvalid = finalvalid & ~(1 << i); 
      ss->epochs[i] = 0;
    }// epochs are decremented only on finalize, so following does not
     // belong here, however, finalize is only called in the java
     // code, so in the TinyOS code, we read from the status device
     // every chance we get to keep everythign uptoday. So, the
     // epochTimeout should be set to about the #ofepochsyouwant *
     // #ofnodesingrid since we will be doing a 'finalie' with every
     // packet we hear
    else if (ss->epochs[i] > 0) {
      // decrement the counter for all the data we know about 
      ss->epochs[i]--;
    } 
    
  }
  ss->shapedData.coveredData = finalcovered;
  ss->shapedData.nodeData = finalvalid;
}



/**
 * Looks at the state and determins what shape it sees. It fill in
 * the value into the state.
 *
 * @param ss is the state
 */
void lookup_shape(shapedState_t *ss) {

  int i = 0;
  uint8_t shape = 0;
  uint8_t guess = 0;
  uint8_t numNodes = 0;
  uint16_t guessMask = 0;
  shapedData_t *sd = &ss->shapedData;

  for (i = 0; i < PATTERN_SIZE *2; i = i + 2 ) {
    if (patterns[i] == sd->coveredData) {
      shape = patterns[i+1];
      elog(LOG_NOTICE, "!!SHAPED!! -> found match %d", shape);
    }
  }
  ss->lastShape = shape;

  //
  // now fill in the guesses
  //

  // To make a guess, we need at least two bits on.
  for (i = 0; i < sizeof(uint16_t); ++i) {
    if (sd->nodeData & (1 << i)) {
      ++numNodes;
    }
  }
  

  // The mask is used to block out the bits from from the known
  // pattern of the nodes we have not heard from. In otherwords, we
  // only use the bits in the known patterns from the nodes we have
  // heard from.
  guessMask = sd->nodeData;

  for (i = 0; i< PATTERN_SIZE *2; i = i +2) {
    if ((patterns[i] & guessMask) == sd->coveredData &&
	patterns[i+1] != shape &&
	numNodes >= minshapes(patterns[i+1])) {

      guess |= patterns[i+1];
      elog(LOG_NOTICE, "Possible shape: %d ", patterns[i+1]);
    }
  }
  ss->lastGuess = guess;

}



/*********************************
 * Shaped status device callbacks
 *********************************/

/**
 * Printable-read shaped status device call back. Prints the current
 * state in human readable format
 *
 * @param ctx is the context which contains info about our state
 * @param buf is the emstar buffer which the result is written to
 */
int shaped_printme(status_context_t *ctx, buf_t *buf) {

  int i = 0;
  shapedState_t *ss = (shapedState_t *) sd_data(ctx);
  shapedData_t *sd = &ss->shapedData;

  elog(LOG_INFO, "SHAPED -> printing cd %x, nd %x, shape %x, epochTimeout %d", 
       sd->coveredData, sd->nodeData,
       ss->lastShape, ss->epochTimeout);

  bufprintf(buf, "Printing stored shape data\n");
  bufprintf(buf, "EpochTimeout: %d\n", ss->epochTimeout);

  bufprintf(buf, "Nodes        : ");
  for (i = 0; i < MAX_NET_SIZE; ++i) {
    bufprintf(buf,"%2d ", i+1);
  }
  bufprintf(buf, "\n");

  bufprintf(buf, "Covered Nodes: ");
  for (i = 0; i < MAX_NET_SIZE; ++i) {
    bufprintf(buf,"%2d ", ((1 << i) & sd->coveredData) > 0 ? 1 : 0);
  }
  bufprintf(buf, "\n");

  bufprintf(buf, "Known Nodes:   ");
  for (i = 0; i < MAX_NET_SIZE; ++i) {
    bufprintf(buf,"%2d ", ((1 << i) & sd->nodeData) > 0 ? 1 : 0);
  }
  bufprintf(buf, "\n");

  bufprintf(buf, "Epochs     :   ");
  for (i = 0; i < MAX_NET_SIZE; ++i) {
    bufprintf(buf,"%2d ", ss->epochs[i]);
  }
  bufprintf(buf, "\n");


  bufprintf(buf, "Last Shape: %d\n", ss->lastShape);

  bufprintf(buf, "Last Guesses: %d\n", ss->lastGuess);

  bufprintf(buf, "\n");
  return STATUS_MSG_COMPLETE;

}



/**
 * Binary-read shaped status device call back. This is what gets
 * called when the TinyDB SHAPE aggregate does a finalize.
 * 
 * @param ctx is the context which contains info about our state
 * @param buf is the emstar buffer which the result is written to
 */
int shaped_finalize(status_context_t *ctx, buf_t *buf) {

  shapedState_t *ss = (shapedState_t *) sd_data(ctx);
  uint8_t res[2];
  lookup_shape(ss);
  res[0] = ss->lastShape;
  res[1] = ss->lastGuess;
  elog(LOG_NOTICE, "SHAPED -> finialize2 %d, guess %d", ss->lastShape, ss->lastGuess);
  bufcpy(buf, &res, sizeof(uint8_t) *2);

  return STATUS_MSG_COMPLETE;
}



/**
 * Write shaped status device call back. When the TinyOS SHAPE
 * aggergate does a merge/update/finalize, it will write the current
 * state it knows to the status device. We update our local state
 * accordingly.
 *
 * @param ctx is the context which contains info about our state
 * @param command is the bytes written to the device
 * @param buf_size is the about of bytes written to the device
 */
int shaped_write(status_context_t *ctx, char *command, size_t buf_size) {
  shapedData_t sd;
  shapedState_t *ss = (shapedState_t *) sd_data(ctx);
  elog(LOG_INFO, "SHAPED -> write before: v: %x, i: %x", ss->shapedData.coveredData, ss->shapedData.nodeData);
  memcpy(&sd, command, buf_size);

  // update the local state
  update_shape(ss, &sd);

  elog(LOG_INFO, "SHAPED ->  write after: v: %x, i: %x", ss->shapedData.coveredData, ss->shapedData.nodeData);


  return STATUS_WRITE_DONE;
}



/**********************************
 * Shaped command device callbacks
 **********************************/

/**
 * Command device callback used to change the setting of the
 * epochtimeout.
 *
 * @param cmdline is the command string
 * @param size is the size of the string
 * @param data is a pointer to the state
 * @returns EVENT_RENEW or EVENT_DONe
 */
int shaped_command(char *cmdline, size_t size, void *data) {
  int i = 0;
  shapedState_t *ss = (shapedState_t *) data;
  int val = atoi(cmdline);
  if (val <= 0 || val > 255) {
    elog(LOG_WARNING, "Invalud value %d for epoch timeout\n", val);
    return EVENT_RENEW;
  }
  ss->epochTimeout = val;

  // reset the overly large epochs
  for (i = 0; i < MAX_NET_SIZE; ++i) {
    if (ss->epochs[i] > val) {
      ss->epochs[i] = val;
    }
  }

  return EVENT_RENEW;
}

/**
 * Display the usage information for the command device used to change
 * the settings of teh epochTimeout.
 *
 * @param data is a pointer to the state
 * @returns a pointer to the usage string
 */
char *shaped_command_usage(void *data) {
  static char buf[80];
  shapedState_t *ss = (shapedState_t *) data;
  sprintf(buf, "Current epochTimeout is %d\nWrtie new value >= 2 to the device\n", ss->epochTimeout);
  return buf;
}


/******************
 * Init functions 
 ******************/

/**
 * Called on shutdown to cleanup. Nothing to do yet (or ever?).
 */
void shaped_shutdown(void *data) {
  elog(LOG_NOTICE, "shaped shutting down!");
}

/**
 * Main. Init misc and emrun stuff. Init the status device. Init the
 * command device, enter the event loop.
 */
int main(int argc, char** argv) {


  shapedState_t shapedState = {
    epochTimeout: 25 // see comment in update_shape() ... this is not
		     // quite what it seems
  };

  status_dev_opts_t stat_opts = {
    device: {
      devname: SHAPED_STATUSDEVICE,
      device_info: &shapedState
    },
    //    open:,
    //    close:,
    printable: shaped_printme,
    binary: shaped_finalize,
    //    ioctl:,
    write: shaped_write
  };

  cmd_dev_opts_t cmd_opts = {
    device: {
      devname: SHAPED_COMMANDDEVICE,
      device_info: &shapedState
      //      destory: shaped_command_destroy
    },
    command: shaped_command,
    usage: shaped_command_usage
  };
    
  emrun_opts_t emrun_opts = {
    shutdown: shaped_shutdown,
  };
  
  misc_init(&argc, argv, CVSTAG);


  if (g_status_dev(&stat_opts, &shaped_status) < 0) {
    elog(LOG_CRIT, "Unable to create shaped status device!");
    return 1;
  }

  if (g_command_dev(&cmd_opts, &shaped_command_ctx) < 0) {
    elog(LOG_CRIT, "Unable to create shaped command device!");
    return 1;
  }

  emrun_init(&emrun_opts);

  g_main();

  elog(LOG_ALERT, "shaped terminated abnormally");
  return 1;

}
