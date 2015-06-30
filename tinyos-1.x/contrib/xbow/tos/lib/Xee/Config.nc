// Interface to Storage routines. These are provided for each parameter by
// the application that defines storage for and uses the parameter.
// These routines get and set the in memory instance of the
// parameter value. They are called from the EEprom code.
//
// Copyright (c) 2004 by Sensicast, Inc. All rights reserved.
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
#define ConfigEdit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.

interface Config
{
    // Get the in memory value of the parameter, place it in the buffer.
    // Calling get with a NULL buffer and any size is allowed, this is
    // used to obtain the size of the in memory parameter.
    //
    // If the parameter size is larger than the buffer only the
    // number of bytes specified in size are actually written to the
    // buffer. 
    //
    // Inputs:
    //	pBuffer		pointer to buffer to copy the data to
    //	size		number of bytes available in the buffer
    // Returns:
    //    Data has been placed in buffer. The size returned is
    //    always the same and reflects the size of the parameter.
    //    A size of 0 is returned if the parameter is not in use.
    //    This occurs when there is no in memory representation.
    command size_t get(void *pBuffer, size_t size);

    // set the in memory value of a parameter. Normally called when a
    // parameter is recovered from flash memory.
    //
    // Inputs:
    //	pBuffer		pointer to buffer to copy the data to
    //	size		number of bytes of data provided
    //			in the buffer (recovered from flash)
    // Returns:
    //	SUCCESS when the parameter was written to memory.
    //	FAIL when the parameter was not written to memory. This
    //  can occur because of a validity check or because the number of
    //  bytes in the set call did not match the parameter size.
    command result_t set(void *buffer, size_t size);

}	
