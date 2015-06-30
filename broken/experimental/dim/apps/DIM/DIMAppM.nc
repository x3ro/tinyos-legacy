/*-*- mode: C++; -*-*/
/** 
 * The Index shim was removed.
 */
/**
 * 8/20/03: PIR was removed. PIR's interface and functionality
 *          need to be discussed with Young later.
 */
module DIMAppM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as DIMControl;
    interface Timer;
    interface Leds;
    interface AttrUse;
    interface Greedy;
    interface Zone;
#ifdef USEGTS
    interface GTS;
#endif
#ifdef QUICKGTS
    interface quickGTS;
#endif    
    //interface Random as SendJitter;
  }
}

implementation {
  TOS_Msg msgRecvQ[MAX_RECV_QLEN], msgSendQ[MAX_SEND_QLEN];
  uint8_t msgSendQHead, msgSendQTail;
  uint8_t msgRecvQHead, msgRecvQTail;

  uint8_t attrNum;
  AttrDescPtr attrDescPtr[MAX_ATTR_NUM];

  Coord myCoord;
  Code myCode;

  //uint16_t networkBound[4];

  uint8_t error;
  bool full;
  bool sendPosted, recvPosted;

  uint8_t tupleSize, querySize;

  bool dimCreated;

  uint8_t readyToSample;
  uint32_t samplePeriod;
  uint16_t curReading;
#ifdef USEGTS
  bool GTSBusy, GTSFound;
#endif
  //uint8_t tupleBuf[sizeof(GenericTuple) + MAX_ATTR_NUM * 2];
  uint8_t tupleBuf[32];
  GenericTuplePtr curTup;

  SchemaErrorNo schemaErrorNo;
  
  GenericQueryPtr qryPtr;
  uint8_t qryBuf[MAX_QUERY_BUF_LEN];
#ifdef USEGTS
  uint8_t pendQuery[MAX_QUERY_BUF_LEN];
  bool havePendQuery;
#endif

  //uint32_t replySeqNo;

  command result_t StdControl.init()
  {
    uint8_t i;
    
    msgSendQHead = msgSendQTail = 0;
    msgRecvQHead = msgRecvQTail = 0;
  
    attrNum = 0;
    for (i = 0; i < MAX_ATTR_NUM; i ++) {
      attrDescPtr[i] = NULL;
    }
    
    sendPosted = FALSE;
    recvPosted = FALSE;

    myCoord = Address[TOS_LOCAL_ADDRESS];

    full = FALSE;
    /*
    networkBound[0] = 0;
    networkBound[1] = MAXX;
    networkBound[2] = 0;
    networkBound[3] = MAXY;
    */
    call Leds.init();
    call DIMControl.init();

    error = 0;
    /*
    dbg(DBG_USR2, "sizeof(GreedyHeader) = %d\n", sizeof(GreedyHeader));
    dbg(DBG_USR2, "sizeof(GenericQuery) = %d\n", sizeof(GenericQuery));
    dbg(DBG_USR2, "sizeof(GenericTuple) = %d\n", sizeof(GenericTuple));
    */

    tupleSize = 0;
    querySize = 0;

    dimCreated = FALSE;

    readyToSample = 0xff;
    samplePeriod = 0;

    curTup = (GenericTuplePtr)tupleBuf;
    curTup->type = 'T';
    curTup->detector = TOS_LOCAL_ADDRESS;
    curTup->sender = TOS_LOCAL_ADDRESS;
    
    qryPtr = (GenericQueryPtr)qryBuf;

#ifdef USEGTS
    GTSBusy = FALSE;
    havePendQuery = FALSE;
    GTSFound = FALSE;
#endif

    //replySeqNo = 0;

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call DIMControl.start();
    //call Zone.init(myCoord, networkBound);
    call Zone.init(myCoord);
    call Timer.start(TIMER_REPEAT, IDLE_PERIOD);
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call DIMControl.stop();
    return SUCCESS;
  }

  void reportError()
  {
    uint16_t j;
    for (j=0; j<2; j++) {
      call Leds.redOn();
      call Leds.yellowOn();
      call Leds.greenOn();
#ifndef PLATFORM_PC
      {
         uint16_t i;
         for (i=0; i<1000; i++) {
            asm volatile ("sleep" ::);
         }
      }
#endif
      call Leds.redOff();
      call Leds.yellowOff();
      call Leds.greenOff();
#ifndef PLATFORM_PC
      {
         uint16_t i;
         for (i=0; i<1000; i++) {
             asm volatile ("sleep" ::);
         }
      }
#endif
    }

    if (error & 0x01) {
      call Leds.greenOn();
    }
    if (error & 0x02) {
      call Leds.yellowOn();
    }
    if (error & 0x04) {
      call Leds.redOn();
    }
  }

  task void stuffTuple();
  task void sendTuple();
  task void sending();

  event result_t Timer.fired()
  {
    if (error) {
      reportError();
      //call Timer.stop();
    } else {
      if (readyToSample == 0) {
        post stuffTuple();
      }
    }
    return SUCCESS;
  }
  
  task void stuffTuple() {
    uint8_t i = 0;
    
    if (readyToSample < attrNum) {
      for (i = 0; i < readyToSample; i ++) {
        if (attrDescPtr[i]->idx == attrDescPtr[readyToSample]->idx) {
          // Repeated attributes
          break;
        }
      }
      if (i < readyToSample) {
        // repeated attribute
        curTup->value[readyToSample] = curTup->value[i];
        atomic {
          readyToSample ++;
        }
        if (readyToSample < attrNum) {
          post stuffTuple();
        } else {
          post sendTuple();
        }
      } else {
        curReading = 0;
        if (call AttrUse.getAttrValue(attrDescPtr[readyToSample]->name, (char *)&curReading, &schemaErrorNo) == FAIL) {
          dbg(DBG_USR2, "Cannot fetch attribute %s!\n", attrDescPtr[readyToSample]->name);
          error = 2;
          readyToSample = 0xff;
        }
        if (schemaErrorNo == SCHEMA_RESULT_READY) {
          curTup->value[readyToSample] = curReading;
          atomic {
            readyToSample ++;
          }
          if (readyToSample < attrNum) {
            post stuffTuple();
          } else {
            post sendTuple();
          }
        }
      }
    }
  }

  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) 
  {
    if (errorNo != SCHEMA_RESULT_READY) {
      // Cannot fetch this attribute.
      dbg(DBG_USR2, "Cannot fetch attribute %s!\n", name);
      error = 2;
      readyToSample = 0xff;
    }
    curTup->value[readyToSample] = curReading;
    atomic {
      readyToSample ++;
    }
    if (readyToSample < attrNum) {
      post stuffTuple();
    } else {
      post sendTuple();
    }
    return SUCCESS;
  }

  event result_t AttrUse.startAttrDone(uint8_t id) {
    return SUCCESS;
  }

  task void sendTuple() {
    Code tupCode;
    Coord destCoord;
    
#ifdef DEBUG
    uint8_t i;
    char text[16];
#endif

    GreedyHeaderPtr gh;
    //uint32_t timestamp;
    
    curTup->queryId = 0;
    if (call AttrUse.getAttrValue("timelo", (char *)&(curTup->timelo), &schemaErrorNo) == FAIL) {
      dbg(DBG_USR2, "Cannot fetch attribute timelo\n");
      error = 2;
      return;
    }
    if (call AttrUse.getAttrValue("timehi", (char *)&(curTup->timehi), &schemaErrorNo) == FAIL) {
      dbg(DBG_USR2, "Cannot fetch attribute timehi\n");
      error = 2;
      return;
    }
#ifdef DEBUG
    dbg(DBG_USR2, "Generate Tuple: %c %hd %hd %hd %ld %ld :: ", 
                  curTup->type, curTup->queryId,
                  curTup->sender, curTup->detector, 
                  curTup->timelo, curTup->timehi);
    for (i = 0; i < attrNum; i ++) {
      dbg(DBG_USR2, "%s: %hd ", attrDescPtr[i]->name, curTup->value[i]);
    }
    dbg(DBG_USR2, "\n");
#endif          
    call Zone.encodeTuple(curTup, attrNum, &tupCode, FALSE);
#ifdef DEBUG
    call Zone.showCode(tupCode, text);
#endif
          
    //dbg(DBG_USR2, "ENCODE Tuple to zone [%s]\n", text);
#if 1
    if (tupCode.length == myCode.length && tupCode.word == myCode.word) {
      // Store the tuple in local storage.
            
      dbg(DBG_USR2, "LOCALLY STORE Tuple\n");
#ifdef USEGTS
      if (!GTSBusy) {
        atomic {
          GTSBusy = TRUE;
        }
        if (call GTS.store(curTup) == FAIL) {
          dbg(DBG_USR2, "Cannot store tuple!\n");
          error = 3;
        }
      } // otherwise, we have to ignore this tuple, but just for now.
#endif
#ifdef QUICKGTS
      if (call quickGTS.store(curTup) == FAIL) {
        dbg(DBG_USR2, "Cannot store tuple!\n");
        error = 3;
      }
#endif
    } else {
      // Send the tuple to a remote node.
      call Leds.greenToggle();

      call Zone.getAddress(tupCode, &destCoord);
#ifdef DEBUG
      dbg(DBG_USR2, "SEND Tuple to zone %s at (%d, %d)\n", text, destCoord.x, destCoord.y);
#endif
      // Enqueue
      if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
        // Sending queue is full.
        dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
      } else {
        atomic {
          gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
          msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
          msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
        }
        gh->mode_ = GREEDY;
        gh->src_addr_ = TOS_LOCAL_ADDRESS;
        gh->coord_ = destCoord;
        memcpy(gh->data_, curTup, tupleSize);
        if (!sendPosted) {
          sendPosted = TRUE;
          post sending();
        }
      }
    }
