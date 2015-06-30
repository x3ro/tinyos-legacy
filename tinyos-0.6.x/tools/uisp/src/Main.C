/*
  Main.C

  Micro In-System Programmer
  Uros Platise (C) 1997-1999
*/

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include "Terminal.h"
#include "MotIntl.h"
#include "AvrAtmel.h"
#include "Stk500.h"
#ifndef NO_DAPA
# include "AvrDummy.h"
#endif

/* Globals
*/

int argc;
const char** argv;
char* argv_ok;
unsigned verbose_level;

PDevice device;
TMotIntl motintl;
TTerminal terminal;

const char* version = "uisp version 20010909\n"
"(c) 1997-1999 Uros Platise, 2000-2001 Marek Michalkiewicz\n";

const char* help_screen =
"Syntax: uisp [-v{=level}] [-h] [--help] [--version] [--hash=perbytes]\n"
"             [-dprog=avr910|pavr|stk500]"
#ifndef NO_DAPA
" [-dprog=type]\n"
"             [-dlpt=address|/dev/parportX] [-dno-poll] [-dno-retry]\n"
"             [-dvoltage=...] [-dt_sck=time] [-dt_wd_{flash|eeprom}=time]"
#endif
"\n"
"             [-dserial=device] [-dpart=name|no]\n"
"             [-dspeed=1200|2400|4800|9600|19200|38400|57600|115200]"
"\n"
"             [--upload] [--verify] [--erase] [--lock] [if=input_file]\n"
"             [--download] [of=output_file]\n"
"             [--segment=flash|eeprom|fuse] [--terminal]\n\n"
"Programming Methods:\n"
"  -dprog=avr910    Standard Atmel Serial Programmer/Atmel Low Cost Programmer\n"
"         pavr      http://avr.jpk.co.nz/pavr/pavr.html\n"
"         stk500    Atmel STK500\n"
#ifndef NO_DAPA
"  -dprog=dapa|stk200|abb|avrisp|bsd|fbprg|dt006|dasa|dasa2  programmer type:\n"
"         dapa      Direct AVR Parallel Access\n"
"         stk200    Parallel Starter Kit STK200, STK300\n"
"         abb       Altera ByteBlasterMV Parallel Port Download Cable\n"
"         avrisp    Atmel AVR ISP (?)\n"
"         bsd       http://www.bsdhome.com/avrprog/ (parallel)\n"
"         fbprg     http://ln.com.ua/~real/avreal/adapters.html (parallel)\n"
"         dt006     http://www.dontronics.com/dt006.html (parallel)\n"
"         dasa      serial (RESET=RTS SCK=DTR MOSI=TXD MISO=CTS)\n"
"         dasa2     serial (RESET=TXD SCK=RTS MOSI=DTR MISO=CTS)\n"
"\n"
"Parallel Device Settings:\n"
"  -dlpt=       specify device name (Linux ppdev, FreeBSD ppi, serial)\n"
#ifndef NO_DIRECT_IO
"               or direct I/O parallel port address (0x378, 0x278, 0x3BC)\n"
#endif
"  -dno-poll    Program without data polling (a little slower)\n"
"  -dno-retry   Disable retries of program enable command\n"
"  -dvoltage    Set timing specs according to the power supply voltage in [V]\n"
"               (default 3.0)\n"
"  -dt_sck      Set minimum SCK high/low time in micro-seconds (default 5)\n"
"  -dt_wd_flash Set FLASH maximum write delay time in micro-seconds\n"
"  -dt_wd_eeprom Set EEPROM maximum write delay time in micro-seconds\n"
"               Use -v=3 option to see current settings.\n"
#endif
"\n"
"Atmel Low Cost Programmer Serial Device Settings:\n"
"  -dserial     Set serial interface as /dev/ttyS* (default /dev/avr)\n"
"  -dpart       Set target abbreviated name or number\n"
"               If -dpart is not given programmer's supported devices\n"
"               are listed. Set -dpart=auto for auto-select.\n"
"  -dspeed      Set speed of the serial interface (default 19200)\n"
"\n"
"Functions:\n"
"  --upload     Upload \"input_file\" to the AVR memory.\n"
"  --verify     Verify \"input_file\" (processed after the --upload opt.)\n"
"  --download   Download AVR memory to \"output_file\" or stdout.\n"
"  --erase      Erase device.\n"
"  --lock       Write lock bits.\n"
"  --segment    Set active segment (auto-select for AVA Motorola output)\n"
"\n"
"Files:\n"
"  if           Input file for the --upload and --verify functions in\n"
"               Motorola S-records (S1 or S2) or 16 bit Intel format\n"
"  of           Output file for the --download function in\n"
"               Motorola S-records format, default is standard output\n"
"\n"
"Other Options:\n"
"  -v           Set verbose level (-v equals -v=2, min/max: 0/3, default 1)\n"
"  --hash       Print hash (default is 32 bytes)\n"
"  --help -h    Help\n"
"  --version    Print version information\n"
"  --terminal   Invoke shell-like terminal\n"
"\n"
"Report bugs to: Marek Michalkiewicz <marekm@amelek.gda.pl>\n"
"Updates:        http://www.amelek.gda.pl/avr/uisp/\n";


