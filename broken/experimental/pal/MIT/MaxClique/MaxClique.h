#include <AM.h>

enum {
  AM_CONNECT = 0x56,
  AM_CLIQUEMSG = 0x57,
  AM_CLIQUERESPONSEMSG = 0x58,
};

enum {
  CLIQUE_SIZE = TOSH_DATA_LENGTH / 2,
  QUALITY_THRESHOLD = 220,
};

typedef struct CliqueMsg {
  uint16_t elements[CLIQUE_SIZE];
} CliqueMsg;

enum {
  CLIQUE_REJECT,
  CLIQUE_ACCEPT,
};

typedef struct CliqueResponseMsg {
  uint16_t cliqueID;
  uint16_t address;
  uint8_t response;
} CliqueResponseMsg;