#endif
    readyToSample = 0;
  }

  void splitQuery(GenericQueryPtr q0, uint8_t *qset, uint8_t *qsetSize) 
  {
    Code q0Code;
    GenericQueryPtr qry;
    uint8_t i, j, qsetIdx;
#if 0
    uint8_t ii, jj;
#endif    
    uint16_t unit = 1024, kl, ku;
    uint8_t cursor;
    uint8_t mask = 1 << (sizeof(mask) * 8 - 1);

    qsetIdx = 0;
    
    q0Code.word = 0;
    q0Code.length = 0;
    for (i = 0; i < myCode.length; i ++) {
      j = i % attrNum;
      if (j == 0) {
        unit >>= 1;
      }
      cursor = myCode.word & mask;
      
      kl = q0->queryField[j].lowerBound/unit;
      ku = q0->queryField[j].upperBound/unit;

      if (kl == ku ||
          (kl < ku && !(q0->queryField[j].upperBound > ((kl + 1) * unit)))) {
        // Lower bound and upper bound fall into the same division segment.
        if (kl % 2 == 0) {
          q0Code.word <<= 1;
        } else {
          q0Code.word = (q0Code.word << 1) | 1;
        }
        q0Code.length ++;

        if ((kl % 2 == 0 && cursor > 0) || (kl % 2 == 1 && cursor == 0)) {
          // This subquery does not overlap with my zone.
          dbg(DBG_USR2, "This subquery does not overlap with my zone.\n");
          //qset[qsetIdx] = *q0;
          memcpy(&qset[qsetIdx * querySize], q0, querySize);
          // Set q0 to NULL.
          q0->type = 0xff;
          *qsetSize = qsetIdx + 1;
          
#if 0
          for (ii = 0; ii < *qsetSize; ii ++) {
            GenericQueryPtr qp = (GenericQueryPtr)(&qset[ii * querySize]);
            
            dbg(DBG_USR2, "subquery %d -t %c :: ", ii, qp->type);
            for (jj = 0; jj < attrNum; jj ++) {
              dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                            attrDescPtr[jj]->name,
                            qp->queryField[jj].lowerBound, 
                            qp->queryField[jj].upperBound);
            }
            dbg(DBG_USR2, "\n");
          }
#endif
          return;
        }
      }
      else {
        // Need to split this field.
        // qset[qsetIdx] = *q0;
        qry = (GenericQueryPtr)(&qset[qsetIdx * querySize]);
        memcpy(qry, q0, querySize);

        if (cursor == 0) {
          q0->queryField[j].upperBound = unit * (kl + 1);
          q0Code.word <<= 1;
          qry->queryField[j].lowerBound = q0->queryField[j].upperBound;
        }
        else {
          q0->queryField[j].lowerBound = unit * (kl + 1);
          q0Code.word = (q0Code.word << 1) | 1;
          qry->queryField[j].upperBound = q0->queryField[j].lowerBound;
        }
#if 0        
        dbg(DBG_USR2, "qset[%d] -t %c :: ", ii, qry->type);
        for (ii = 0; ii < attrNum; ii ++) {
          dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                        attrDescPtr[ii]->name,
                        qry->queryField[ii].lowerBound, 
                        qry->queryField[ii].upperBound);
        }
        dbg(DBG_USR2, "\n");
#endif
       
        q0Code.length ++;
        qsetIdx ++;
      }
      mask >>= 1;
    }
    *qsetSize = qsetIdx;
  }

  /*
  * Unlike PIR.send(), *msg* includes the routing protocol header.
  */
  task void receiving()
  {
    GreedyHeaderPtr gh;
    TOS_MsgPtr msg;
#ifdef DEBUG
    char text[16];
#endif
    uint8_t mode, i, j;
    GenericTuplePtr tupPtr;
    Code tupCode;
    GenericQueryPtr subQuery;
    Code qryCode;
    Coord destCoord, subQueryDest;
    uint8_t subQueryNum;

    if (msgRecvQHead == msgRecvQTail) {
      // Receiving queue is empty.
      atomic {
        recvPosted = FALSE;
      }
      return;
    }
      
    msg = &msgRecvQ[msgRecvQHead];
    gh = (GreedyHeaderPtr)(msg->data);
    mode = gh->mode_;

    if (mode == CONSOLE_CREATE) {
      if (dimCreated == FALSE) {
        ConsoleCreateMsgPtr cmd = (ConsoleCreateMsgPtr)gh;
        if (attrNum != cmd->beginNum) {
          // Creation request packets lost
          dbg(DBG_USR2, "Creation request packets lost\n");
          error = 4;
        } 
        else {
          for (i = 0; i <= (cmd->endNum - cmd->beginNum); i ++) {
            attrDescPtr[attrNum] = call AttrUse.getAttr(cmd->attrName[i]);
            if (attrDescPtr[attrNum] == NULL) {
              dbg(DBG_USR2, "Attribute %s NOT registered.\n", cmd->attrName[i]);
              error = 4;
              break;
            }
            //tupleSize += attrDescPtr[attrNum]->nbytes;
            dbg(DBG_USR2, "Attribute %s registered with idx = %d, nbytes = %d\n", 
                          attrDescPtr[attrNum]->name, 
                          attrDescPtr[attrNum]->idx, 
                          attrDescPtr[attrNum]->nbytes);
            attrNum ++;
          } // for

          tupleSize = sizeof(GenericTuple) + attrNum * 2;
          querySize = sizeof(GenericQuery) + attrNum * 4;
          
          dbg(DBG_USR2, "tupleSize = %d, querySize = %d\n", tupleSize, querySize);

          call Leds.redToggle();

          if (!error && attrNum == cmd->totalNum) {
            // All indexed attribute names have been received.
#ifdef USEGTS
            if (call GTS.create(tupleSize, (uint8_t)MAX_GTS_QUOTA, attrNum) == FAIL) {
              dbg(DBG_USR2, "Cannot create generic tuple storage!\n");
              //reportError();
              error = 3;
            }
#endif
#ifdef QUICKGTS
            if (call quickGTS.create(tupleSize, (uint8_t)MAX_GTS_QUOTA, attrNum) == FAIL) {
              dbg(DBG_USR2, "Cannot create generic tuple storage!\n");
              error = 3;
            }
#endif
            atomic {
              dimCreated = TRUE;
            }

            // Broadcast creation request
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
              // error = 5;
            } else {
              DimCreateMsgPtr dim;

              atomic {
                gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(DimCreateMsg) + sizeof(GreedyHeader);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              gh->coord_.x = gh->coord_.y = 0xffff;
              gh->src_addr_ = TOS_LOCAL_ADDRESS;
              gh->mode_ = GREEDY;
              dim = (DimCreateMsgPtr)(gh->data_);
              dim->type = 'C';
              dim->attrNum = attrNum;
              for (i = 0; i < attrNum; i ++) {
                dim->attrIds[i] = attrDescPtr[i]->idx;
              }

              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }

            // Reply to Console.
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
              // error = 5;
            } else {
              ConsoleReplyMsgPtr cmdRe;

              dbg(DBG_USR2, "sizeof(ConsoleReplyMsg) = %d\n", sizeof(ConsoleReplyMsg));

              atomic {
                cmdRe = (ConsoleReplyMsgPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(ConsoleReplyMsg);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              cmdRe->mode = CONSOLE_CREATE_REPLY;
              cmdRe->queryId = attrNum;
              cmdRe->sender = TOS_LOCAL_ADDRESS;
              for (i = 0; i < attrNum; i ++) {
                cmdRe->value[i] = attrDescPtr[i]->idx;
              }
              
              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          } 
        }
      }
    }
#if 1
    else if (mode == CONSOLE_DROP) {
      if (dimCreated == TRUE) {
        if (readyToSample < 0xff) {
          call Timer.stop();
          call Timer.start(TIMER_REPEAT, IDLE_PERIOD);

          atomic {
            readyToSample = 0xff;
            samplePeriod = 0;
          }
        }

        atomic {
          dimCreated = FALSE;
          attrNum = 0;
        }
        for (i = 0; i < MAX_ATTR_NUM; i ++) {
          attrDescPtr[i] = NULL;
        }
#ifdef USEGTS
        call GTS.drop();
#endif
#ifdef QUICKGTS
        call quickGTS.drop();
#endif        
        call Leds.redToggle();
        dbg(DBG_USR2, "DIM Index dropped!\n");

        // Broadcast creation request
        if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
          // Sending queue is full.
          dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
          error  = 5;
        } else {
          DimDropMsgPtr dimDr;

          atomic {
            gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(DimDropMsg) + sizeof(GreedyHeader);
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          gh->coord_.x = gh->coord_.y = 0xffff;
          gh->src_addr_ = TOS_LOCAL_ADDRESS;
          gh->mode_ = GREEDY;
          dimDr = (DimDropMsgPtr)(gh->data_);
          dimDr->type = 'D';
                
          dbg(DBG_USR2, "Broadcast DIM drop request\n");

          if (!sendPosted) {
            sendPosted = TRUE;
            post sending();
          }
        }
      }
    } else if (mode == CONSOLE_START) {
      if (dimCreated == TRUE && readyToSample == 0xff) {
        DimStartMsgPtr dimSt = (DimStartMsgPtr)gh; 
        atomic {
          readyToSample = 0;
          samplePeriod = dimSt->period;
        }
        call Timer.stop();
        call Timer.start(TIMER_REPEAT, samplePeriod);
        
        call Leds.redToggle();

        dbg(DBG_USR2, "DIM Index started with sampling period = %d!\n", samplePeriod);

        // Broadcast start request
        if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
          // Sending queue is full.
          dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
          error  = 5;
        } else {
          atomic {
            gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(DimStartMsg) + sizeof(GreedyHeader);
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          gh->coord_.x = gh->coord_.y = 0xffff;
          gh->src_addr_ = TOS_LOCAL_ADDRESS;
          gh->mode_ = GREEDY;
          dimSt = (DimStartMsgPtr)(gh->data_);
          dimSt->type = 'S';
          dimSt->period = samplePeriod;

          dbg(DBG_USR2, "Broadcast DIM start request\n");

          if (!sendPosted) {
            sendPosted = TRUE;
            post sending();
          }
        }
      }
    } else if (mode == CONSOLE_STOP) {
      if (dimCreated == TRUE && readyToSample < 0xff) {
        call Timer.stop();
        call Timer.start(TIMER_REPEAT, IDLE_PERIOD);

        atomic {
          readyToSample = 0xff;
          samplePeriod = 0;
        }
        
        call Leds.redToggle();
        dbg(DBG_USR2, "DIM Index stopped!\n");

        // Broadcast creation request
        if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
          // Sending queue is full.
          dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
          error  = 5;
        } else {
          DimStartMsgPtr dimSt;
          atomic {
            gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(DimStartMsg) + sizeof(GreedyHeader);
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          gh->coord_.x = gh->coord_.y = 0xffff;
          gh->src_addr_ = TOS_LOCAL_ADDRESS;
          gh->mode_ = GREEDY;
          dimSt = (DimStartMsgPtr)(gh->data_);
          dimSt->type = '$';
          dbg(DBG_USR2, "Broadcast DIM stop request\n");

          if (!sendPosted) {
            sendPosted = TRUE;
            post sending();
          }
        }
      }
    } else if (mode == CONSOLE_QUERY) {
      ConsoleQueryMsgPtr cmd = (ConsoleQueryMsgPtr)gh;
      //memset(qryPtr, 0, querySize);
      memset(qryPtr, 0, MAX_QUERY_BUF_LEN);
      qryPtr->type = 'Q';
      qryPtr->queryId = cmd->queryId;
      qryPtr->issuerX = myCoord.x;
      qryPtr->issuerY = myCoord.y;

      for (i = 0; i < attrNum; i ++) {
        qryPtr->queryField[i].lowerBound = 0;
        qryPtr->queryField[i].upperBound = 1024;
      }
      for (i = 0; i < cmd->attrNum; i ++) {
        for (j = 0; j < attrNum; j ++) {
          if (attrDescPtr[j]->idx == cmd->queryField[i].attrId) {
            qryPtr->queryField[j].lowerBound = cmd->queryField[i].lowerBound;
            qryPtr->queryField[j].upperBound = cmd->queryField[i].upperBound;
            break;
          }
        }
      }
#ifdef DEBUG
      dbg(DBG_USR2, "Console query: -n %hd -q %hd :: ", attrNum, qryPtr->queryId);
      for (i = 0; i < attrNum; i ++) {
        dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                      attrDescPtr[i]->name,
                      qryPtr->queryField[i].lowerBound, 
                      qryPtr->queryField[i].upperBound);
      }
      dbg(DBG_USR2, "\n");
#endif      
      // Encode query
      call Zone.encodeQuery(qryPtr, attrNum, &qryCode);
      
#ifdef DEBUG
      call Zone.showCode(qryCode, text);
      dbg(DBG_USR2, "Query encoded: %s\n", text);
#endif

#if 0
      //show the zone Code using the Leds
      call Leds.redOff();
      call Leds.yellowOff();
      call Leds.greenOff();

     if (qryCode.word == 0) {
        call Leds.redOn();
        call Leds.yellowOn();
        call Leds.greenOn();
     } else if (qryCode.word == 0x40) {
        call Leds.greenOn();
     }
#ifndef PLATFORM_PC
      {
         for (i=0; i<2000; i++) {
             asm volatile ("sleep" ::);
         }
      }
#endif
      call Leds.redOff();
      call Leds.yellowOff();
      call Leds.greenOff();
#endif 
#if 0
if (TOS_LOCAL_ADDRESS == 0) {
        call Leds.redOff();
        call Leds.yellowOff();
        call Leds.greenOn();
}
#endif
      if (call Zone.subZone(myCode, qryCode)) {
        
        // I can resolve this query entirely and no need to forward it.
        dbg(DBG_USR2, "I can resolve this query entirely and no need to forward it.\n");
#ifdef USEGTS
        if (!GTSBusy) {
          atomic {
            GTSBusy = TRUE;
            GTSFound = FALSE;
          }
          if (call GTS.search(qryPtr) == FAIL) {
            dbg(DBG_USR2, "Cannot search in GTS!\n");
            error = 3;
          }
        } else {
          havePendQuery = TRUE;
          memset(pendQuery, 0, MAX_QUERY_BUF_LEN);
          memcpy(pendQuery, qryPtr, querySize);
        }
#endif
#ifdef QUICKGTS
        if (call quickGTS.search(qryPtr) == FAIL) {
          dbg(DBG_USR2, "Cannot search in GTS!\n");
          error = 3;
        }
#endif        
      } else if (! call Zone.subZone(qryCode, myCode)) {
        // Query does not cover my zone.
        dbg(DBG_USR2, "Query does not cover my zone.\n");
        
        call Zone.getAddress(qryCode, &destCoord);
#ifdef DEBUG
        call Zone.showCode(qryCode, text);
        dbg(DBG_USR2, "FORWARD Query to zone %s at (%d, %d)\n", text, destCoord.x, destCoord.y);
#endif  
        // Enqueue
        if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
          // Sending queue is full.
          dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
        } else {
#ifdef DEBUG
          //GenericQueryPtr qp;
#endif
          GreedyHeaderPtr ghOut;

          atomic {
            ghOut = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + querySize;
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          ghOut->mode_ = GREEDY;
          ghOut->src_addr_ = TOS_LOCAL_ADDRESS;
          ghOut->coord_ = destCoord;
          memcpy(ghOut->data_, qryPtr, querySize);

#ifdef dEBUG   
          qp = (GenericQueryPtr)(ghOut->data_);
          dbg(DBG_USR2, "forward: -n %hd -q %hd :: ", attrNum, qp->queryId);
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                          attrDescPtr[i]->name,
                          qp->queryField[i].lowerBound, 
                          qp->queryField[i].upperBound);
          }
          dbg(DBG_USR2, "\n");
#endif
          if (!sendPosted) {
            sendPosted = TRUE;
            post sending();
          }
        }
      } else {
        uint8_t orgQuery[32];
        uint8_t subQueryBuf[MAX_SUBQUERY_NUM * 32];
        subQueryNum = 0;

        // Perserve the original query.
        memcpy(orgQuery, qryPtr, querySize);

        dbg(DBG_USR2, "Query does cover my zone. Need to split.\n");

        // Need to split.
        splitQuery(qryPtr, subQueryBuf, &subQueryNum);

#ifdef DEBUG
        if (qryPtr->type != 0xff) {
          dbg(DBG_USR2, "Current query after splitting :: ");
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                          attrDescPtr[i]->name,
                          qryPtr->queryField[i].lowerBound, 
                          qryPtr->queryField[i].upperBound);
          }
          dbg(DBG_USR2, "\n");
        }
        dbg(DBG_USR2, "subQueryNum = %d\n", subQueryNum);
