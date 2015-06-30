enum {
  FSOP_DIR_START,
  FSOP_DIR_READNEXT,
  FSOP_DIR_END,
  FSOP_DELETE,
  FSOP_RENAME,
  FSOP_READ_OPEN,
  FSOP_READ,
  FSOP_READ_CLOSE,
  FSOP_READ_REMAINING,
  FSOP_WRITE_OPEN,
  FSOP_WRITE,
  FSOP_WRITE_CLOSE,
  FSOP_WRITE_SYNC,
  FSOP_WRITE_RESERVE,
  FSOP_FREE_SPACE
};

enum {
  FS_ERROR_REMOTE_UNKNOWNCMD = 0x80,
  FS_ERROR_REMOTE_BAD_ARGS,
  FS_ERROR_REMOTE_CMDFAIL
};

struct FSOpMsg
{
  uint8_t op;
  uint8_t data[];
};

struct FSReplyMsg
{
  uint8_t op;
  fileresult_t result;
  uint8_t data[];
};

enum {
  AM_FSOPMSG = 0x42,
  AM_FSREPLYMSG = 0x54,
  MAX_REMOTE_DATA = DATA_LENGTH - offsetof(struct FSReplyMsg, data)
};
