/*
 * social.c - a people-tracking application
 *   two functions: 
 *     broadcast a regular "I'm here" message with the motes unique id
 *     keep track of how often other motes are heard
 *       (used to build a social network graph)
 *
 * Authors: David Gay
 * History: created 12/20/01
 */

includes Identity;
includes IdentMsg;
includes SocialMsg;
module SocialM
{
  provides interface StdControl;
  uses {
    interface StdControl as SubControl;

    interface CheckpointInit;
    interface CheckpointRead;
    interface CheckpointWrite;

    interface Ident;
    interface Timer;
    interface Pot;
    interface Leds;

    interface SendMsg as SendSocialMsg;
    interface ReceiveMsg as ReceiveIdMsg;
    interface ReceiveMsg as ReceiveReqDataMsg;
    interface ReceiveMsg as ReceiveRegisterMsg;
  }
}
implementation
{

  /* Power increase for social info messages */
  enum {
    SSI_POT_STEP = 10,
    CHECKPOINT_INTERVAL = 300,
    MIN_SEND_INTERVAL = 300,
    SEND_TIMEOUT = 5, /* Minimum interval before resending social info */

    SOCIAL_EEPROM_BASE = 128,

  };

  struct socialInfo {
    uint8_t counts[MAX_PEOPLE * 3];
  };

  struct eepromState {
    uint16_t localId;
    struct socialInfo currentInfo, sentInfo;
    uint32_t timeInfoStarts, timeSentInfoEnds;
  };

  bool ready;
  bool sending;
  bool checkpointing;
  struct eepromState info;
  uint32_t currentTime;
  uint32_t last_checkpointTime;

  TOS_Msg msg1;
  uint8_t socialSeqno, socialPacketId;
  uint32_t sendTimeoutEnd;

  void clearSocialInfo(struct socialInfo *s);
  void updateSocialInfo(uint8_t id, uint16_t period);
  void sendSocialInfo();

  command result_t StdControl.init() {
    ready = sending = checkpointing = FALSE;
    currentTime = last_checkpointTime = 0;

    return rcombine(call SubControl.init(), call CheckpointInit.init(SOCIAL_EEPROM_BASE, sizeof(info), 1));
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  void updateIdentity() {
    identity_t id;

    id.moteId = TOS_LOCAL_ADDRESS;
    id.localId = info.localId;
    id.timeInfoStarts = info.timeInfoStarts;
    call Ident.setId(&id);
  }

  void startApp() {
    ready = TRUE;
    call Timer.start(TIMER_REPEAT, 1000);
    updateIdentity();
  }

  void checkpointEnd() {
    checkpointing = FALSE;
    if (sending)
      {
	updateIdentity();
	sendSocialInfo();
      }
    else if (!ready)
      startApp();
    else
      updateIdentity();
  }

  void checkpoint() {
    if (!checkpointing)
      {
	checkpointing = TRUE;
	if (!call CheckpointWrite.write(0, (uint8_t *)&info))
	  {
	    call Leds.redOn();
	    checkpointEnd();
	  }
      }
  }

  event result_t CheckpointWrite.writeDone(result_t success, uint8_t *data) {
    if (success)
      call Leds.redOff();
    else
      call Leds.redOn();
    checkpointEnd();
    return SUCCESS;
  }

  void clearState(int newid) {
    struct eepromState *s = &info;

    s->localId = newid;
    clearSocialInfo(&s->currentInfo);
    clearSocialInfo(&s->sentInfo);
    s->timeInfoStarts = s->timeSentInfoEnds = 0;

    /* There's a potential vulnerability here (if we die before saving,
       we won't get the "cleared" indication from the checkpointer
       next time). To fix, need to change CHECKPOINT to keep a per-data-set
       validity bit (or else, perform our own validation of checkpoint entries,
       but that seems silly (CHECKPOINT can easily do it)) */
    checkpoint();
  }

  void loadState() {
    call CheckpointRead.read(0, (uint8_t *)&info);
  }

  event result_t CheckpointRead.readDone(result_t success, uint8_t *data) {
    if (success)
      {
	call Leds.greenOn();
	startApp();
      }
    else
      {
	call Leds.redOn();
	clearState(0);
      }
    return SUCCESS;
  }

  event result_t CheckpointInit.initialised(bool cleared) {
    if (cleared)
      {
	call Leds.redOn();
	clearState(0);
      }
    else
      loadState();

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveRegisterMsg.receive(TOS_MsgPtr m) {
    struct RegisterMsg *newid = (struct RegisterMsg *)m->data;

    if (newid->localId != info.localId && ready && !checkpointing)
      {
	/* Host has given us a new identity. Forget old state */
	ready = FALSE;
	clearState(newid->localId);
      }

    return m;
  }

  event result_t Timer.fired() {
    currentTime++;
    if (currentTime > last_checkpointTime + CHECKPOINT_INTERVAL)
      {
	last_checkpointTime = currentTime;
	if (!sending)
	  checkpoint();
      }

    if (sending && currentTime >= sendTimeoutEnd)
      sending = FALSE;
    return SUCCESS;
  }

  /* Respond to messages */

  /* From another social mote */
  event TOS_MsgPtr ReceiveIdMsg.receive(TOS_MsgPtr msg) {
    struct IdentMsg *sender = (struct IdentMsg *)msg->data;

    if (ready && !checkpointing && sender->identity.localId &&
	sender->identity.localId < MAX_PEOPLE)
      updateSocialInfo(sender->identity.localId, sender->broadcastPeriod);
    return msg;
  }

  /* Figure out number of entries per packet. */
  enum {
    FIRSTPACKET_PEOPLE = ((DATA_LENGTH - sizeof(struct DataMsg) - offsetof(struct SocialPacket, timeTogether)) / 2),
    PEOPLE_PERPACKET = ((DATA_LENGTH - sizeof(struct DataMsg)) / 2),
    NPACKETS =
      MAX_PEOPLE <= FIRSTPACKET_PEOPLE ? 1 :
      1 + (MAX_PEOPLE - FIRSTPACKET_PEOPLE + PEOPLE_PERPACKET - 1) / PEOPLE_PERPACKET
  };


  uint32_t getSocial_count_fp(struct socialInfo *s, uint8_t id) {
    return ((uint32_t)s->counts[id * 3 + 2] << 16) +
      ((uint16_t)s->counts[id * 3 + 1] << 8) + s->counts[id * 3];
  }

  void copySocial_count(struct socialInfo *s, uint8_t id, uint16_t *to) {
    /* Implicit round to zero, skip low order 8 bits */
    *to = s->counts[id * 3 + 1] | (s->counts[id * 3 + 2] << 8);
  }

  void setSocial_count_fp(struct socialInfo *s, uint8_t id, uint32_t count) {
    s->counts[id * 3] = count & 0xff;
    count >>= 8;
    s->counts[id * 3 + 1] = count & 0xff;
    count >>= 8;
    s->counts[id * 3 + 2] = count;
  }

  void clearSocialInfo(struct socialInfo *s) {
    memset(s, 0, sizeof(*s));
  }

  void clearSentSocialData() {
    struct socialInfo *c = &info.currentInfo;
    struct socialInfo *l = &info.sentInfo;
    uint8_t i;

    for (i = 0; i < MAX_PEOPLE; i++)
      setSocial_count_fp(c, i, getSocial_count_fp(c, i) - getSocial_count_fp(l, i));
    clearSocialInfo(l); /* Don't subtract l twice ! */
  }

  void updateSocialInfo(uint8_t id, uint16_t period) {
    struct socialInfo *s = &info.currentInfo;
    setSocial_count_fp(s, id, getSocial_count_fp(s, id) + period);
  }

  void sendSocialInfo() {
    uint8_t packetId = socialPacketId;
    TOS_MsgPtr m = &msg1;
    uint8_t moteId, mote_baseId;
    uint16_t *base;
    struct socialInfo *s = &info.sentInfo;
    struct DataMsg *mhdr = (struct DataMsg *)m->data;
    uint8_t npeople;

    call Leds.greenToggle();
    mhdr->moteId = TOS_LOCAL_ADDRESS;
    mhdr->seqno = socialSeqno;
    mhdr->messageno = packetId;
    if (packetId == 0)
      {
	struct SocialPacket *shdr = (struct SocialPacket *)(mhdr->data);
	uint8_t i;

	base = shdr->timeTogether;
	shdr->protocol = 100;
	shdr->timeInfoStarts = info.timeInfoStarts;
	shdr->timeInfoEnds = info.timeSentInfoEnds;
	npeople = FIRSTPACKET_PEOPLE;
	mote_baseId = 0;
	for (i = 0; i < SSI_POT_STEP; i++)
	  call Pot.decrease();
      }
    else
      {
	base = (uint16_t *)mhdr->data;
	npeople = PEOPLE_PERPACKET;
	mote_baseId = FIRSTPACKET_PEOPLE + (packetId - 1) * PEOPLE_PERPACKET;
      }

    if (mote_baseId + npeople > MAX_PEOPLE)
      npeople = MAX_PEOPLE - mote_baseId;

    for (moteId = 0; moteId < npeople; moteId++)
      copySocial_count(s, mote_baseId + moteId, base + moteId);

    call SendSocialMsg.send(TOS_BCAST_ADDR,
			    (uint8_t *)(base + npeople) - (uint8_t *)msg1.data,
			    &msg1);
  }

  task void sendNext() {
    sendSocialInfo();
  }

  event result_t SendSocialMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &msg1) 
      {
	socialPacketId++;
	if (socialPacketId < NPACKETS)
	  post sendNext();
	else
	  {
	    uint8_t i;

	    /* start timeout */
	    sendTimeoutEnd = currentTime + SEND_TIMEOUT;

	    /* Decrease xmission power */
	    for (i = 0; i < SSI_POT_STEP; i++)
	      call Pot.increase();
	  }
      }
    return SUCCESS;
  }

  void startSocialDataSend() {
    memcpy(&info.sentInfo,
	   &info.currentInfo, sizeof(struct socialInfo));
    info.timeSentInfoEnds = currentTime;
    sending = TRUE;
    socialSeqno++;
    socialPacketId = 0;
    sendTimeoutEnd = (uint32_t)-1; /* Disable timeout */
    checkpoint();
  }

  /* From a base station */
  event TOS_MsgPtr ReceiveReqDataMsg.receive(TOS_MsgPtr msg) {
    struct ReqDataMsg *rd = (struct ReqDataMsg *)msg->data;

    if (ready && !checkpointing)
      {
	bool info_change = FALSE;

	/* Resync clock (it drifts quite fast, so we can't just sync
	   it once).
	   This doesn't create problems as we don't timestamp our data,
	   except for "time sent info ends", and that is only set just
	   after the clock is synced. */
	uint32_t oldTime = currentTime, toffset;

	currentTime = rd->currentTime;
	if (info.timeInfoStarts == 0 &&
	    info.timeSentInfoEnds == 0)
	  {
	    toffset = currentTime - oldTime;
	    info.timeInfoStarts += toffset;
	    info.timeSentInfoEnds += toffset;
	    info_change = TRUE;
	  }

	/* Sanity checks (irrespective of comment above ;-))
	   These guarantee that
	   timeSentInfoEnds < currentTime 
	   and avoids disturbing timeSentInfoEnds (which is used
	   in our protocol as an identifier)
	*/
	if (currentTime <= info.timeSentInfoEnds)
	  currentTime = info.timeSentInfoEnds + 1;

	/* Update other times */
	toffset = currentTime - oldTime;
	last_checkpointTime += toffset;
	if (sendTimeoutEnd != (uint32_t)-1)
	  sendTimeoutEnd += toffset;


	if (rd->lastDataTime == info.timeSentInfoEnds)
	  {
	    clearSentSocialData();
	    info.timeInfoStarts =
	      info.timeSentInfoEnds;
	    info_change = TRUE;
	  }

	if (!sending)
	  {
	    if (currentTime >= rd->lastDataTime + MIN_SEND_INTERVAL)
	      startSocialDataSend();
	    else if (info_change)
	      checkpoint();
	  }
      }
    return msg;
  }
}