#endif          
          
        /*
        * Should first send out all subqueries, then resolve the local part.
        */
        // curQuery must exist.
        for (i = 0; i < subQueryNum; i ++) {
          subQuery = (GenericQueryPtr)&(subQueryBuf[i * querySize]);
#ifdef DEBUG
          dbg(DBG_USR2, "subquery %d -t %c :: ", i, subQuery->type);
          for (j = 0; j < attrNum; j ++) {
            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                      attrDescPtr[j]->name,
                      subQuery->queryField[j].lowerBound, 
                      subQuery->queryField[j].upperBound);
          }
          dbg(DBG_USR2, "\n");
#endif
          call Zone.encodeQuery(subQuery, attrNum, &qryCode);
          call Zone.getAddress(qryCode, &subQueryDest);
#ifdef DEBUG            
          call Zone.showCode(qryCode, text);
          dbg(DBG_USR2, "FORWARD subquery to zone %s at (%d, %d)\n", text, subQueryDest.x, subQueryDest.y);
#endif
          // Enqueue
          if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
            // Sending queue is full.
            dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
          } else {
            GreedyHeaderPtr ghOut;
            
            atomic {
              ghOut = (GreedyHeaderPtr)&(msgSendQ[msgSendQTail].data);
              msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + querySize;
              msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
            }
            ghOut->mode_ = GREEDY;
            ghOut->src_addr_ = TOS_LOCAL_ADDRESS;
            ghOut->coord_ = subQueryDest;
            memcpy(ghOut->data_, subQuery, querySize);
            if (!sendPosted) {
              sendPosted = TRUE;
              post sending();
            }
          }
        }
        if (qryPtr->type != 0xff) {
#ifdef USEGTS        
          if (!GTSBusy) {
            atomic {
              GTSBusy = TRUE;
              GTSFound = FALSE;
            }
            if (call GTS.search(qryPtr) == FAIL) {
              dbg(DBG_USR2, "Cannot search in GTS!\n");
              error = 3;
            }
          } else {
            havePendQuery = TRUE;
            memset(pendQuery, 0, MAX_QUERY_BUF_LEN);
            memcpy(pendQuery, qryPtr, querySize);
          }
#endif
#ifdef QUICKGTS
          if (call quickGTS.search(qryPtr) == FAIL) {
            dbg(DBG_USR2, "Cannot search in GTS!\n");
            error = 3;
          }
#endif
        }
      } 
    }
    else if (mode == BEACON) {
#ifdef DEBUG    
      char old_text[9];
      Code oldCode = myCode;
#endif

      call Zone.adjust(gh->coord_);
      call Zone.getCode(&myCode);
#ifdef DEBUG      
      if (myCode.length != oldCode.length || myCode.word != oldCode.word) {
        call Zone.showCode(myCode, text);
        call Zone.showCode(oldCode, old_text);
        dbg(DBG_USR2, "Zone code changed from [%s] to [%s].\n", old_text, text);
      }
#endif      
    }
    else if (mode == GREEDY) {
      uint8_t type;
      type = gh->data_[0];
      switch (type) {
        case 'C': // DIM creation request
          if (dimCreated == FALSE) {
            DimCreateMsgPtr dim;
            
            atomic {
              dimCreated = TRUE;
            }
            dim = (DimCreateMsgPtr)(gh->data_);
            attrNum = dim->attrNum;
            tupleSize = 0;
            for (i = 0; i < attrNum; i ++) {
              attrDescPtr[i] = call AttrUse.getAttrById(dim->attrIds[i]);
              if (attrDescPtr[i] == NULL) {
                dbg(DBG_USR2, "Attribute %d NOT registered.\n", dim->attrIds[i]);
                error = 2;
                break;
              }
              //tupleSize += attrDescPtr[i]->nbytes;
              dbg(DBG_USR2, "Attribute %s registered with idx = %d, nbytes = %d\n", 
                            attrDescPtr[i]->name, 
                            attrDescPtr[i]->idx, 
                            attrDescPtr[i]->nbytes);
            } // for
            tupleSize = sizeof(GenericTuple) + attrNum * 2;
            querySize = sizeof(GenericQuery) + attrNum * 4;

            call Leds.redToggle();
            
            dbg(DBG_USR2, "tupleSize = %d, querySize = %d\n", tupleSize, querySize);

            if (!error && i == attrNum) {
              // All indexed attribute names have been received.
#ifdef USEGTS
              if (call GTS.create(tupleSize, (uint8_t)MAX_GTS_QUOTA, attrNum) == FAIL) {
                dbg(DBG_USR2, "Cannot create generic tuple storage!\n");
                error = 3;
              }
#endif
#ifdef QUICKGTS
              if (call quickGTS.create(tupleSize, (uint8_t)MAX_GTS_QUOTA, attrNum) == FAIL) {
                dbg(DBG_USR2, "Cannot create generic tuple storage!\n");
                error = 3;
              }
#endif
              // Broadcast creation request
              if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
                // Sending queue is full.
                dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
                error  = 5;
              } else {
                atomic {
                  gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                  msgSendQ[msgSendQTail].length = sizeof(DimCreateMsg) + sizeof(GreedyHeader);
                  msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
                }
                gh->coord_.x = gh->coord_.y = 0xffff;
                gh->src_addr_ = TOS_LOCAL_ADDRESS;
                gh->mode_ = GREEDY;
                dim = (DimCreateMsgPtr)(gh->data_);
                dim->type = 'C';
                dim->attrNum = attrNum;
                for (i = 0; i < attrNum; i ++) {
                  dim->attrIds[i] = attrDescPtr[i]->idx;
                }
                
                if (!sendPosted) {
                  sendPosted = TRUE;
                  post sending();
                }
              }
            }
          } 
          break;
        case 'D': // DIM drop request
          if (dimCreated == TRUE) {
            if (readyToSample < 0xff) {
              call Timer.stop();
              call Timer.start(TIMER_REPEAT, IDLE_PERIOD);

              atomic {
                readyToSample = 0xff;
                samplePeriod = 0;
              }
            }

            atomic {
              dimCreated = FALSE;
              attrNum = 0;
            }
            for (i = 0; i < MAX_ATTR_NUM; i ++) {
              attrDescPtr[i] = NULL;
            }
#ifdef USEGTS            
            call GTS.drop();
#endif
#ifdef QUICKGTS
            call quickGTS.drop();
#endif
            call Leds.redToggle();
            dbg(DBG_USR2, "DIM Index dropped!\n");

            // Broadcast creation request
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
              // error = 5;
            } else {
              DimDropMsgPtr dimDr;
              atomic {
                gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(DimDropMsg) + sizeof(GreedyHeader);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              gh->coord_.x = gh->coord_.y = 0xffff;
              gh->src_addr_ = TOS_LOCAL_ADDRESS;
              gh->mode_ = GREEDY;
              dimDr = (DimDropMsgPtr)(gh->data_);
              dimDr->type = 'D';
                
              dbg(DBG_USR2, "Broadcast DIM drop request\n");

              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          }
          break;
        case 'S': // DIM start request
          if (dimCreated == TRUE && readyToSample == 0xff) {
            DimStartMsgPtr dimSt = (DimStartMsgPtr)(gh->data_); 
            
            atomic {
              readyToSample = 0;
              samplePeriod = dimSt->period;
            }
            call Timer.stop();
            call Timer.start(TIMER_REPEAT, samplePeriod);

            call Leds.redToggle();

            dbg(DBG_USR2, "DIM Index started with sampling period = %d!\n", samplePeriod);

            // Broadcast start request
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
              // error = 5;
            } else {
              atomic {
                gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(DimStartMsg) + sizeof(GreedyHeader);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              gh->coord_.x = gh->coord_.y = 0xffff;
              gh->src_addr_ = TOS_LOCAL_ADDRESS;
              gh->mode_ = GREEDY;
              dimSt = (DimStartMsgPtr)(gh->data_);
              dimSt->type = 'S';
              dimSt->period = samplePeriod;

              dbg(DBG_USR2, "Broadcast DIM start request\n");

              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          }
          break;
        case '$': // DIM stop request
          if (dimCreated == TRUE && readyToSample < 0xff) {
            call Timer.stop();
            call Timer.start(TIMER_REPEAT, IDLE_PERIOD);

            atomic {
              readyToSample = 0xff;
              samplePeriod = 0;
            }
            dbg(DBG_USR2, "DIM Index stopped!\n");

            call Leds.redToggle();

            // Broadcast creation request
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
              error  = 5;
            } else {
              DimStartMsgPtr dimSt;
              atomic {
                gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(DimStartMsg) + sizeof(GreedyHeader);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              gh->coord_.x = gh->coord_.y = 0xffff;
              gh->src_addr_ = TOS_LOCAL_ADDRESS;
              gh->mode_ = GREEDY;
              dimSt = (DimStartMsgPtr)(gh->data_);
              dimSt->type = '$';
              dbg(DBG_USR2, "Broadcast DIM stop request\n");

              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          }
          break;
        case 'T':
          tupPtr = (GenericTuplePtr)(gh->data_);
#ifdef DEBUG          
          dbg(DBG_USR2, "Received Tuple: %c %hd %hd %hd %ld %ld :: ", 
                         tupPtr->type, tupPtr->queryId,
                         tupPtr->sender, tupPtr->detector, 
                         tupPtr->timelo, tupPtr->timehi);
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "%s: %hd ", attrDescPtr[i]->name, tupPtr->value[i]);
          }
          dbg(DBG_USR2, "\n");
#endif          
          call Zone.encodeTuple(tupPtr, attrNum, &tupCode, FALSE);

          if (tupCode.length == myCode.length && tupCode.word == myCode.word) {
            // This packet is destined for me, Absorb it.
            /*
            if (full) {
              dbg(DBG_USR2, "DROP Tuple\n");
            }
            */
            dbg(DBG_USR2, "ABSORB Tuple\n");
#ifdef USEGTS            
            if (!GTSBusy) {
              atomic {
                GTSBusy = TRUE;
              }
              if (call GTS.store(tupPtr) == FAIL) {
                dbg(DBG_USR2, "Cannot absorb tuple!\n");
                error = 3;
              }
            } // otherwise, we have to ignore this tuple, but just for now.
#endif
#ifdef QUICKGTS
            if (call quickGTS.store(tupPtr) == FAIL) {
              dbg(DBG_USR2, "Cannot absorb tuple!\n");
              error ++;
            }
#endif
          } else {
            // This packet is destined for somebody else, Forward it.
            call Zone.getAddress(tupCode, &destCoord);
#ifdef DEBUG            
            call Zone.showCode(tupCode, text);
            dbg(DBG_USR2, "FORWARD Tuple\n");
#endif            
            // Enqueue
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
            } else {
              GreedyHeaderPtr ghOut;
              
              atomic {
                ghOut = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              ghOut->mode_ = GREEDY;
              ghOut->src_addr_ = gh->src_addr_;
              ghOut->coord_ = destCoord;
              memcpy(ghOut->data_, tupPtr, tupleSize);
              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          }
          break;
        case 'Q': {
#ifdef DEBUG        
          GenericQueryPtr qp;
#endif          
          //memset(qryPtr, 0, 41);
          memset(qryPtr, 0, MAX_QUERY_BUF_LEN);
          //qryPtr = (GenericQueryPtr)(gh->data_);
          //*qryPtr = *((GenericQueryPtr)(gh->data_));
          memcpy(qryPtr, gh->data_, querySize);

#ifdef DEBUG      
          qp = qryPtr;
          dbg(DBG_USR2, "Received query: -n %hd -q %hd -S %d:: ", attrNum, qp->queryId, querySize);
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                          attrDescPtr[i]->name,
                          qp->queryField[i].lowerBound, 
                          qp->queryField[i].upperBound);
          }
          dbg(DBG_USR2, "\n");
          dbg(DBG_USR2, "Retrieved query: -n %hd -q %hd -S %d:: ", attrNum, qryPtr->queryId, querySize);
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                          attrDescPtr[i]->name,
                          qryPtr->queryField[i].lowerBound, 
                          qryPtr->queryField[i].upperBound);
          }
          dbg(DBG_USR2, "\n");
