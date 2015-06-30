/*
	Terminal.C
	
	Device Terminal Access
	Uros Platise (c) 1999
*/

#include <iostream.h>
#include <stdio.h>
#include <string.h>
#include "Global.h"
#include "Error.h"
#include "Terminal.h"
#include "MotIntl.h"

void TTerminal::Run(){
/*
  enableAvr ();
  if (isDeviceLocked ()) {
    string q;
    cout << "Do you want to clear it and enter normal mode now (enter y for yes): "; cin>>q;
    if (q=="y") { chipErase (); }
    else { return; }
  }
*/
  cout << "Entering the AVR Terminal. ?-help, q-quit.\n";
  char cmd[32];
  TAddr addr = 0;
  do {
    try {
      printf("avr>"); 
      scanf("%s",cmd);
      if (!strcmp(cmd,"?")){
	cout << "AVR Terminal supports the following commands:\n"
	  "ul fileName        - uploads data from Motorola/Intel format.\n"
	  "vf fileName        - verify file with memory\n"
/*	  
	  "dl fileName[%segs] - downloads data to Micro Output File\n"
*/	  
          "ls                 - list segments\n"
	  "ss seg_name        - set segment\n"
	  "ce                 - perform chip erase\n"
	  "rd addr            - read a byte from a segment\n"
	  "wr addr byte       - write a 'byte' to a segment at address 'addr'\n"
	  "du addr            - dump segment starting at address 'addr'\n"
	  ",                  - continue segment dump\n"
	  "\n"
	  "Written by Uros Platise (c) 1997-1999, uros.platise@ijs.si\n";
      }
      else if (!strcmp(cmd,"ul")) {
	char inputFileName [64]; scanf ("%s", inputFileName);
	try{
	  motintl.Read(inputFileName, true, false);
	}
	catch (Error_Device& errDev) { errDev.print (); }
	catch (Error_C) { perror ("Error"); }
      }
      else if (!strcmp(cmd,"vf")) {
	char inputFileName [64]; scanf ("%s", inputFileName);
	try{
	  motintl.Read(inputFileName, false, true);
	}
	catch (Error_Device& errDev) { errDev.print (); }
	catch (Error_C) { perror ("Error"); }
      }      
/*      
      else if (cmd=="dl") {
	char outputFileName [64]; scanf ("%s", outputFileName);
	try { 
	  TAout outAout (outputFileName, "wt");
	  download (&outAout); 
	}
	catch (Error_Device& errDev) { errDev.print (); }
	catch (Error_C) { perror ("Error"); }
      }
*/     
      else if (!strcmp(cmd,"ls")){
        printf("Available segments: ");
        const char* seg_name;
        for (unsigned i=0; (seg_name=device->ListSegment(i))!=NULL; i++){
	  if (i>0){printf(", ");}
	  printf("%s", seg_name);
	}
	putchar('\n');
      } 
      else if (!strcmp(cmd,"ss")){
        char seg_name [32];
	scanf("%s", seg_name);
	if (!device->SetSegment(seg_name)){
	  printf("Invalid segment: `%s'\n", seg_name);
	} else {addr=0;}
      }       
      else if (!strcmp(cmd,"ce")){ 
	device->ChipErase();
      }
/*      
      else if (cmd=="rsb") {
	unsigned char byte = readLockBits ();
	printf ("Lock and Fuse bits status: %.2x\n", byte );
      }
      else if (cmd=="wlb") {
	string mode; cin >> mode;
	if (mode=="wr") { writeLockBits (lckPrg);
	} else if (mode=="rdwr") { writeLockBits (lckPrgRd); 
	} else { cout << "Invalid parameter: " << mode << '\n'; }
      }
*/      
      else if (!strcmp(cmd,"rd")){
	scanf ("%x", &addr);
	printf("%s: $%.2x\n", 
	  device->TellActiveSegment(), device->ReadByte(addr));
      }
      else if (!strcmp(cmd,"wr")){
        unsigned x;
	scanf("%x%x", &addr, &x);
	device->WriteByte(addr, TByte(x));
      }
      else if (!strcmp(cmd,"du")){
	scanf ("%x", &addr);
	goto list_contents;
      }
      else if (!strcmp(cmd,",")){
list_contents:
	int i,l=0;
	while (l<4) {
	  printf ("%s $%.5x: ", device->TellActiveSegment(), addr); 
	  for (i=0; i<0x8; addr++,i++) 
	    printf ("%.2x ", device->ReadByte(addr));
	  cout << '\n';
	  l++;
	}  
      }
      else cout << "Ouch.\n";
      
    } catch (Error_MemoryRange){Info(0,"Out of memory range!\n");putchar('\n');}
  } while (strcmp(cmd,"q"));
}
