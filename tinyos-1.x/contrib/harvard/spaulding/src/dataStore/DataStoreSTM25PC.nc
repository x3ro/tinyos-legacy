/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**
 * Interface for the data store module.  Inserted chunks are copied for internal storage.
 * Requests must supply a buffer where to copy the content in.  This in necessare because
 * the requested chunks may reside in flash. 
 * 
 * @author Konrad Lorincz
 * @version 1.0 - April 20, 2005
 */
#include "PrintfUART.h"
#include "DataStoreSTM25PPrivate.h"

configuration DataStoreSTM25PC 
{
    provides interface StdControl;
    provides interface DataStore; 
} 
implementation 
{
    components DataStoreSTM25PM as DataStoreM, LedsC;
    components BlockStorageC, FormatStorageC;
    components new QueueM(Request, REQUEST_QUEUE_SIZE) as RequestQueueM;
    DataStoreM.RequestQueue -> RequestQueueM;

    components ErrorToLedsC;

    StdControl = DataStoreM;
    DataStore = DataStoreM;

    DataStoreM.Leds -> LedsC; 


    DataStoreM.FormatStorage -> FormatStorageC;
    DataStoreM.ErrorToLeds -> ErrorToLedsC;

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_0]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_0];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_0]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_0];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_0]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_0];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_0] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_0];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_1]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_1];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_1]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_1];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_1]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_1];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_1] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_1];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_2]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_2];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_2]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_2];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_2]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_2];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_2] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_2];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_3]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_3];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_3]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_3];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_3]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_3];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_3] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_3];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_4]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_4];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_4]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_4];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_4]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_4];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_4] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_4];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_5]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_5];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_5]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_5];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_5]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_5];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_5] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_5];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_6]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_6];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_6]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_6];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_6]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_6];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_6] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_6];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_7]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_7];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_7]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_7];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_7]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_7];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_7] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_7];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_8]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_8];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_8]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_8];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_8]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_8];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_8] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_8];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_9]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_9];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_9]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_9];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_9]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_9];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_9] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_9];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_10]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_10];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_10]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_10];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_10]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_10];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_10] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_10];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_11]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_11];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_11]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_11];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_11]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_11];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_11] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_11];

    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_12]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_12];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_12]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_12];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_12]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_12];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_12] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_12];
#if DS_NBR_VOLUMES >= 14
    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_13]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_13];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_13]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_13];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_13]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_13];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_13] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_13];
#if DS_NBR_VOLUMES >= 15
    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_14]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_14];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_14]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_14];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_14]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_14];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_14] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_14];
#if DS_NBR_VOLUMES >= 16
    DataStoreM.BlockRead[DS_PARAM_VOLUME_ID_15]    -> BlockStorageC.BlockRead[DS_PARAM_VOLUME_ID_15];
    DataStoreM.BlockWrite[DS_PARAM_VOLUME_ID_15]   -> BlockStorageC.BlockWrite[DS_PARAM_VOLUME_ID_15];
    DataStoreM.Mount[DS_PARAM_VOLUME_ID_15]        -> BlockStorageC.Mount[DS_PARAM_VOLUME_ID_15];
    DataStoreM.StorageRemap[DS_PARAM_VOLUME_ID_15] -> BlockStorageC.StorageRemap[DS_PARAM_VOLUME_ID_15];
#endif
#endif
#endif
           
}