#endif      
          // Encode query
          call Zone.encodeQuery(qryPtr, attrNum, &qryCode);
#ifdef DEBUG      
          call Zone.showCode(qryCode, text);
          dbg(DBG_USR2, "Query encoded: %s\n", text);
#endif
          if (call Zone.subZone(myCode, qryCode)) {
            // I can resolve this query entirely and no need to forward it.
            dbg(DBG_USR2, "I can resolve this query entirely and no need to forward it.\n");
#ifdef USEGTS            
            if (!GTSBusy) {
              atomic {
                GTSBusy = TRUE;
                GTSFound = FALSE;
              }
              if (call GTS.search(qryPtr) == FAIL) {
                dbg(DBG_USR2, "Cannot search in GTS!\n");
                error = 3;
              }
            } else {
              havePendQuery = TRUE;
              memset(pendQuery, 0, MAX_QUERY_BUF_LEN);
              memcpy(pendQuery, qryPtr, querySize);
            }
#endif
#ifdef QUICKGTS
            if (call quickGTS.search(qryPtr) == FAIL) {
              dbg(DBG_USR2, "Cannot search in GTS!\n");
              error ++;
            }
#endif
          } else if (! call Zone.subZone(qryCode, myCode)) {
            // Query does not cover my zone.
            dbg(DBG_USR2, "Query does not cover my zone.\n");

            call Zone.getAddress(qryCode, &destCoord);
#ifdef DEBUG            
            call Zone.showCode(qryCode, text);
            dbg(DBG_USR2, "FORWARD Query to zone %s at (%d, %d)\n", text, destCoord.x, destCoord.y);
#endif  
            // Enqueue
            if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
              // Sending queue is full.
              dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
            } else {
              GreedyHeaderPtr ghOut;
              
              atomic {
                ghOut = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + querySize;
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              ghOut->mode_ = GREEDY;
              ghOut->src_addr_ = gh->src_addr_;
              ghOut->coord_ = destCoord;
              memcpy(ghOut->data_, qryPtr, querySize);
              if (!sendPosted) {
                sendPosted = TRUE;
                post sending();
              }
            }
          } else {
            uint8_t orgQuery[32];
            uint8_t subQueryBuf[MAX_SUBQUERY_NUM * 32];
            subQueryNum = 0;

            // Perserve the original query.
            memcpy(orgQuery, qryPtr, querySize);

            dbg(DBG_USR2, "Query does cover my zone. Need to split.\n");

            // Need to split.
            splitQuery(qryPtr, subQueryBuf, &subQueryNum);

#ifdef DEBUG
            if (qryPtr->type != 0xff) {
              dbg(DBG_USR2, "Current query after splitting :: ");
              for (i = 0; i < attrNum; i ++) {
                dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
                              attrDescPtr[i]->name,
                              qryPtr->queryField[i].lowerBound, 
                              qryPtr->queryField[i].upperBound);
              }
              dbg(DBG_USR2, "\n");
            }
            // Query does cover my zone. Need to split.
		        dbg(DBG_USR2, "subQueryNum = %d\n", subQueryNum);
