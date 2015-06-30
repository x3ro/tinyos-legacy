#ifndef FUNCLETS_H
#define FUNCLETS_H

#include "Basic_Types.h"
extern WORD ramsize;
extern void (*flash_callback)(WORD, WORD);

STATUS_T programFlash(WORD address, const CHAR* buffer, WORD count);
STATUS_T eraseFlash(WORD type, WORD address);
STATUS_T syncCPU(void);
STATUS_T executeCode(const WORD* code, WORD sizeCode, BOOL verify, BOOL wait);
int isHalted(void);
#endif //FUNCLETS_H
