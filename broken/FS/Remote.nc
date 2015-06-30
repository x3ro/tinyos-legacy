// Remote execution of FS ops
includes Matchbox;
includes AM;
includes Remote;
module Remote
{
  provides {
    interface StdControl;
    event result_t sendDone();
  }
  uses {
    interface FileDelete;
    interface FileDir;
    interface FileRead;
    interface FileRename;
    interface FileWrite;

    interface SendMsg as SendReplyMsg;
    interface ReceiveMsg as ReceiveCommandMsg;
    interface Leds;
    interface StdControl as CommControl;
  }
}
implementation {
  TOS_Msg cmdSwapMsg;
  TOS_MsgPtr cmdMsg;
  TOS_Msg replyMsg;
  struct FSReplyMsg *reply;
  uint8_t replyMsgLen;

  bool busy, sendPending;

  bool dirEnding;

  void busyLeds() {
    call Leds.yellowToggle();
  }

  void errorLeds() {
    call Leds.redToggle();
  }

  uint8_t extractU8(uint8_t **args) {
    return *(*args)++;
  }
  
  filesize_t extractFileSize(uint8_t **args) {
    filesize_t n = *(filesize_t *)*args;

    *args += sizeof(filesize_t);

    return n;
  }
  
  enum { MAX_STR = 14 };

  char *extractString(uint8_t **args) {
    uint8_t i;
    for (i = 0; i < MAX_STR; i++)
      if (!(*args)[i])
	{
	  char *s = (char *)*args;

	  *args += i + 1;
	  return s;
	}
    return NULL;
  }

  void safe_strcpy(char *to, const char *from) {
    uint8_t i;

    for (i = 0; i < MAX_STR - 1; i++)
      if (!(*to++ = *from++))
	return;

    *to = '\0';
  }

  command result_t StdControl.init() {
    reply = (struct FSReplyMsg *)replyMsg.data;
    busy = sendPending = FALSE;
    call Leds.init();
    call Leds.greenOn();
    return call CommControl.init();
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  

  void trySend() {
    sendPending = TRUE;
    if (call SendReplyMsg.send(TOS_UART_ADDR, replyMsgLen, &replyMsg))
      sendPending = FALSE;
  }

  event result_t sendDone() {
    if (sendPending)
      trySend();
    return SUCCESS;
  }

  void sendResult(fileresult_t result, uint8_t len) {
    reply->op = ((struct FSOpMsg *)cmdMsg->data)->op;
    reply->result = result;
    replyMsgLen = offsetof(struct FSReplyMsg, data[len]);

    trySend();
  }

  void sendResult0(fileresult_t result) {
    sendResult(result, 0);
  }

  event result_t SendReplyMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &replyMsg)
      {
	busy = FALSE;
	if (!success)
	  errorLeds();
      }
    return SUCCESS;
  }

  task void handleCommand();

  event TOS_MsgPtr ReceiveCommandMsg.receive(TOS_MsgPtr msg) {
    TOS_MsgPtr oldCmd;

    if (busy)
      {
	busyLeds();
	return msg;
      }
    busy = TRUE;

    call Leds.greenToggle();
    oldCmd = cmdMsg;
    cmdMsg = msg;
    post handleCommand();
    return oldCmd;
  }

  task void handleCommand() {
    struct FSOpMsg *cmd = (struct FSOpMsg *)cmdMsg->data;
    uint8_t *args = cmd->data;
    result_t opResult = SUCCESS;

    switch (cmd->op)
      {
      case FSOP_FREE_SPACE:
	*(filesize_t *)reply->data = call FileDir.freeBytes();
	sendResult(FS_OK, sizeof(filesize_t));
	break;

      case FSOP_DIR_START:
	opResult = call FileDir.start();
	if (opResult != FAIL)
	  sendResult0(FS_OK);
	break;

      case FSOP_DIR_READNEXT:
	dirEnding = FALSE;
	opResult = call FileDir.readNext();
	break;

      case FSOP_DIR_END:
	dirEnding = TRUE;
	opResult = call FileDir.readNext();
	break;

      case FSOP_DELETE: {
	char *fname;

	fname = extractString(&args);
	if (fname)
	  opResult = call FileDelete.delete(fname);
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_RENAME: {
	char *from, *to;

	from = extractString(&args);
	to = extractString(&args);
	if (from && to)
	  opResult = call FileRename.rename(from, to);
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_READ_OPEN: {
	char *fname;

	fname = extractString(&args);
	if (fname)
	  opResult = call FileRead.open(fname);
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_READ: {
	uint8_t count;

	count = extractU8(&args);
	if (count <= MAX_REMOTE_DATA)
	  opResult = call FileRead.read(reply->data + 1, count);
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_READ_CLOSE:
	// non-split-phase op
	opResult = call FileRead.close();
	if (opResult)
	  sendResult0(FS_OK);
	break;

      case FSOP_READ_REMAINING:
	opResult = call FileRead.getRemaining();
	break;

      case FSOP_WRITE_OPEN: {
	char *fname;
	uint8_t create, truncate;

	fname = extractString(&args);
	create = extractU8(&args);
	truncate = extractU8(&args);
	if (fname)
	  opResult = call FileWrite.open(fname,
					 (create ? FS_FCREATE : 0) |
					 (truncate ? FS_FTRUNCATE : 0));
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_WRITE: {
	uint8_t count;

	count = extractU8(&args);
	if (count <= MAX_REMOTE_DATA)
	  opResult = call FileWrite.append(args, count);
	else
	  sendResult0(FS_ERROR_REMOTE_BAD_ARGS);
	break;
      }
      case FSOP_WRITE_CLOSE:
	opResult = call FileWrite.close();
	break;

      case FSOP_WRITE_SYNC:
	opResult = call FileWrite.sync();
	break;

      case FSOP_WRITE_RESERVE:
	opResult = call FileWrite.reserve(extractFileSize(&args));
	break;

      default: 
	sendResult0(FS_ERROR_REMOTE_UNKNOWNCMD);
	break;
      }
    if (opResult == FAIL)
      sendResult0(FS_ERROR_REMOTE_CMDFAIL);
  }

  event result_t FileDir.nextFile(const char *filename, fileresult_t result) {
    if (dirEnding)
      {
	sendResult0(FS_OK);
	return FAIL;
      }
    else
      {
	safe_strcpy(reply->data, filename);
	sendResult(result, strlen(reply->data) + 1);
	return SUCCESS;
      }
  }

  event result_t FileDelete.deleted(fileresult_t result) {
    sendResult0(result);
    return SUCCESS;
  }
  
  event result_t FileRename.renamed(fileresult_t result) {
    sendResult0(result);
    return SUCCESS;
  }

  event result_t FileRead.opened(fileresult_t result) {
    sendResult0(result);
    return SUCCESS;
  }

  event result_t FileRead.readDone(void *buffer, filesize_t nRead,
				   fileresult_t result) {
    reply->data[0] = nRead;
    sendResult(result, nRead + 1);
    return SUCCESS;
  }

  event result_t FileWrite.opened(filesize_t fileSize, fileresult_t result) {
    *(filesize_t *)reply->data = fileSize;
    sendResult0(result);
    return SUCCESS;
  }

  event result_t FileWrite.closed(fileresult_t result) {
    sendResult0(result);
    return SUCCESS;
  }

  event result_t FileWrite.appended(void *buffer, filesize_t nWritten,
				    fileresult_t result) {
    reply->data[0] = nWritten;
    sendResult(result, 1);
    return SUCCESS;
  }

  event result_t FileWrite.synced(fileresult_t result) {
    sendResult0(result);
    return SUCCESS;
  }

  event result_t FileWrite.reserved(filesize_t reservedSize, fileresult_t result) {
    *(filesize_t *)reply->data = reservedSize;
    sendResult(result, sizeof(filesize_t));
    return SUCCESS;
  }

  event result_t FileRead.remaining(filesize_t n, fileresult_t result) {
    *(filesize_t *)reply->data = n;
    sendResult(result, sizeof(filesize_t));
    return SUCCESS;
  }
}
