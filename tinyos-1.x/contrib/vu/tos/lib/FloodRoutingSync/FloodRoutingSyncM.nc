/**
 *
 * FloodRoutingSync is an implementation of the Routing Integrated Time Synchronization (RITS) protocol.
 * RITS extends FloodRouting engine by aggregating time information into the data packets (e.g. local time
 * of an event) and converting the timing information from the local time of the sender to the receiver's
 * local time as the packets are routed in the network. If converge cast is used towards base station, the 
 * base station can convert event times of all received packets into its local time.
 *
 * For more information on FloodRouting, please see FloodRoutingM.nc.
 *
 *   @author Miklos Maroti
 *   @author Brano Kusy, kusy@isis.vanderbilt.edu
 *   @modified Jan05 doc fix
 */

includes FloodRoutingSyncMsg;
includes Timer;
#include <string.h>

module FloodRoutingSyncM
{
    provides
    {
        interface StdControl;
        interface FloodRouting[uint8_t id];
        interface TimeStamp;
    }
    uses
    {
        interface FloodingPolicy[uint8_t id];
        interface SendMsg;
        interface ReceiveMsg;
        interface Timer;
        interface StdControl as SubControl;
        interface Leds;
        interface TimeStamping; // for the GLOBAL_TIMING-BRANO
#ifdef LOGICAL_IDS
        interface IDs;
#endif
    }
}

