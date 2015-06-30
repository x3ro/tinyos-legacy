/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

#ifndef RATE_CONT
#define RATE_CONT

#include "Neigh.h" 

enum { 
    AM_ROUTEBEACONMSG = 250,
};



/* Mode of IFRC */ 

enum {
    START = 0,  // Slow start 
    AI  = 1,    // Additive Increase 
    HALF = 2,   // Congested 
    FOURTH = 3, // Even more congested 
    EIGHTH = 4, // And so on .. 
    SIXTEEN = 5,
    NONE   = 6,
};



/* Size of the Array used to store
 * packets that need to be forwarded
 */
enum { 
    /* Size of the buffer that stores 
     * packet that need to be forwarded
     */
    //FWDMSG_BUFF = 32,
    /* Min and Max threshold for the queue */

#ifndef PARAM_MINTHR
#define PARAM_MINTHR 4
#endif
    MINTHR = PARAM_MINTHR,
    
#ifndef PARAM_MAXTHR
#define PARAM_MAXTHR 8
#endif
    MAXTHR = PARAM_MAXTHR,
    
    /* This decides the increment over MAXTHR
     * that leads to mode change. Currently when 
     * the queue size is *increasing*
     * q_{avg} < MAXTHR       mode = AI
     * q_{avg} > MAXTHR       mode = HALF
     * q_{avg} > MAXTHR+INC   mode = FOURTH
     * q_{avg} > MAXTHR+3*INC/2   mode = EIGHT
     * q_{avg} > MAXTHR+7*INC/4   mode = EIGHT  reset rLocal to DELTA
     */
#ifndef PARAM_INC
#define PARAM_INC 8
#endif
    INC    = PARAM_INC,
};

 


enum { 
    LOWERTHRESH = MINTHR,
    UPPERTHRESH0 = MAXTHR, 
    UPPERTHRESH1 = MAXTHR + INC, 
    UPPERTHRESH2 = MAXTHR + INC + INC/2, 
    UPPERTHRESH3 = MAXTHR + INC + INC/2 + INC/4,
};


#ifndef MDFACTOR
#define MDFACTOR 0.5
#endif




/* Delta is the amount by which the rLocal value
 * is increase. INITVAL is the intial value of rLocal.
 */
#ifndef PARAM_DELTA
#define PARAM_DELTA 2000
#endif
#define DELTA PARAM_DELTA

#define INITVAL    (BANDWIDTH/100)
#define INFINITY   (2*BANDWIDTH)




#endif 
