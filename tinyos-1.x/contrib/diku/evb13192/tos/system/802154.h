
#ifdef INCLUDEFREESCALE802154
#include "802_15_4.h"
#include "AbelReg.h"
#include "Phy_Spi.h"
extern uint8_t gSeqPowerSaveMode;
//extern const uint8_t aExtendedAddress[8];
/* These defines should be synchronized with NV_Data.h always. */
#define NV_SYSTEM_FLAG  ((uint8_t)0x55)
#define ABEL_CCA_ENERGY_DETECT_THRESHOLD 0x9600
#define ABEL_POWER_COMPENSATION_OFFSET   0x0074
// This is the NV RAM layout. The layout covers a whole physical flash sector
 // (512 bytes) in HCS08. The NV RAM data while be copied to another physical sector
 // when updated.
 typedef struct NV_RAM_Struct
 {
         const uint8_t Freescale_Copyright[54];
         const uint8_t Firmware_Database_Label[40];
         const uint8_t MAC_Version[47];
         const uint8_t PHY_Version[47];
         const uint8_t Target_Version[48];
         const uint8_t FreeLoader_Firmware_Version[52];
         const uint16_t NV_RAM_Version;
         const uint8_t MCU_Manufacture;
         const uint8_t MCU_Version;
         const uint8_t Bus_Frequency_In_MHz;
         const uint16_t Abel_Clock_Out_Setting;
         const uint16_t Abel_HF_Calibration;
         const uint8_t NV_ICGC1;
         const uint8_t NV_ICGC2;
         const uint8_t NV_ICGFLTU;
         const uint8_t NV_ICGFLTL;
         const uint8_t NV_SCI1BDH;
         const uint8_t NV_SCI1BDL;
         const uint8_t MAC_Address[8];
         const uint8_t AntennaSelect;
         const uint8_t SleepModeEnable;
         const uint8_t HWName_Revision[20];
         const uint8_t SerialNumber[10];
         const uint16_t ProductionSite;
         const uint8_t CountryCode;
         const uint8_t ProductionWeekCode;
         const uint8_t ProductionYearCode;
         const uint8_t Application_Section[163];
         const uint8_t System_Flag; // Must not be changed
 } NV_RAM_Struct_t;
// #include "NV_Data.h"

// NOTE: This pointer declaration have been moved to hcs08MangleAppC.pl
//#pragma DATA_SEG NV_RAM_POINTER
//volatile NV_RAM_Struct_t * NV_RAM_ptr;
//#pragma DATA_SEG default
//extern volatile NV_RAM_Struct_t * NV_RAM_ptr;
// extern void ICG_Setup(void); // Unsure about this one, actually.
extern void PHY_HW_Setup(void);
extern void AbelRegisterSetup(void);

// Include the tinyos defines.
//#include "IEEE802154.h"
#endif
