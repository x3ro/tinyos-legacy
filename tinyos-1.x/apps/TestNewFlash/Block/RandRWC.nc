/* $Id: RandRWC.nc,v 1.1 2005/07/11 23:27:38 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author David Gay
 */
configuration RandRWC { }
implementation {
  components RandRW, BlockStorageC, Main, LedsC;

  enum { ID = unique("StorageManager") };

  Main.StdControl -> RandRW;
  RandRW.Mount -> BlockStorageC.Mount[ID];
  RandRW.BlockRead -> BlockStorageC.BlockRead[ID];
  RandRW.BlockWrite -> BlockStorageC.BlockWrite[ID];
  RandRW.Leds -> LedsC;
}
