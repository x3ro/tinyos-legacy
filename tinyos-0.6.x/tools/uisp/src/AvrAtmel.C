/*
	AvrAtmel.C
	
	Device driver for the Serial Atmel Low Cost Programmer
	Uros Platise (c) 1999
*/

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "AvrAtmel.h"

#define AUTO_SELECT	0

/* Low Cost Atmel Programmer AVR Codes
   Valid for software version: SW_MAJOR=2 SW_MINOR=0
   
   Code 0xff is reserved for invalid code. Update the
   TAvrAtmel constructor if Atmel comes up with it.
*/
TAvrAtmel::SPrgPart TAvrAtmel::prg_part [] = {
  /* 0x10, 0x11 = AT90S1200 rev. A, B (very old) */
  {"S1200C", 0x12, "AT90S1200 Revision C", false}, /* old */
  {"S1200D", 0x13, "AT90S1200 Revision D", false},
  {"S2313A", 0x20, "AT90S2313 Revision A", false},
  {"S2323A", 0x48, "AT90S2323 Revision A", false},
  {"S4414A", 0x28, "AT90S4414 Revision A", false},
  {"S8515A", 0x38, "AT90S8515 Revision A", false},
  {"S8252",  0x86, "AT89S8252", false},
  {"S01838C",0x40, "ATmega103 Revision C", false}, /* old */
  {"S01838D",0x41, "ATmega103 Revision D", false},
#if 1
  /* more device codes, mostly reverse-engineered from avrprog.exe that
     comes with AVR Studio (but where is the updated avr910.asm ???
     version 2.0 updated 1998-01-06 only handles the above devices).
     XXX - ATtiny22 is missing from avrprog.exe (should work as a 2343).  */

  {"S4433",  0x30, "AT90S4433", false},
  {"S2333",  0x34, "AT90S2333", false},
	  /* 0x38 = AT90S8515 */
	  /* 0x40 = ATmega103 rev. C (old) */
	  /* 0x41 = ATmega103 */
  {"M603",   0x42, "ATmega603", false},
	  /* 0x48 = AT90S2323 */
  {"S2343",  0x4C, "AT90S2343", false}, /* ATtiny22 ??? */
  {"TN11",   0x50, "ATtiny11",  false}, /* parallel */
  {"TN10",   0x51, "ATtiny10",  false}, /* parallel */
  {"TN12",   0x55, "ATtiny12",  false},
  {"TN15",   0x56, "ATtiny15",  false},
  {"TN19",   0x58, "ATtiny19",  false}, /* parallel ??? */
  {"TN28",   0x5C, "ATtiny28",  false}, /* parallel */
  {"M161",   0x60, "ATmega161", false},
  {"M163",   0x64, "ATmega163", false},
  {"M83",    0x65, "ATmega83",  false},
  {"AVR109", 0x66, "AVR109",    false}, /* self programming, AVR109 app note */
  {"S8535",  0x68, "AT90S8535", false},
  {"S4434",  0x6C, "AT90S4434", false},
  {"C8534",  0x70, "AT90C8534", false}, /* parallel */
  {"M323",   0x72, "ATmega323", false},
  {"89C2051",0x81, "AT89C2051", false}, /* parallel */
  {"89C51",  0x82, "AT89C51",   false}, /* parallel */
  {"89LV51", 0x83, "AT89LV51",  false}, /* parallel */
  {"89C52",  0x84, "AT89C52",   false}, /* parallel */
  {"89LV52", 0x85, "AT89LV52",  false}, /* parallel */
	  /* 0x86 = AT89S8252 */
  {"89S53",  0x87, "AT89S53",   false},
  /* 0x88..0xDF reserved for AT89,
     0xE0..0xFF reserved */
#endif
  {"auto",   AUTO_SELECT, "Auto detect", false},  
  {"",       0x00, "", false}
};

/* Private Functions
*/

void TAvrAtmel::EnterProgrammingMode(){
  /* Select Device Type */
  TByte set_device[2] = {'T', desired_avrcode};
  Send(set_device, 2, 1);
  CheckResponse(set_device[0]);

  /* Enter Programming Mode */
  TByte enter_prg[1] = {'P'};
  Send(enter_prg, 1);
  CheckResponse(enter_prg[0]);

  /* Read Signature Bytes */
  TByte sig_bytes[3] = {'s', 0, 0};
  Send(sig_bytes, 1, 3);
  part_number = sig_bytes[0];
  part_family = sig_bytes[1];
  vendor_code = sig_bytes[2];
}

