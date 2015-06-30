// Methods to read parameters from internal EEPROM
//
// Copyright (c) 2004 by Sensicast, Inc.
// All rights including that of resale granted to Crossbow, Inc.
//
// Permission to use, copy, modify, and distribute this software and its
// documentation for any purpose, without fee, and without written
// agreement is hereby granted, provided that the above copyright
// notice, the (updated) modification history and the author appear in
// all copies of this source code.
//
// Permission is also granted to distribute this software under the
// standard BSD license as contained in the TinyOS distribution.
//
// @Author: Michael Newman
//
#define InternalEEPROMedit 1
//
// Modification History:
//  22Jan04 MJNewman 1: Created.
/**
 * Provide access to the internal EEPROM.
 *
 * <code>ReadData</code> and <code>WriteData</code> provides
 * straightforward data reading and writing at arbitrary offsets in a flash
 * region. The <code>WriteData</code> interface guarantees that the data
 * has been committed to the flash when the <code>writeDone</code> event
 * completes successfully. 
 *
 * @author Michael Newman
 */
configuration InternalEEPROMC {
  provides {
    interface WriteData;
    interface ReadData;
    interface StdControl;
  }
}
implementation {
  components InternalEEPROMM;

  WriteData = InternalEEPROMM;
  ReadData = InternalEEPROMM;
  StdControl = InternalEEPROMM;
  
}
