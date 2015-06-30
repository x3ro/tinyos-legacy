#include "PCH.h" // common MicroSoft/Borland Headers
/*
  cmdAvr.C

  command line access to parallel dummy programmer
  Uros Platise (c) 1997,1999

  This is very fast port from AtmelCMD.C. Some functions like bit
  locking is not yet supported.
*/

#include "AvrCmd.h"// this is the header file for this source code
//------------------------------------------------------------------------------
void TcmdAvr::Do (int argc, char* argv[])
{
  enableAvr ();
   
  /*
    if (isDeviceLocked ()) {
    printf ( "Do you want to clear it and continue "
    "programming (enter y for yes): " );
    char buf[20]; scanf ("%s", buf);
    printf ("\n");
    if (strcmp (buf, "y")==0) { chipErase (); }
    else { return; }
    }
  */
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
		  "  --speed speed	"
		  "set the transfer speed 0->400 (0 is fastest, default = 200)\n"
		  "\n"
		  "The --lock option must be placed after upload/download option.\n"
		  "filters are used to specify which segments are to be used in\n"
		  "downloading or uploading process. Examples:\n"
		  "  --upload a.out%%flash            uploads program only\n"
		  "  --download a.out%%eeprom,flash   downloads flash and eeprom memory\n" );
	}
      else if(strcmp (argv[argI], "--erase")==0)
	chipErase ();
	
      else if(strcmp (argv[argI], "--ext_clock")==0)
	setExtClock();
      else if(strcmp (argv[argI], "--read_fuse")==0)
	read_fuse();
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
            throw Error_Device ("Filename is missing.");

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
      else if(strcmp (argv[argI], "--speed")==0)
	{
	  argI++;
	  if(argI>=argc)
	    {
	      throw Error_Device ("Speed is missing.");
	    }
          //set speed;
	  speed = atoi(argv[argI]);
	  printf("speed set to %d\n", speed);
	}	
      else if(strcmp (argv[argI], "--no_verify")==0)
	{
         
          NO_VERIFY = 1;
		  
	}	
      else
	{
	  printf ("Invalid option: %s\n", argv[argI]);
	  return;
	}
    }
}
