package tools;

class FS {
    final static int FSOP_DIR_START = 0;
    final static int FSOP_DIR_READNEXT = 1;
    final static int FSOP_DIR_END = 2;
    final static int FSOP_DELETE = 3;
    final static int FSOP_RENAME = 4;
    final static int FSOP_READ_OPEN = 5;
    final static int FSOP_READ = 6;
    final static int FSOP_READ_CLOSE = 7;
    final static int FSOP_READ_REMAINING = 8;
    final static int FSOP_WRITE_OPEN = 9;
    final static int FSOP_WRITE = 10;
    final static int FSOP_WRITE_CLOSE = 11;
    final static int FSOP_WRITE_SYNC = 12;
    final static int FSOP_WRITE_RESERVE = 13;
    final static int FSOP_FREE_SPACE = 14;

    final static int FS_ERROR_REMOTE_UNKNOWNCMD = 0x80;
    final static int FS_ERROR_REMOTE_BAD_ARGS = 0x81;
    final static int FS_ERROR_REMOTE_CMDFAIL = 0x82;

    final static int FS_OK = 0;
    final static int FS_NO_MORE_FILES = 1;
    final static int FS_ERROR_NOSPACE = 2;
    final static int FS_ERROR_BAD_DATA = 3;
    final static int FS_ERROR_FILE_OPEN = 4;
    final static int FS_ERROR_NOT_FOUND = 5;
    final static int FS_ERROR_BAD_CRC = 6;
    final static int FS_ERROR_HW = 7;
}