void TAvrAtmel::LeaveProgrammingMode(){
  TByte leave_prg [1] = { 'L' };
  Send(leave_prg, 1);    
}

void TAvrAtmel::CheckResponse(TByte x){
  if (x!=13){throw Error_Device ("Device is not responding correctly.");}
}

void TAvrAtmel::EnableAvr(){
  bool auto_select = desired_avrcode == AUTO_SELECT;
  
  for (unsigned pidx=0; prg_part[pidx].code != AUTO_SELECT; pidx++){
  
    if (!prg_part[pidx].supported && auto_select){continue;}
    if (auto_select){
      desired_avrcode = prg_part[pidx].code;
      Info(2, "Trying with: %s\n", prg_part[pidx].description);
    }    
    EnterProgrammingMode();
    if (!auto_select ||
        !(vendor_code==0 && part_family==1 && part_number==2)){
      break;
    }
    LeaveProgrammingMode();    
  }

 // OverridePart("atmega163"); // XXXXX local hack for broken signature bytes
  
  Identify();
  
  if (auto_select){
    /* If avr was recongnized by the Identify(), try to find better match
       in the support list.
    */    
    unsigned better_pidx = 0;
    TByte better_avrcode = desired_avrcode;
    
    for (unsigned pidx=0; prg_part[pidx].code != AUTO_SELECT; pidx++){
      if (!prg_part[pidx].supported){continue;}      
      if (strstr(prg_part[pidx].description, GetPartName())){
        better_avrcode = prg_part[better_pidx = pidx].code;
      }
    }
    if (better_avrcode != desired_avrcode){
      Info(2, "Retrying with better match: %s\n", 
        prg_part[better_pidx].description);
      desired_avrcode = better_avrcode;
      LeaveProgrammingMode();
      EnterProgrammingMode();
      Identify();
    }
  }
}

void TAvrAtmel::SetAddress(TAddr addr){
  apc_address = addr;
  TByte setAddr [3] = { 'A', (addr>>8)&0xff, addr&0xff};
  Send(setAddr, 3, 1);
  CheckResponse(setAddr [0]);
}

void TAvrAtmel::WriteProgramMemoryPage(){
  SetAddress(page_addr >> 1);
  TByte prg_page [1] = { 'm' };
  Send(prg_page, 1);    
}

/* Device Interface Functions
*/

TByte TAvrAtmel::ReadByte(TAddr addr){
  CheckMemoryRange(addr);
  if (segment==SEG_FLASH){
    TAddr saddr = addr>>1;
    TByte rdF [2] = { 'R', 0 };
    
    if (buf_addr==addr && cache_lowbyte==true){return buf_lowbyte;}
    if (apc_address!=saddr || apc_autoinc==false) SetAddress(saddr);    
    apc_address++;
    Send(rdF, 1, 2);
    /* cache low byte */
    cache_lowbyte = true;
    buf_addr = (saddr<<1) + 1;
    buf_lowbyte = rdF[0];
    return rdF [1 - (addr&1)];
  }
  else if (segment==SEG_EEPROM){    
    SetAddress(addr);
    TByte readEE [1] = { 'd' };    
    Send(readEE, 1);
    return readEE[0];
  }
  else return 0;
}

void TAvrAtmel::WriteByte(TAddr addr, TByte byte, bool flush_buffer){
  CheckMemoryRange(addr);
  
  /* do not check if byte is already written -- it spoils auto-increment
     feature which reduces the speed for 50%!
  */     
  if (segment==SEG_FLASH){
  
    cache_lowbyte = false;		/* clear read cache buffer */  
    if (!page_size && byte==0xff) return;
  
    /* PAGE MODE PROGRAMMING:
       If page mode is enabled cache page address.
       When current address is out of the page address
       flush page buffer and continue programming.
    */  
    if (page_size){
      Info(4, "Loading data to address: %d (page_addr_fetched=%s)\n", 
	addr, page_addr_fetched?"Yes":"No");

      if (page_addr_fetched && page_addr != (addr & ~(page_size - 1))){
	WriteProgramMemoryPage();
	page_addr_fetched = false;
      }
      if (page_addr_fetched==false){
	page_addr=addr & ~(page_size - 1);
	page_addr_fetched=true;
      }
      if (flush_buffer){WriteProgramMemoryPage();}
    }
    
    TByte wrF [2] = { (addr&1)?'C':'c', byte };
    
    if (apc_address!=(addr>>1) || apc_autoinc==false) SetAddress (addr>>1);
    if (wrF[0]=='C') apc_address++;
    Send(wrF, 2, 1);
    CheckResponse(wrF[0]);
  }
  else if (segment==SEG_EEPROM){
    SetAddress(addr);
    TByte writeEE [2] = { 'D', byte };
    Send(writeEE, 2, 1);
    CheckResponse(writeEE[0]);
  }  
}

