#ifndef __MGMTATTRS_H__
#define __MGMTATTRS_H__

enum {
  MGMT_ATTRS = uniqueCount("MgmtAttr"),
};

enum {
  MA_TYPE_INT,
  MA_TYPE_UINT,
  MA_TYPE_OCTETSTRING,
  MA_TYPE_TEXTSTRING,
  MA_TYPE_BITSTRING,
  MA_TYPE_UNIXTIME,
  MA_TYPE_SPECIAL,
};

typedef uint16_t MgmtAttrID;

typedef struct MgmtAttrDesc {
  uint8_t len;
} MgmtAttrDesc;

#endif // __MGMTATTRS_H__