implementation
{
    /**
    * Block is an encapsulation of data packet that is routed.
    * Blocks are stored sequentially in a buffer that the user of FloodRouting
    *   provides.
    */
    struct block
    {
        uint8_t priority;   // lower value is higher priority
        uint8_t timeStamp[TIMESTAMP_LENGTH];    //time information is stored in the packet
        uint8_t data[0];    // the packet data of length dataLength
    };

    /**
    * States of the desc->dirty flag in the struct descriptor.
    * dirty flag contains information for all blocks in the buffer;
    * allows for optimization in routing engine - can skip the whole
    *   descriptor, no need to visit all blocks in the descriptor
    */
    enum
    {
        DIRTY_CLEAN = 0x00, // no action is needed for this descriptor
        DIRTY_AGING = 0x01, // only aging is required, no sending
        DIRTY_SENDING = 0x03,   // some packets are ready to be sent
    };

    /**
    * Descriptor is a logical structure which we build on top of a buffer (
    *   a 'chunk of data' provided by user), each parametrized FloodRouting
    *   interface has one descriptor.
    *   buffer is structured the following way: the first 10 bytes is a header and
    *   the next bytes are sequentially stored data packets (called blocks).
    *   sequential representation of blocks saves space, to be able to access the blocks,
    *   we use the fact that blocks have uniform size (blockLength), and we store
    *   a pointer to the first block (blocks) and to the last block(blocksEnd).
    */
    struct descriptor
    {
        uint8_t appId;      // comes from parametrized FloodRouting interface
        struct descriptor *nextDesc;// allows to go through multiple buffers
        uint8_t dataLength;     // size of a data packet in bytes (i.e. size of block.data)
        uint8_t uniqueLength;   // size of unique part of data a packet in bytes
        uint8_t blockLength;    // dataLength + 1, where 1 is a size of priority field
        uint8_t maxDataPerMsg;  // how many packets can fit in the buffer
        uint8_t dirty;      // common information about states of all blocks 
        struct block *blocksEnd;// pointer to the last block in the descriptor
        struct block blocks[0]; // pointer to the first block in the descriptor
    };
    
    /** 
    * Descriptors are stored as a linked list.
    */
    struct descriptor *firstDesc;

    /** 
    * Find descriptor for a specific parametrized interface.
    */
    struct descriptor *getDescriptor(uint8_t appId)
    {
        struct descriptor *desc = firstDesc;
        while( desc != 0 )
        {
            if( desc->appId == appId )
                return desc;

            desc = desc->nextDesc;
        }
        return 0;
    }

    /**
    * Return the next block in the descriptor.
    */
    static inline struct block* nextBlock(struct descriptor *desc, struct block* blk)
    {
        return (struct block*)(((void*)blk) + desc->blockLength);
    }

    /**
    * Returns match or block with lowest priority (set to 0xFF).
    */
    struct block *getBlock(struct descriptor *desc, uint8_t *data)
    {
        struct block *blk = desc->blocks;
        struct block *selected = blk;

        do
        {
            if( blk->priority != 0xFF
                && memcmp(blk->data, data, desc->uniqueLength) == 0 )
                return blk;

            if( blk->priority > selected->priority )
                selected = blk;

            blk = nextBlock(desc, blk);
        } while( blk < desc->blocksEnd );

        selected->priority = 0xFF;
        return selected;
    }

    TOS_Msg rxMsgData, txMsg;
    TOS_MsgPtr rxMsg;

    /* 
    * There are three concurrent activities, that routing engine performs.
    *  (1) sending of packets, 
    *  (2) processing of a received msg, and
    *  (3) aging of packets
    */
    uint8_t state;
    enum
    {
        STATE_IDLE = 0x00,
        STATE_SENDING = 0x01,
        STATE_PROCESSING = 0x02,
        STATE_AGING = 0x04,
    };
    
    // see selectData comments
    struct block freeBlock = { 0xFF };
    
    /**
    * Selects blocks for transmission from desc and stores them in selection. 
    *   selection buffer is provided by caller.
    *    blocks are selected based on priority.
    *    blocks are sorted in decreasing order (priority field) in selection.
    */
    void selectData(struct descriptor *desc, struct block **selection)
    {
        uint8_t maxPriority = 0xFF;
        struct block *blk = desc->blocks;
        struct block **s = selection + desc->maxDataPerMsg;
        struct block stopBlock = { 0x00 };

        // the blocks in selection are in decreasing order, initialization:
        //  - the last block has highest priority (0x00)
        //  - all other blocks have lowest priority (0xFF)
        //  - free Block needs to be a global variable, since if there is 
        //  less to be transmitted packets in desc, than the maximum we
        //  can fit to the FloodRouting message, selection would point
        //  to non-existent data after returning
        *s = &stopBlock;
        do
            *(--s) = &freeBlock;
        while( s != selection );

        // go through all blocks in desc, find the highest priority block
        // and insert them in selection in decreasing order
        do
        {
            uint8_t priority = blk->priority;
            //only block with even priority can be transmitted
            //see FloodingPolicy.nc for more details
            if( (priority & 0x01) == 0 && priority < maxPriority )
            {
                s = selection;
                while( priority < (*(s+1))->priority )
                {
                    *s = *(s+1);
                    ++s;
                }

                *s = blk;
                maxPriority = (*selection)->priority;
            }

            blk = nextBlock(desc, blk);
        } while( blk < desc->blocksEnd );
    }

    /**
    * Creates FloodRoutingSync message by copying selection of blocks into the message.
    *    selection provides blocks in the decreasing order, the last
    *     block having the highest priority, that's why we want to 
    *     start copying data from the end of selection.
    *    !!! as opposed to FloodRouting, FLOODROUTING_DEBUG does not work with 
    *    FloodRoutingSync
    *    copyData() will be called after selectData().
    */
    void copyData(struct descriptor *desc, struct block **selection)
    {
        struct block **s = selection + desc->maxDataPerMsg;
        uint8_t *data = ((FloodRoutingSyncMsg*)txMsg.data)->data;

        while( s != selection && (*(--s))->priority != 0xFF )
        {
            memcpy(data, (*s)->data, desc->dataLength);
            //timestamp needs to be copied to the message as well
            memcpy(data + desc->dataLength , (*s)->timeStamp, TIMESTAMP_LENGTH);
            //dataLength is length of data packet, timestamp is transmitted as well
            data += desc->dataLength + TIMESTAMP_LENGTH;
        }

        ((FloodRoutingSyncMsg*)txMsg.data)->appId = desc->appId;
        ((FloodRoutingSyncMsg*)txMsg.data)->location = call FloodingPolicy.getLocation[desc->appId]();
        txMsg.length = data - ((uint8_t*)txMsg.data);
    }

    /**
    *  Task sendMsg() goes through the descriptions list and schedules radio messages for transmission.
    *   first a buffer is created, where the selected blocks will be stored, then for each
    *   description, we call selectData() (puts blocks into the selection buffer) and
    *   copyData() (copies selection blocks into a radio message).
    *   we transmit 1 TOSMSG containing the first blocks found in the first descriptor
    *   that had at least one block to be sent, 1 msg contains only blocks from 1 descriptor.
    *   if at least one block from a descriptor is transmitted, desc->dirty is set to aging.
    *  The only extension to FloodRouting is making sure the timestamp will be added at the 
    *  message transmission.
    */
    task void sendMsg()
    {
        // 1 + FLOODROUTINGSYNC_MAXDATA / 2 is the upper bound on the size of selection, 
        // assuming that the data part of each block is at least 1 byte long;
        // note that selection contains certain number blocks that are copied into
        // a radio message
        struct block *selection[1 + FLOODROUTINGSYNC_MAXDATA / 2];

        struct descriptor *desc = firstDesc;
        while( desc != 0 )
        {
            //if DIRTY_SENDING, then there exists at least one block that need to be
            //transmitted in desc
            if( desc->dirty == DIRTY_SENDING )
            {
                selectData(desc, selection);
                copyData(desc, selection);
                //txMsgdata->timeStamp will contain our local time at the transmission time, it
                //needs to be initialized to 0, see SysTimeStamping service
                ((FloodRoutingSyncMsg*)txMsg.data)->timeStamp = 0; 
#ifdef SIMULATE_MULTIHOP    // this is used to simulate multiple hops
                ((FloodRoutingSyncMsg*)txMsg.data)->nodeId= (uint8_t)(TOS_LOCAL_ADDRESS); 
#endif

                //if there is at least one block to be sent
                if( txMsg.length > FLOODROUTINGSYNC_HEADER )
                {
                    if( call SendMsg.send(TOS_BCAST_ADDR, txMsg.length, &txMsg) == SUCCESS )
                        // adding sender's timestamp to the message
                        call TimeStamping.addStamp2(&txMsg, offsetof(FloodRoutingSyncMsg,timeStamp));
                    else if (! post sendMsg() )
                        state &= ~STATE_SENDING;
                    
                    call Leds.redToggle();
                    return;
                }
            
                //we have sent at least one packet, this packet needs to be aged    
                desc->dirty = DIRTY_AGING;
            }
            desc = desc->nextDesc;
        }

        state &= ~STATE_SENDING;
    }

    /**
    * Upon successfull sending, we call task sendMsg() again, to transmit all the data which
    * are waiting to be transmitted.
    */
    task void sendMsgDone()
    {
        FloodRoutingSyncMsg *msg = (FloodRoutingSyncMsg*)txMsg.data;
        struct descriptor *desc = getDescriptor(msg->appId);

        if( desc != 0 )
        {
            //call policy.sent() on each of the transmitted blocks
            //this allows to update priority of the block according to the policy
            uint8_t *data = ((uint8_t*)txMsg.data) + txMsg.length;
            //dataLength is the length of data packet, timestamp is transmitted as well
            while( msg->data <= (data -= desc->dataLength + TIMESTAMP_LENGTH) )
            {
                struct block *block = getBlock(desc, data);
                if( block->priority != 0xFF )
                    block->priority = call FloodingPolicy.sent[desc->appId](block->priority);
            }
        }

        if( ! post sendMsg() )
            state &= ~STATE_SENDING;
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
    {
        if( success != SUCCESS )
        {
            if( ! post sendMsg() )
                state &= ~STATE_SENDING;
        }
        else
        {
            if( ! post sendMsgDone() )
                state &= ~STATE_SENDING;
        }

        return SUCCESS;
    }

    /**
    * updatedBlock variable stores the pointer to the last upadate block (in procMsg() task).
    * Consequently, we can provide application with the timestamp field of this block, if
    * TimeStamp.getStamp() is called from the FloodRouting.receive() event handler.
    */
    struct block* updatedBlock;
    
    /**
    * Blocks are extracted out from the received message and stored in routing
    * buffer, if the routing policy accepts the packet and the application that 
    * initialized FloodRouting accepts the packet as well(signal 
    * FloodRouting.receive[](data) == SUCCESS).
    * 
    * RITS requires to update timestamps of the data packets, right after they were
    * received. As we know, rxMsg.timeStamp contains the offset of times of the sender 
    * and the receiver. Also each data
    * packet is attached with a time - in the local time of sender. We want to convert
    * these packet-attached times into the local time of current mote. This can be done
    * by subtracting this offset from each packet-attached time. 
    **/
    task void procMsg()
    {
        FloodRoutingSyncMsg *msg = (FloodRoutingSyncMsg*)rxMsg->data;
        struct descriptor *desc = getDescriptor(msg->appId);
        call Leds.greenToggle();
        if( desc != 0 && call FloodingPolicy.accept[desc->appId](msg->location) )
        {
            uint8_t *data = ((uint8_t*)rxMsg->data) + rxMsg->length;
            while( msg->data <= (data -= desc->dataLength+TIMESTAMP_LENGTH) )
            {
                struct block *block = getBlock(desc, data);
                if( block->priority == 0xFF )
                {
                    uint32_t tmp1 = 0, tmp2 = 0;
                    // timing extension: block.TS contains local time of sender,
                    // we want it to convert this to the receiver's time.
                    // to do this we subtract offset of sender and receiver timestamps at
                    // transmission and reception of rxMsg from each block.TS.

                    //timestamp attached to the data in local time of the sender
                    memcpy(&tmp1, (data+desc->dataLength), TIMESTAMP_LENGTH);
                    //offset of sender and receiver
                    memcpy(&tmp2, &(((FloodRoutingSyncMsg*)rxMsg->data)->timeStamp), TIMESTAMP_LENGTH);
                    //conversion data timestamp to the local time of the current mote
                    tmp1 -= tmp2;
                    //copy the updated timestamp back into the block
                    memcpy(&(block->timeStamp), &tmp1, TIMESTAMP_LENGTH);
                    updatedBlock = block;

                    if( signal FloodRouting.receive[msg->appId](data) != SUCCESS ){
                        continue;
                    }
                    memcpy(block->data, data, desc->dataLength);
                    block->priority = 0x00;
                }
                block->priority = call FloodingPolicy.received[desc->appId](msg->location, block->priority);
            }

            desc->dirty = DIRTY_SENDING;
            if( (state & STATE_SENDING) == 0 && post sendMsg() )
                state |= STATE_SENDING;
        }

        state &= ~STATE_PROCESSING;
    }

    uint32_t msgTimeStamp;
    uint32_t msgSenderTimeStamp;
    /**
    * Routing message from a different mote is scheduled for processing.
    *  since the pointer p which we obtain in the receive event can not be used
    *   after we return from the event handler, and we need to take long time to
    *   process the received message (i.e. we post a task), we need to save the
    *   pointer to some local variable (rxMsg).
    * 
        * Timestamping extension requires rxMsg.timeStamp to contains offset of times of the sender and receiver.
        * The sender's timestamp taken at the transmission time of rxMsg is in rxMsg.timeStamp. The reciever's
        * timestamp can be obtained from the TimeStamping service. The offset can be computed 
    * by subtractin these two values, consequentelly, we write the offset back into rxMsg.timeStamp
    **/
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
    {
#ifdef SIMULATE_MULTIHOP    
        // this code can be used to simulate multiple hops, only the least significant 8 bits of TOS_LOCAL_ADDRESS  
        // are important and are assumed to have this format: 0xXY, where X,Y are coordinates of mote in 2D space
        uint8_t incomingID = ((FloodRoutingSyncMsg*)p->data)->nodeId;
        int8_t diff = (incomingID & 0x0F) - (TOS_LOCAL_ADDRESS & 0x0F);
#ifdef LOGICAL_IDS
        if( call IDs.IS_NEIGHBOR(call IDs.TOS2ID(TOS_LOCAL_ADDRESS),call IDs.TOS2ID(incomingID)) )
            diff = 0;
        else 
            diff = 17;
#else  //LOGICAL_IDS
        if( diff < -1 || diff > 1 )
            return p;
        
        diff = (incomingID & 0xF0) - (TOS_LOCAL_ADDRESS & 0xF0);
#endif //LOGICAL_IDS
        if( diff < -16 || diff > 16 )
            return p;
#endif //SIMULATE_MULTIHOP
        
        call Leds.yellowOn();
        if( (state & STATE_PROCESSING) == 0 )
        {
            TOS_MsgPtr t;

            // obtain the receiver's timestamp
            msgTimeStamp = call TimeStamping.getStamp();
            // obtain the sender's timestamp
            msgSenderTimeStamp = ((FloodRoutingSyncMsg*)(p->data))->timeStamp;
            // subtract the two to get offset
            ((FloodRoutingSyncMsg*)(p->data))->timeStamp -= msgTimeStamp;
            t = rxMsg;
            rxMsg = p;
            p = t;

            if( post procMsg() )
                state |= STATE_PROCESSING;
        }

        return p;
    }

    /**
    * Packets need to be aged, until they are thrown out from the buffer.
    *  moreover, after a packet has been aged, it may have to be resend (depending on
    *   the current policy), therefore we need to check for this and post a send task
    *   if it happens.
    *  dirty flag for desc is set to DIRTY_AGING, if there is at least one packet that
    *   needs to be aged, and set to DIRTY_SENDING if it needs to be sent().
    */
    task void age()
    {
        struct descriptor *desc = firstDesc;
        while( desc != 0 )
        {
            if( desc->dirty != DIRTY_CLEAN )
            {
                struct block *blk = desc->blocks;
                desc->dirty = DIRTY_CLEAN;
                do
                {
                    if( blk->priority != 0xFF )
                    {
                        blk->priority = call FloodingPolicy.age[desc->appId](blk->priority);

                        if( (blk->priority & 0x01) == 0 )
                            desc->dirty = DIRTY_SENDING;
                        else
                            desc->dirty |= DIRTY_AGING;
                    }
                    blk = nextBlock(desc, blk);
                } while( blk < desc->blocksEnd );

                if( desc->dirty == DIRTY_SENDING 
                        && (state & STATE_SENDING) == 0 
                        && post sendMsg() )
                    state |= STATE_SENDING;
            }
            desc = desc->nextDesc;
        }
        state &= ~STATE_AGING;
    }

    /**
    * Each timer event triggers aging of the blocks in descriptors.
    *  this may result in sending a radio message.
    */
    event result_t Timer.fired()
    {
        if( (state & STATE_AGING) == 0 && post age() )
            state |= STATE_AGING;

        return SUCCESS;
    }

uint32_t stored_ts;
uint8_t stored_id;
    // just remember time for later use
    command result_t TimeStamp.addStamp(uint32_t time, uint8_t id){
        stored_ts = time;
        stored_id = id;
        return SUCCESS;
    }

    /** Find the actual block in a descriptor based on the match of unique data
    *   part, the new block gets assigned 0x00 priority and is sent from a task.
    *   Timestamp needs to be retrieved and stored.
    */
    command result_t FloodRouting.send[uint8_t id](void *data)
    {
    struct descriptor *desc = getDescriptor(id);
        if( stored_id != id)
            return FAIL;

        if( desc != 0 )
        {
            struct block *blk = getBlock(desc, data);
            if( blk->priority == 0xFF )
            {
                memcpy(blk->data, data, desc->dataLength);
                memcpy(&(blk->timeStamp), &stored_ts, TIMESTAMP_LENGTH); //for global timing-BRANO

                blk->priority = 0x00;

                desc->dirty = DIRTY_SENDING;
                if( (state & STATE_SENDING) == 0 && post sendMsg() )
                    state |= STATE_SENDING;

                call Leds.yellowToggle();
                return SUCCESS;
            }
        }
        return FAIL;
    }

    command result_t FloodRouting.init[uint8_t id](uint8_t dataLength, uint8_t uniqueLength,
        void *buffer, uint16_t bufferLength)
    {
        struct block *blk;
        struct descriptor *desc;

        if( dataLength < 2 //dataLength is too small
            || dataLength > FLOODROUTINGSYNC_MAXDATA - TIMESTAMP_LENGTH //single packet does not fit in TOSMSG
            || uniqueLength > dataLength
            || bufferLength <= //single packet does not fit in the buffer
                sizeof(struct descriptor) + dataLength + TIMESTAMP_LENGTH
            || getDescriptor(id)!=0 ) //the descriptor for id already exists
            return FAIL;

        desc = (struct descriptor*)buffer;
        desc->appId = id;
        desc->dataLength = dataLength;
        desc->uniqueLength = uniqueLength;
        //block contains data (dataLength bytes), timestamp (TIMESTAMP_LENGTH bytes) and priority (1 byte)
        desc->blockLength = dataLength + TIMESTAMP_LENGTH + 1;
        desc->maxDataPerMsg = FLOODROUTINGSYNC_MAXDATA / (dataLength+TIMESTAMP_LENGTH);
        desc->dirty = DIRTY_CLEAN;

        buffer += bufferLength - (desc->blockLength-1); // this is the first invalid position
        blk = desc->blocks;
        while( (void*)blk < buffer )
        {
            uint32_t tmp=0;
            blk->priority = 0xFF;
            //timestamp init
            memcpy( &(blk->timeStamp), &tmp, TIMESTAMP_LENGTH);
            blk = nextBlock(desc, blk);
        }
        desc->blocksEnd = blk;
        
        desc->nextDesc = firstDesc;
        firstDesc = desc;

        return SUCCESS;
    }

    /** Just remove the descriptor from the linked list, the information is lost.
    *  stop() can not be undone (i.e. restarted).
    */
    command void FloodRouting.stop[uint8_t id]()
    {
        struct descriptor **desc = &firstDesc;
        while( *desc != 0 )
        {
            if( (*desc)->appId == id )
            {
                *desc = (*desc)->nextDesc;
                return;
            }
            desc = &((*desc)->nextDesc);
        }
    }

    command uint32_t TimeStamp.getStamp(){
        uint32_t tmp = 0;
        memcpy(&tmp, &(((struct block *)updatedBlock)->timeStamp), TIMESTAMP_LENGTH);   
        return tmp;
    }
    command uint32_t TimeStamp.getMsgStamp(){
        return msgTimeStamp;
    }
    command uint32_t TimeStamp.getMsgSenderStamp(){
        return msgSenderTimeStamp;
    }
    
    command uint8_t TimeStamp.getStampSize(){
        return TIMESTAMP_LENGTH;
    }

    default command uint16_t FloodingPolicy.getLocation[uint8_t id]() { return 0; }
    default command uint8_t FloodingPolicy.sent[uint8_t id](uint8_t priority) { return 0xFF; }
    default command result_t FloodingPolicy.accept[uint8_t id](uint16_t location) { return FALSE; }
    default command uint8_t FloodingPolicy.received[uint8_t id](uint16_t location, uint8_t priority) { return 0xFF; }
    default command uint8_t FloodingPolicy.age[uint8_t id](uint8_t priority) { return priority; }
    default event result_t FloodRouting.receive[uint8_t id](void *data) { return FAIL; }

    command result_t StdControl.init()
    {
        firstDesc = 0;
        rxMsg = &rxMsgData;
        txMsg.addr = TOS_LOCAL_ADDRESS;
        state = STATE_IDLE;
        stored_id = 255;

        return call SubControl.init();
    }
    
    command result_t StdControl.start()
    {
        call SubControl.start();
        call Timer.start(TIMER_REPEAT, 1024);   // one second timer
        call Leds.set(TIMESTAMP_LENGTH);
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        call Timer.stop();
        return SUCCESS;
    }
}