void TAvrAtmel::FlushWriteBuffer(){
  if (page_addr_fetched){
    WriteProgramMemoryPage();  
  }
}

void TAvrAtmel::ChipErase(){
  TByte eraseTarget [1] = { 'e' };
  Send (eraseTarget, 1);
  CheckResponse(eraseTarget [0]);
  Info(1, "Erasing device ...\nReinitializing device\n");
  EnableAvr();
}

void TAvrAtmel::WriteLockBits(TByte bits){
  TByte lockTarget [2] = { 'l', 0xF9 | ((bits << 1) & 0x06) };
  Send (lockTarget, 2, 1);
  CheckResponse(lockTarget [0]);
  Info(1, "Writing lock bits ...\nReinitializing device\n");
  EnableAvr();
}

/* Constructor/Destructor
*/

TAvrAtmel::TAvrAtmel():
  cache_lowbyte(false), apc_address(0x10000), apc_autoinc(false)
  {

  /* Select Part by Number or Name */
  desired_avrcode=0xff;
  const char* desired_partname = GetCmdParam("-dpart");
  bool got_device=false;
  
  if (desired_partname!=NULL) {
    if (desired_partname[0] >= '0' && desired_partname[0] <= '9'){
      desired_avrcode = strtol(&desired_partname[0],(char**)NULL,16); 
    } else{
      int j;
      for (j=0; prg_part[j].name[0] != 0; j++){
	if (strcmp (desired_partname, prg_part[j].name)==0){
	  desired_avrcode = prg_part[j].code;
	  break;
	}
      }
      if (prg_part[j].name[0]==0){throw Error_Device("-dpart: Invalid name.");}
    }
  }
  
  /* check: software version and supported part codes */
  TByte sw_version [2] = {'V', 0};
  TByte hw_version [2] = {'v', 0};
  Send(sw_version, 1, 2);
  Send(hw_version, 1, 2);
  Info(1, "Programmer Information:\n"
          "  Software Version: %c.%c, Hardware Version: %c.%c\n", 
	  sw_version [0], sw_version [1],
	  hw_version [0], hw_version [1]);
  
  /* Detect Auto-Increment */
  if (sw_version[0]>='2'){
    apc_autoinc=true;
    Info(2, "Address Auto Increment Optimization Enabled\n");
  }
  
  /* Retrieve supported codes */
  TByte sup_codes[1] = {'t'};
  TByte sup_prg_code[32];
  Tx(sup_codes, 1);
  TByte buf_code;
  timeval timeout = {1, 0};
  int i=0;
  if (desired_partname==NULL){
    Info(1, "  Supported Parts:\n\tNo\tAbbreviation\tDescription\n");
  }
  do{
    Rx(&buf_code, 1, &timeout);
    sup_prg_code[i++] = buf_code;
    if (buf_code==0){break;}    
    if (desired_partname!=NULL){ 
      if (buf_code==desired_avrcode){got_device=true;}
      if (desired_avrcode!=AUTO_SELECT) continue; 
    }
    int j;
    for (j=0; prg_part[j].name[0] != 0; j++){
      if (prg_part[j].code == buf_code){
        prg_part[j].supported = true;
	if (desired_avrcode!=AUTO_SELECT){
	  Info(1, "\t%.2x\t%s\t\t%s\n", 
	    buf_code, prg_part[j].name, prg_part[j].description);
	}
	break;
      }
    }
    if (prg_part[j].code == 0) {
      Info(1, "    - %.2xh (not on the uisp's list yet)\n", buf_code);
    }
  } while (1);  
  Info(1, "\n");
  
  if (got_device==false) {
    if (desired_partname==NULL){
      throw Error_Device("Select a part from the list with the: -dpart\n"
        "or use the -dpart=auto option for auto-select.\n");
    } 
    else if (desired_avrcode!=AUTO_SELECT){
      throw Error_Device("Programmer does not supported chosen device.");
    }
  }
  
  EnableAvr();
}

TAvrAtmel::~TAvrAtmel(){
  /* leave programming mode! Due to this 
     procedure, enableAvr had to be taken out
     of TAtmelAvr::TAtmelAvr func. */
  LeaveProgrammingMode();
}