#endif		
		        /*
		        * Should first send out all subqueries, then resolve the local part.
		        */
		        // curQuery must exist.
		        for (i = 0; i < subQueryNum; i ++) {
              subQuery = (GenericQueryPtr)&(subQueryBuf[i * querySize]);
#ifdef DEBUG
              dbg(DBG_USR2, "subquery %d -t %c :: ", i, subQuery->type);
		          for (j = 0; j < attrNum; j ++) {
		            dbg(DBG_USR2, "-a %s [%hd, %hd] ", 
		                      attrDescPtr[j]->name,
		                      subQuery->queryField[j].lowerBound, 
		                      subQuery->queryField[j].upperBound);
		          }
		          dbg(DBG_USR2, "\n");
#endif
		          call Zone.encodeQuery(subQuery, attrNum, &qryCode);
		          call Zone.getAddress(qryCode, &subQueryDest);
#ifdef DEBUG
              call Zone.showCode(qryCode, text);
              dbg(DBG_USR2, "FORWARD subquery to zone %s at (%d, %d)\n", text, subQueryDest.x, subQueryDest.y);
#endif          
		          // Enqueue
		          if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
		            // Sending queue is full.
		            dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
                // error = 5;
		          } else {
                GreedyHeaderPtr ghOut;
                
                atomic {
                  ghOut = (GreedyHeaderPtr)&(msgSendQ[msgSendQTail].data);
                  msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + querySize;
                  msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
                }
                ghOut->mode_ = GREEDY;
                ghOut->src_addr_ = gh->src_addr_;
                ghOut->coord_ = subQueryDest;
                memcpy(ghOut->data_, subQuery, querySize);
		            if (!sendPosted) {
		              sendPosted = TRUE;
		              post sending();
		            }
		          }
		        }
            if (qryPtr->type != 0xff) {
#ifdef USEGTS            
              if (!GTSBusy) {
                atomic {
                  GTSBusy = TRUE;
                  GTSFound = FALSE;
                }
                if (call GTS.search(qryPtr) == FAIL) {
                  dbg(DBG_USR2, "Cannot search in GTS!\n");
                  error = 3;
                }
              } else {
                havePendQuery = TRUE;
                memset(pendQuery, 0, MAX_QUERY_BUF_LEN);
                memcpy(pendQuery, qryPtr, querySize);
              }
#endif
#ifdef QUICKGTS
		          if (call quickGTS.search(qryPtr) == FAIL) {
		            dbg(DBG_USR2, "Cannot search in GTS!\n");
                error ++;
              }
#endif
            }
          }}
          break;
        case 'R':
          call Leds.yellowToggle();

          tupPtr = (GenericTuplePtr)(gh->data_);
