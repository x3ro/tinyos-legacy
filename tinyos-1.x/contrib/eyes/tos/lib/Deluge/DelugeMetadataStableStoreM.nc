/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Storing Deluge's Metadata in the internal msp430 information segments
 * instead of using the external flash.
 * METADATA_STARTADR must be chosen very carefully, not to overwrite 
 * data in the internal Flash.
 */
/* - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2004/09/20 15:41:46 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */  

module DelugeMetadataStableStoreM {
  provides {
    interface DelugeMetadataStableStore as MetadataStableStore;
  }
  uses interface InternalFlash;
}

implementation {

  enum {
    METADATA_STARTADR = 0x00 // 0x00 - 0x50 is currently safe
  };
  
  command result_t MetadataStableStore.getMetadata(DelugeMetadata* metadata) {
    result_t res = call InternalFlash.read(METADATA_STARTADR, metadata, sizeof(DelugeMetadata));
    signal MetadataStableStore.getMetadataDone(res);
    return res;
  }

  command result_t MetadataStableStore.writeMetadata(DelugeMetadata* metadata) {
    result_t res = call InternalFlash.write(METADATA_STARTADR, metadata, sizeof(DelugeMetadata));
    signal MetadataStableStore.writeMetadataDone(res);
    return res;
  }
}
