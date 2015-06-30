#ifndef __GENERICSAMPLING_H__
#define __GENERICSAMPLING_H__

/******
functionInfo_t structure

field: function
description:  describes the function of the board that the paramname and paramval should be associated with

field: paramname
description:  unique parameter that is part of the "function field" namespace

field: paramval
description:  paramter associated with the paramname in question
****/

typedef struct{
  uint16_t  function;  
  uint16_t  paramname;  
  uint32_t paramval;  
} __attribute__((packed)) functionInfo_t;

/******
TypeValItem structure

field: count
description:  number of functionInfo_t structures in the array pointed to by functionInfo

field: functionInfo
description:  array of length count of functionInfo_t structures
****/

typedef struct{
  uint32_t count; //number of entries in the functionInfo structure array that follows.
  functionInfo_t *functionInfo; //array of functionInfo_t's
} __attribute__((packed)) TypeValItem;


//functionInfo_t function field defines
#define FI_FUNCTION_BOARD  (0xFFFF)
#define FI_FUNCTION_FFT    (0x0)
#define FI_FUNCTION_GSE    (0x1)
#define FI_FUNCTION_AVG    (0x2)


//parmname defs for BOARD FUNCTIONS
#define FIF_BOARD_LOGICALNODEID    (0x0)
#define FIF_BOARD_QUERYGROUPID     (0x1)
#define FIF_BOARD_ACQUISITIONNUM   (0x2)
#define FIF_BOARD_ACQUISITIONCOUNT (0x3)
#define FIF_BOARD_DESIREDUOM       (0x4)
#define FIF_BOARD_ENGINEERINGUOM   (0x5)
#define FIF_BOARD_OUTPUTUOM        (0x6)
#define FIF_BOARD_CONVERSIONVAL    (0x7)
#define FIF_BOARD_SENSORZERO       (0x8)

//parmname defs for FFT FUNCTIONS
#define FIF_FFT_NUMOUTPUTSAMPLES   (0x0)

//parmname defs for gSE FUNCTIONS
#define FIF_GSE_FILTERFREQ         (0x0)

//parmname defs for AVG FUNCTIONS
#define FIF_AVG_NUMAVERAGES        (0x0)



#endif
