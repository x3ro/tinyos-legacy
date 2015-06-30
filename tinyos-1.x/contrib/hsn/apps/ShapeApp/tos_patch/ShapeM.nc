// $Id: ShapeM.nc,v 1.1 2004/12/31 20:08:22 yarvis Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Implements SHAPE aggregate. Used Eugene Shvets SUM and MAX
 * aggergate as a template.
 *
 * Author:	Martin Lukac
 * @author Martin Lukac
 *
 */
includes Aggregates;
//includes TinyDB;
#ifdef PLATFORM_EMSTAR
includes shaped;
#endif

module ShapeM {
  provides {
    interface Aggregate;
  }
}

implementation {

  command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
    ShapeData *dest  = (ShapeData *)destdata;
    ShapeData *merge = (ShapeData *)mergedata;
	  
#ifdef PLATFORM_EMSTAR
    dest->value = merge->value | dest->value;
    dest->ids = merge->ids | dest->ids;
    shapedclient_write(dest->value, dest->ids); // do anything on error?
    shapedclient_read(&(dest->shape), &(dest->guess));
    printf("Merging m: %x, r: %x\n", merge->value, dest->value);
    printf("Merge: IDs m: %x, r: %x, shape: %d, guess: %d\n", merge->ids, dest->ids, dest->shape, dest->guess);fflush(stdout);
#else
    dest->value = merge->value | dest->value;
    dest->ids = merge->ids | dest->ids;
    dest->shape = merge->shape | dest->shape;
    dest->guess = merge->guess | dest->guess;
#endif	
    return SUCCESS;
  }
	
  //we'll probably get rid of this later
  command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
    ShapeData *dest  = (ShapeData *)destdata;
    int16_t val = *(int16_t *)value;
    if (TOS_LOCAL_ADDRESS <= 16 && TOS_LOCAL_ADDRESS > 0) {
      dest->value = (val << (TOS_LOCAL_ADDRESS -1)) | dest->value;
      dest->ids = 1 << (TOS_LOCAL_ADDRESS -1);
    }
#ifdef PLATFORM_EMSTAR
    // do this here to keep the service up to date
    shapedclient_write(dest->value, dest->ids); // do anything on error?
    shapedclient_read(&(dest->shape), &(dest->guess));
    printf("update: IDs v: %x, i: %x, shape: %d, guess: %d\n", dest->value, dest->ids, dest->shape, dest->guess);fflush(stdout);
#endif
    return SUCCESS;
  }

  //doubles as startEpoch right now? might separate the two
  command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
    ShapeData *mydata = (ShapeData *)data;
#ifdef PLATFORM_EMSTAR
    if (isFirstTime) {
      shapedclient_write(0, 0); // do anything on error?
    }
#endif
    mydata->value = 0;
    mydata->ids = 0;
    mydata->shape = 0;
    mydata->guess = 0;
    return SUCCESS;
  }
	
  command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
    return sizeof(ShapeData);
  }
	
  command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
    return TRUE;
  }
	
  command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
    ShapeData *mydata = (ShapeData *)data;
#ifdef PLATFORM_EMSTAR
    shapedclient_read(&mydata->shape, &mydata->guess);
    //	  *(int16_t *)result_buf = shapedclient_read();
    //	  mydata->shape = *(int16_t *)result_buf;
    printf("finalize IDs v: %x, i: %x, shape: %d\n", mydata->value, mydata->ids, mydata->shape);fflush(stdout);
#endif	
    ((uint8_t *)result_buf)[0] = mydata->shape;
    ((uint8_t *)result_buf)[1] = mydata->guess;

    return err_NoError;
  }
	
  command AggregateProperties Aggregate.getProperties() {
    // I think having these here is correct. I'm not sure they are all
    // used yet even. 
    return kEXEMPLARY_PROPERTY | kMONOTONIC_PROPERTY | kDUPLICATE_INSENSITIVE_PROPERTY;
  }
}


		
		
		
		
		   






