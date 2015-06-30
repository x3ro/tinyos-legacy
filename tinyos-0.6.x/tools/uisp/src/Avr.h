/*
	Avr.h
	
	Top class of the AVR micro controllers 
	Uros Platise (c) 1999
*/

#ifndef __AVR
#define __AVR

#include "Global.h"

/* Flags for device features: */

/* Old command (LB1=b7, LB2=b6) for Read Lock and Fuse Bits.  */
#define AVR_LOCK_RD76	0x0001

/* New command (LB1=b1, LB2=b2) for Read Lock Bits.  */
#define AVR_LOCK_RD12	0x0002

/* Read/Write Boot Lock Bits (BLB12,11,02,01,LB2,LB1=b5...b0).  */
#define AVR_LOCK_BOOT	0x0004

/* Read Fuse Bits (0x50) command supported.  */
#define AVR_FUSE_RD	0x0008

/* Old command (bits 0-4 of byte 2) for Write Fuse Bits.  */
#define AVR_FUSE_OLDWR	0x0010

/* New command (all bits of byte 4) for Write Fuse (Low) Bits.  */
#define AVR_FUSE_NEWWR	0x0020

/* Read/Write Fuse High Bits.  */
#define AVR_FUSE_HIGH 	0x0040

/* Read Calibration Byte.  */
#define AVR_CAL_RD	0x0080

/* Data Polling supported for Flash page write.  */
#define AVR_PAGE_POLL	0x0100

/* Data Polling supported for byte write (XXX not on AT90S1200?).  */
#define AVR_BYTE_POLL	0x0200

/* Has 3 bytes of fuse bits (ATmega128).  */
#define AVR_FUSE_EXT	0x0400

/* Sets of the above flags ORed for different classes of devices.  */

#define AVR_1200 0  /* XXX no polling */
#define AVR_2313 (AVR_BYTE_POLL)
#define AVR_TN22 (AVR_BYTE_POLL | AVR_LOCK_RD76)
#define AVR_8535 (AVR_BYTE_POLL | AVR_LOCK_RD76 | AVR_FUSE_OLDWR)
#define AVR_4433 (AVR_BYTE_POLL | AVR_LOCK_RD12 | AVR_FUSE_RD | AVR_FUSE_OLDWR)
#define AVR_M103 (AVR_BYTE_POLL | AVR_LOCK_RD12 | AVR_FUSE_RD | AVR_FUSE_OLDWR)
#define AVR_TN12 (AVR_BYTE_POLL | AVR_LOCK_RD12 | AVR_FUSE_RD | AVR_FUSE_NEWWR \
		  | AVR_CAL_RD)
#define AVR_TN15 (AVR_BYTE_POLL | AVR_LOCK_RD12 | AVR_FUSE_RD | AVR_FUSE_NEWWR)
#define AVR_M161 (AVR_BYTE_POLL | AVR_PAGE_POLL | AVR_LOCK_BOOT | AVR_FUSE_RD \
		  | AVR_FUSE_NEWWR)
#define AVR_M163 (AVR_BYTE_POLL | AVR_PAGE_POLL | AVR_LOCK_BOOT | AVR_FUSE_RD \
		  | AVR_FUSE_NEWWR | AVR_CAL_RD | AVR_FUSE_HIGH)
#define AVR_M128 (AVR_BYTE_POLL | AVR_PAGE_POLL | AVR_LOCK_BOOT | AVR_FUSE_RD \
		  | AVR_FUSE_NEWWR | AVR_CAL_RD | AVR_FUSE_HIGH | AVR_FUSE_EXT)

#define AVR_MIN_VOLTAGE		2.7	/* V */
#define AVR_MAX_VOLTAGE		6.0	/* V */
#define AVR_DEFAULT_VOLTAGE	3.0	/* V */

class TAvr: public TDevice{
private:
  /* AVR Family Device (Part) List */
  struct TPart {
    const char* name;
    TByte part_family;
    TByte part_number;
    TAddr flash_size;
    TAddr flash_page_size;
    TAddr eeprom_size;
    long t_wd_flash_50;    	/* flash programming delay at 5.0 V */
    long t_wd_eeprom_50;
    unsigned int flags;
  };  
  
  static const TPart parts[];
  const TPart* part;
  bool device_locked;   
  long t_wd_flash;
  long t_wd_eeprom;

protected:
  enum TSegment{SEG_FLASH=0, SEG_EEPROM=1, SEG_FUSE=2};
  
  /* ATmega page programming */  
  TAddr page_size;
  TAddr page_addr_fetched;	/* Becomes true when first byte is written */
  TAddr page_addr;		/* Fetched Page Address */
  /* Page Write Polling */
  TAddr page_poll_addr;  /* address of the last non-0xFF byte written */
  TByte page_poll_byte;  /* value of the last non-0xFF byte written */
  
  /* Variables and Functions */
private:
  TAddr GetWritePageSize();
  void SetWriteTimings();

protected:  
  int segment;
  static const char* segment_names[];
  
  /* AVR Signs/Info */
  TByte vendor_code;
  TByte part_family;
  TByte part_number;
  
  void Identify();
  void OverridePart(const char *);
  const char* GetPartName();  
  TAddr GetSegmentSize();
  bool TestFeatures(unsigned int mask);
  void CheckMemoryRange(TAddr addr);  
  long Get_t_wd_flash() const;
  long Get_t_wd_eeprom() const;    
  long Get_t_wd_erase() const;

public:
  /* Set active segment. 
     Returns true if segment exists, otherwise false 
  */
  bool SetSegment(const char* segment_name);
  
    /* Returns char pointer of current active segment name.
  */
  const char* TellActiveSegment();
  
  /* Returns char pointer of the indexed segment name.
     Index is in range [0,no_of_segments].
     When index is out of range NULL is returned.
  */
  const char* ListSegment(unsigned index);

  /* Read byte description at address addr (as security bits) */
  const char* ReadByteDescription(TAddr addr);
  
  TAvr();
  ~TAvr();
};

#endif
