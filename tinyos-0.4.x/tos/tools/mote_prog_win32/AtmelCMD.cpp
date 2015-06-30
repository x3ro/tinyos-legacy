#include "PCH.h" // common MicroSoft/Borland Headers
/*
  termAvr.C

  Terminal Access to AVR mpu
  Uros Platise (c) 1997
*/

#include "AtmelCMD.h"// this is the header file for this source code
//------------------------------------------------------------------------------
void TAtmelCMD::Do (int argc, char* argv[])
{
   enableAvr ();
   if(isDeviceLocked ())
   {
      printf ( "Do you want to clear it and continue "
               "programming (enter y for yes): " );
      char buf[20]; scanf ("%s", buf);
      printf ("\n");
      if(strcmp (buf, "y")==0)
         chipErase ();

      else
         return;
   }
   printf ("\n");
   if(argc<2)
      printf ("Add --help switch for help.\n");

   for(int argI=1; argI<argc; argI++)
   {
      if(strcmp (argv[argI], "--help")==0)
      {
         printf ("Command line options:\n"
                 "  --erase                          "
                 "chip erase - place it before anyone below\n"
                 "  --upload filename[%%filters]      "
                 "uploads Micro Asm's output file\n"
                 "  --verify filename[%%filters]      "
                 "verifies/compares file data with memory\n"
                 "  --download filename[%%filters]    "
                 "downloads to Micro Asm's output file\n"
                 "  --lock[wr|rdwr]                 "
                 "set lock bits (wr=write,rd=read)\n"
                 "\n"
                 "The --lock option must be placed after upload/download option.\n"
                 "filters are used to specify which segments are to be used in\n"
                 "downloading or uploading process. Examples:\n"
                 "  --upload a.out%%flash            uploads program only\n"
                 "  --download a.out%%eeprom,flash   downloads flash and eeprom memory\n" );
      }
      else if(strcmp (argv[argI], "--erase")==0)
         chipErase ();

      else if(strcmp (argv[argI], "--upload")==0)
      {
         argI++;
         if(argI>=argc)
         {
            throw Error_Device ("Filename is missing.");
         }
         TAout inAout (argv[argI], "rt");
         upload (&inAout);
      }
      else if(strcmp (argv[argI], "--verify")==0)
      {
         argI++;
         if(argI>=argc)
         {
            throw Error_Device ("Filename is missing.");
         }
         TAout inAout (argv[argI], "rt");
         upload (&inAout, true);
      }
      else if(strcmp (argv[argI], "--download")==0)
      {
         argI++;
         if(argI>=argc)
         {
            throw Error_Device ("Filename is missing.");
         }
         TAout outAout (argv[argI], "wt");
         download (&outAout);
      }
      else if(strcmp (argv[argI], "--lock")==0)
      {
         argI++;
         if(argI>=argc)
         {
            throw Error_Device ("Lock mode is missing.");
         }
         if(strcmp (argv[argI], "wr")==0)
         {
            writeLockBits (lckPrg);
            printf ("Device is now locked for writing.\n");
         }
         else if(strcmp (argv[argI], "rdwr")==0)
         {
            writeLockBits (lckPrgRd);
            printf ("Device is now locked for reading and writing.\n");
         }
      }
      else
      {
         printf ("Invalid option: %s\n", argv[argI]);
         return;
      }
   }
}
