/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */

module RipsDataStoreM
{
    provides
    {
        interface RipsDataStore;
	    interface DataCommand as ParamsSetCommand;
	    interface DataCommand as ChannelsSetCommand;
	    interface IntCommand as ParamsGetCommand;
	    interface IntCommand as ChannelsGetCommand;
    }
}

implementation
{
    /*               CHANNELS                    */
    int8_t channels[CHANNELS_NUM] = {-61,60,-54,41,40,31,23,17,15,3,2,-60,59,-53,-42,-33,-25,-19,-17,-5,-2,-1};
    command void ChannelsSetCommand.execute(void *data, uint8_t length)
	{
        memcpy(channels, data, sizeof(channels));
        signal ChannelsSetCommand.ack(1);
    }
    command void *RipsDataStore.getChannels(){
        return channels;
    }
    command void ChannelsGetCommand.execute(uint16_t param){
        if (param >= CHANNELS_NUM)
            signal ParamsGetCommand.ack(0);
        signal ChannelsGetCommand.ack(channels[param]);
    }


    /*               PARAMS                    */
    struct DataCollectionParams params = {1, 1, 53, 350, 3, 40, -40, -60, 5, 24, 2, 19, -55, 6};
    command void ParamsSetCommand.execute(void *data, uint8_t length)
	{
        memcpy(&params, data, sizeof(struct DataCollectionParams));
        signal ParamsSetCommand.ack(1);
    }
    command void *RipsDataStore.getParams(){
        return &params;
    }
    command void ParamsGetCommand.execute(uint16_t param){
        if (param >= sizeof(struct DataCollectionParams))
            signal ParamsGetCommand.ack(0);
        signal ParamsGetCommand.ack(((uint8_t*)&params)[param]);
    }

    /*               SYNC PACKET                    */
    struct SyncPacket syncPacket;
    command void *RipsDataStore.getSyncPacket(){
        return &syncPacket;
    }

    /*               MEASUREMENT SETUP                    */
    command void *RipsDataStore.getMeasurementSetup(){
        return &syncPacket;
    }

    /*               ROUTING_BUFFER                       */
    uint8_t routingBuffer[ROUTING_BUFF_SIZE];
    command void *RipsDataStore.getRoutingBuffer(){
        return routingBuffer;
    }
    command uint16_t RipsDataStore.getRoutingBufferSize(){
        return ROUTING_BUFF_SIZE;
    }
}

