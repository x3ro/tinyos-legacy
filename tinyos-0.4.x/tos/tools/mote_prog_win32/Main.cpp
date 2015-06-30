#include "PCH.h" // common MicroSoft/Borland Headers
//#pragma argsused
/*
  Main.C

  Micro In-System Programmer
  Uros Platise (C) 1997
*/

/* dummy AVR terminal - for non-standard programmators */
#include "AvrTerm.h"
#include "AvrCmd.h"

/* ATMEL STANDARD PROGRAMMATOR */
#include "AtmelTerm.h"
#include "AtmelCMD.h"
#include "IO_Cards.h"
const char* help = "Syntax: uisp device mode[chip_number] optional parameters\n";



/*
** Start-UP
*/
int main(int argc, char* argv[])
{


/*	{
		TAout* aout = new TAout ("main.srec", "rt");         
   unsigned char read_buf[BufferSize];
   char segName_buf[32];
   TDataQuery rdQ;

   rdQ.segName = segName_buf;
   rdQ.buf = read_buf;
   for (unsigned i=0; i<BufferSize; i++)
       read_buf[i] = 0; // clear buffer

   while(aout->readData (&rdQ)>0){
		printf ("%s: %04Xh bytes to %s at %04Xh",
              "Uploading",
              rdQ.size, rdQ.segName, rdQ.offset);

   }
   FILE* file;
   file = fopen("main.dump", "w");
   fwrite(rdQ.buf, rdQ.size, 1, file);
   fclose(file);
}*/



   bool StandardMode;
#ifdef PARALLEL_PORT_PROGRAMMER
   printf ("Micro In-System Programmer Version 0.1.6 via Parallel Port,\n"
#else
   printf ("Micro In-System Programmer Version 0.1.6 via TestFixture,\n");
   printf ("%s, %s\n",__DATE__,__TIME__);
#endif
   printf (" based on code from: Uros Platise\n");
   
   try
   {
      int ppbase=1;
         StandardMode = false;
         parport_base = ppbase;
         OpenTVicPort();
         if(!IsDriverOpened())
         { // driver error
            fprintf(stderr, "Unable to open IO Driver\n");
            exit(1);
         }
            // intialize card(s)
    
		 /*
		 SetHardAccess(true);
         if (ppbase != LPT1 && ppbase != LPT2)
            WritePort(ppbase+7, 0x85); // OUTPUT_OUTPUT_INPUT
      */
		TPartDB Part("Not specified");

            TcmdAvr cmdAvr(NULL, &Part);

            cmdAvr.Do(argc,argv);
      
   }
   catch(Error_C)
   {
      perror("Error");
   }
   catch(Error_Device& errDev)
   {
      errDev.print();
   }
   catch(TPartDB::UnknownPart)
   {
      printf("Unknown part.\n");
   }

  
   CloseTVicPort();
   return 0;
}