#ifdef DEBUG
          dbg(DBG_USR2, "Reply Tuple: %c %hd %hd %hd %ld %ld :: ", 
                        tupPtr->type, tupPtr->queryId, tupPtr->sender,
                        tupPtr->detector, tupPtr->timelo, tupPtr->timehi);
          for (i = 0; i < attrNum; i ++) {
            dbg(DBG_USR2, "%s: %hd ", attrDescPtr[i]->name, tupPtr->value[i]);
          }
          dbg(DBG_USR2, "\n");
#endif
          if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
            // Sending queue is full.
            dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
            error  = 5;
          } else {
            destCoord = gh->coord_;
            if (destCoord.x == myCoord.x && destCoord.y == myCoord.y) {
              ConsoleReplyMsgPtr cmdRe;
              atomic {
                cmdRe = (ConsoleReplyMsgPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(ConsoleReplyMsg);
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
#if 0
if (TOS_LOCAL_ADDRESS == 0) {
  call Leds.redOff();
  call Leds.yellowOff();
  call Leds.greenOn();
}
#endif
              cmdRe->mode = CONSOLE_QUERY_REPLY;
              cmdRe->queryId = tupPtr->queryId;
              cmdRe->sender = tupPtr->sender;
              cmdRe->detector = tupPtr->detector;
              cmdRe->timelo = tupPtr->timelo;
              cmdRe->timehi = tupPtr->timehi;
              for (i = 0; i < attrNum; i ++) {
                cmdRe->value[i] = tupPtr->value[i];
              }              
            } else {
              //GenericTuplePtr tupRe;
              GreedyHeaderPtr ghOut;

              atomic {
                ghOut = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
                msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
                msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
              }
              /*
              *ghOut = *gh;
              tupRe = (GenericTuplePtr)(ghRe->data_);
              *tupRe = *tupPtr;
              for (i = 0; i < attrNum; i ++) {
                tupRe->value[i] = tupPtr->value[i];
              }
              */
              memcpy(ghOut, gh, sizeof(GreedyHeader) + tupleSize);
            }
            if (!sendPosted) {
              sendPosted = TRUE;
              post sending();
            }
          }
          break;
        default:
          dbg(DBG_USR2, "Unknown message type '%d'\n", type);
          break;
      }
    } else {
      dbg(DBG_USR2, "Unknown packet mode %d from %d\n", mode, gh->src_addr_);
    }

    atomic {
      msgRecvQHead = (msgRecvQHead + 1) % MAX_RECV_QLEN;
    }
    if (msgRecvQHead != msgRecvQTail) {
      post receiving();
    } 
    else {
      atomic {
        recvPosted = FALSE;
      }
    }