/* Find command line parameter's value.
   It searches the command line parameters of the form:
   
	argv_name=value
	
   Returns pointer to the value. 
*/
const char* GetCmdParam(const char* argv_name, bool value_required=true){
  int argv_name_len = strlen(argv_name);
  for (int i=1; i<argc; i++){
    if (strncmp(argv_name, argv[i], argv_name_len)==0){
      if (argv[i][argv_name_len]==0){
        if (value_required){
	  throw Error_Device("Incomplete parameter", argv[i]);
	}
	argv_ok[i]=1;
        return &argv[i][argv_name_len];	
      }
      if (argv[i][argv_name_len]=='='){
        argv_ok[i]=1;
        return &argv[i][argv_name_len+1];
      }
    }
  }
  return NULL;
}

/* Print Status Information to the Standard Error Output.
*/
bool Info(unsigned _verbose_level, const char* fmt, ...){
  if (_verbose_level > verbose_level){return false;}
  va_list ap;
  va_start(ap,fmt); 
  vfprintf(stderr,fmt,ap);
  va_end(ap);
  return true;
}


int main(int _argc, const char* _argv[]){
  int return_val=0;
  argc = _argc;
  argv = _argv;
  verbose_level=1;  
  
  if (argc==1){
    Info(0, "%s: No command specified.\n", argv[0]); exit(1);
  }  
  argv_ok = (char *)malloc(argc);
  for (int i=1; i<argc; i++){argv_ok[i]=0;}    
  
  /* Help Screen? */
  if (GetCmdParam("-h", false) || GetCmdParam("--help", false)){
    printf("%s%s\n", version, help_screen);
    return 0;
  }
  if (GetCmdParam("--version", false)){
    printf("%s\n", version);
    return 0;
  }
  
  /* Setup Verbose Level */
  const char *p = GetCmdParam("-v",false);
  if (p!=NULL){
    if (*p==0){verbose_level=2;} else{verbose_level = atoi(p);}
  }

  /* Invoke Terminal or Command Line Batch Processing */
  try{
    const char* val;

    val = GetCmdParam("-dprog");
    /* backwards compatibility, -datmel is now -dprog=avr910 */
    if (GetCmdParam("-datmel", false))
      val = "avr910";
    if (strcmp(val, "avr910") == 0 || strcmp(val, "pavr") == 0) {
      /* Drop setuid privileges (if any - not recommended) before
	 trying to open the serial device, they are only needed for
	 direct I/O access (not ppdev/ppi) to the parallel port.  */
      setgid(getgid());
      setuid(getuid());
      device = new TAvrAtmel();
    }
    else if (strcmp(val, "stk500") == 0) {
      setgid(getgid());
      setuid(getuid());
      device = new TStk500();
    }
#ifndef NO_DAPA
    else if (val) {
      device = new TAvrDummy();
    }
#endif

    /* Check Device's bad command line params. */
    for (int i=1; i<argc; i++){
      if (argv_ok[i]==0 && strncmp(argv[i], "-d", 2)==0){
        Info(0,"Invalid parameter: %s\n", argv[i]); exit(1);
      }
    }    
    if (device()==NULL){
      throw Error_Device("Programming method is not selected.");
    }

    /* Set Current Active Segment */
    if ((val=GetCmdParam("--segment"))!=NULL){
      if (!device->SetSegment(val)){
	Info(0, "--segment=%s: bad segment name\n", val);
      }
    }

    	/* Device Operations: */

    if (GetCmdParam("--download", false)) {
      motintl.Write(GetCmdParam("of"));
    }

    if (GetCmdParam("--erase", false)){device->ChipErase();}

    /* Input file */
    if ((val=GetCmdParam("if"))) {
      if (GetCmdParam("--upload", false)){motintl.Read(val, true, false);}
      if (GetCmdParam("--verify", false)){motintl.Read(val, false, true);}
    }

    if (GetCmdParam("--lock", false)){device->WriteLockBits(0xFC);}

    	/* enter terminal */ 
	
    if (GetCmdParam("--terminal", false)){terminal.Run();}
    
    /* Check bad command line parameters */
    for (int i=1; i<argc; i++){
      if (argv_ok[i]==0){Info(0,"Invalid parameter: %s\n", argv[i]);}
    }  
  } 
  catch(Error_C){perror("Error"); return_val=1;}
  catch(Error_Device& errDev){errDev.print(); return_val=2;}
  catch(Error_MemoryRange& x){
    Info(0, "Address out of memory range.\n"); return_val=3;
  }    
  free(argv_ok);
  return return_val;
}