#endif
  }

#ifdef USEGTS
  event result_t GTS.found(GenericTuplePtr tupPtr)
  {
    call Leds.yellowToggle();

    if (tupPtr) {
      uint8_t i;

      atomic {
        GTSFound = TRUE;
      }
      if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
        // Sending queue is full.
        dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
        // error = 5;
      } else {
        if (qryPtr->issuerX == myCoord.x && qryPtr->issuerY == myCoord.y) {
          ConsoleReplyMsgPtr cmdRe;
          atomic {
            cmdRe = (ConsoleReplyMsgPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(ConsoleReplyMsg);
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          cmdRe->mode = CONSOLE_QUERY_REPLY;
          cmdRe->queryId = qryPtr->queryId;
          cmdRe->sender = TOS_LOCAL_ADDRESS;
          cmdRe->detector = tupPtr->detector;
          cmdRe->timelo = tupPtr->timelo;
          cmdRe->timehi = tupPtr->timehi;
          for (i = 0; i < attrNum; i ++) {
            cmdRe->value[i] = tupPtr->value[i];
          }
        } else {
          GenericTuplePtr tupRe;
          GreedyHeaderPtr gh;
        
          atomic {
            gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          gh->coord_.x = qryPtr->issuerX;
          gh->coord_.y = qryPtr->issuerY;
          gh->mode_ = GREEDY;
          gh->src_addr_ = TOS_LOCAL_ADDRESS;
          tupRe = (GenericTuplePtr)(gh->data_);
          tupRe->type = 'R';
          tupRe->queryId = qryPtr->queryId;
          tupRe->sender = TOS_LOCAL_ADDRESS;
          tupRe->detector = tupPtr->detector;
          tupRe->timelo = tupPtr->timelo;
          tupRe->timehi = tupPtr->timehi;
          for (i = 0; i < attrNum; i ++) {
            tupRe->value[i] = tupPtr->value[i];
          }
        }
          
        if (!sendPosted) {
          sendPosted = TRUE;
          post sending();
        }
      }
    }
    return SUCCESS;
  }

  event result_t GTS.full()
  {
    //call Timer.stop();
    return SUCCESS;
  }

  event result_t GTS.dropDone() {
    return SUCCESS;
  }

  event result_t GTS.broken(uint8_t errorNo) {
    error = errorNo;
    return SUCCESS;
  }

  event result_t GTS.storeDone() {
    if (havePendQuery) {
      atomic {
        GTSFound = FALSE;
      }
      if (call GTS.search((GenericQueryPtr)pendQuery) == FAIL) {
        dbg(DBG_USR2, "Cannot search in GTS!\n");
        error  = 3;
      }
      //havePendQuery = FALSE;
    } else {
      atomic {
        call Leds.yellowToggle();
        GTSBusy = FALSE;
      }
    }
    return SUCCESS;
  }
  
#if 0  
  event result_t GTS.getAtDone(void *data, uint8_t size) {
    return SUCCESS;
  }
#endif

  event result_t GTS.searchDone() {
    uint8_t i ;

//call Leds.yellowToggle();

    atomic {
      GTSBusy = FALSE;
      havePendQuery = FALSE;
    } 
    if (!GTSFound) {
      if (((msgSendQTail + 1) % MAX_SEND_QLEN) == msgSendQHead) {
        // Sending queue is full.
        dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
        // error = 5;
      } else {
        if (qryPtr->issuerX == myCoord.x && qryPtr->issuerY == myCoord.y) {
          ConsoleReplyMsgPtr cmdRe;
          atomic {
            cmdRe = (ConsoleReplyMsgPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(ConsoleReplyMsg);
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
#if 0
if (TOS_LOCAL_ADDRESS == 0) {
  call Leds.greenOn();
  call Leds.yellowOn();
  call Leds.redOff();
}
#endif
          cmdRe->mode = CONSOLE_QUERY_REPLY;
          cmdRe->queryId = qryPtr->queryId;
          cmdRe->sender = TOS_LOCAL_ADDRESS;
          cmdRe->detector = 0;
          cmdRe->timelo = 0;
          cmdRe->timehi = 0;
          //cmdRe->timehi = replySeqNo ++;
          for (i = 0; i < attrNum; i ++) {
            cmdRe->value[i] = 0;
          }
        } else {
          GenericTuplePtr tupRe;
          GreedyHeaderPtr gh;
        
          atomic {
            gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
            msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
            msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
          }
          gh->coord_.x = qryPtr->issuerX;
          gh->coord_.y = qryPtr->issuerY;
          gh->mode_ = GREEDY;
          gh->src_addr_ = TOS_LOCAL_ADDRESS;
          tupRe = (GenericTuplePtr)(gh->data_);
          tupRe->type = 'R';
          tupRe->queryId = qryPtr->queryId;
          tupRe->sender = TOS_LOCAL_ADDRESS;
          tupRe->detector = 0;
          tupRe->timelo = 0;
          tupRe->timehi = 0;
          //tupRe->timehi = replySeqNo ++;
          for (i = 0; i < attrNum; i ++) {
            tupRe->value[i] = 0;
          }
        }

        if (!sendPosted) {
          sendPosted = TRUE;
          post sending();
        }
      }
    }
    return SUCCESS;
  }
#endif

  task void sending() 
  {
    Coord destCoord;
    GreedyHeaderPtr gh;
    uint8_t sendResult;

    //dbg(DBG_USR2, "task sending() running\n");

    if (msgSendQHead != msgSendQTail) {
      // Sending queue is not empty.
      gh = (GreedyHeaderPtr)(msgSendQ[msgSendQHead].data);

      if (gh->mode_ > GREEDY) {
        destCoord.x = destCoord.y = 0;
      } else {
        destCoord = gh->coord_;
      }

      sendResult = call Greedy.send(destCoord, msgSendQ[msgSendQHead].length, (uint8_t *)(msgSendQ[msgSendQHead].data));
      switch (sendResult) {
      case FAIL:
        error = 6;
        dbg(DBG_USR2, "Invocation of Greedy.send() failed!\n");
        break;
      case SUCCESS:
        break;
      case NO_ROUTE:
        error = 6;
        if (gh->data_[0] == 'T') {
          GenericTuplePtr gTuplePtr = (GenericTuplePtr)(gh->data_);
#ifdef USEGTS
          if (!GTSBusy) {
            atomic {
              GTSBusy = TRUE;
            }
            call Leds.redToggle();
            if (call GTS.store(gTuplePtr) == FAIL) {
              dbg(DBG_USR2, "Cannot store tuple!\n");
              error = 3;
            }
          } // otherwise, we have to ignore this tuple, but just for now.
#endif
#ifdef QUICKGTS        
          if (call quickGTS.store(gTuplePtr) == FAIL) {
            dbg(DBG_USR2, "Cannot store tuple!\n");
            error ++;
          }
#endif          
        }
        dbg(DBG_USR2, "No route!\n");
        // Dequeue
        atomic {
          msgSendQHead = (msgSendQHead + 1) % MAX_SEND_QLEN;
          if (msgSendQHead != msgSendQTail) {
            // Keep sending if sending queue is not empty.
            post sending();
          } else {
            sendPosted = FALSE;
          }
        }
        break;
      }
    }
  }
  
  event result_t Greedy.sendDone(result_t success)
  {
    if (success != SUCCESS) {
      error = 6;
      dbg(DBG_USR2, "Greeady.sendDone() failed!\n");
    } else {
      // Dequeue
      atomic {
        msgSendQHead = (msgSendQHead + 1) % MAX_SEND_QLEN;
      }
      if (msgSendQHead != msgSendQTail) {
        // Keep sending if sending queue is not empty.
        post sending();
      } else {
        atomic {
          sendPosted = FALSE;
        }
      }
    }
    return success;
  }

  event result_t Greedy.recv(TOS_MsgPtr msgPtr)
  {
    if ((msgRecvQTail + 1) % MAX_RECV_QLEN == msgRecvQHead) {
      // Receiving queue is full.
      dbg(DBG_USR2, "Receiving queue is full, droptail this message!\n");
      // error = 7;
    } else {
      atomic {
        msgRecvQ[msgRecvQTail] = *msgPtr;
        msgRecvQTail = (msgRecvQTail + 1) % MAX_RECV_QLEN;
      }
      if (! recvPosted) {
        atomic {
          recvPosted = TRUE;
        }
        post receiving();
      }
    }
    return SUCCESS;
  }

#ifdef QUICKGTS
  event result_t quickGTS.found(GenericTuplePtr tupPtr)
  {
    uint8_t i ;
#ifdef DEBUG
    if (tupPtr) {
      dbg(DBG_USR2, "Reply Tuple: R %hd %hd %hd %ld %ld :: ", 
                    qryPtr->queryId,
                    TOS_LOCAL_ADDRESS, tupPtr->detector, 
                    tupPtr->timelo, tupPtr->timehi);
      for (i = 0; i < attrNum; i ++) {
        dbg(DBG_USR2, "%s: %hd ", attrDescPtr[i]->name, tupPtr->value[i]);
      }
      dbg(DBG_USR2, "\n");
    } else {
      dbg(DBG_USR2, "Reply Tuple: R %hd %hd 0 0 0 :: NIL\n", qryPtr->queryId, TOS_LOCAL_ADDRESS);
    }
#endif
    if ((msgSendQTail + 1) % MAX_SEND_QLEN == msgSendQHead) {
      // Sending queue is full.
      dbg(DBG_USR2, "Sending queue is full, droptail this message!\n");
      //error ++;
    } else {
      if (qryPtr->issuerX == myCoord.x && qryPtr->issuerY == myCoord.y) {
        ConsoleReplyMsgPtr cmdRe;
        atomic {
          cmdRe = (ConsoleReplyMsgPtr)(msgSendQ[msgSendQTail].data);
          msgSendQ[msgSendQTail].length = sizeof(ConsoleReplyMsg);
          msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
        }
        cmdRe->mode = CONSOLE_QUERY_REPLY;
        cmdRe->queryId = qryPtr->queryId;
        cmdRe->sender = TOS_LOCAL_ADDRESS;
        if (tupPtr != NULL) {
          cmdRe->detector = tupPtr->detector;
          cmdRe->timelo = tupPtr->timelo;
          cmdRe->timehi = tupPtr->timehi;
          for (i = 0; i < attrNum; i ++) {
            cmdRe->value[i] = tupPtr->value[i];
          }
        } else {
          cmdRe->detector = 0;
          cmdRe->timelo = 0;
          cmdRe->timehi = 0;
          for (i = 0; i < attrNum; i ++) {
            cmdRe->value[i] = 0;
          }
        }
      } else {
        GenericTuplePtr tupRe;
        GreedyHeaderPtr gh;
        
        atomic {
          gh = (GreedyHeaderPtr)(msgSendQ[msgSendQTail].data);
          msgSendQ[msgSendQTail].length = sizeof(GreedyHeader) + tupleSize;
          msgSendQTail = (msgSendQTail + 1) % MAX_SEND_QLEN;
        }
        gh->coord_.x = qryPtr->issuerX;
        gh->coord_.y = qryPtr->issuerY;
        gh->mode_ = GREEDY;
        gh->src_addr_ = TOS_LOCAL_ADDRESS;
        tupRe = (GenericTuplePtr)(gh->data_);
        tupRe->type = 'R';
        tupRe->queryId = qryPtr->queryId;
        tupRe->sender = TOS_LOCAL_ADDRESS;
        if (tupPtr != NULL) {
          tupRe->detector = tupPtr->detector;
          tupRe->timelo = tupPtr->timelo;
          tupRe->timehi = tupPtr->timehi;
          for (i = 0; i < attrNum; i ++) {
            tupRe->value[i] = tupPtr->value[i];
          }
        } else {
          tupRe->detector = 0;
          tupRe->timelo = 0;
          tupRe->timehi = 0;
          for (i = 0; i < attrNum; i ++) {
            tupRe->value[i] = 0;
          }
        }
      }
          
      if (!sendPosted) {
        sendPosted = TRUE;
        post sending();
      }
    }
    return SUCCESS;
  }

  event result_t quickGTS.full()
  {
    //call Timer.stop();
    return SUCCESS;
  }
  event result_t quickGTS.createDone(result_t success) {
    if (success != SUCCESS) {
      dbg(DBG_USR2, "Failed to create generic tuple storage!\n");
      error = 2;
    } 
    return success;
  }
#endif
}
