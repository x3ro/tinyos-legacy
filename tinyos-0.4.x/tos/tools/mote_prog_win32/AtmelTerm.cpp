#include "PCH.h" // common MicroSoft/Borland Headers
/*
  termAvr.C

  Terminal Access to AVR mpu
  Uros Platise (c) 1997
*/

#include "AtmelTerm.h"// this is the header file for this source code
//------------------------------------------------------------------------------
void TAtmelTerm::Run ()
{
   enableAvr ();
   if(isDeviceLocked ())
   {
      string q;
      cout << "Do you want to clear it and enter normal mode now (enter y for yes): "; cin>>q;
      if(q=="y")
         chipErase ();

      else
         return;
   }
   cout << "Entering the AVR Terminal. ?-help, q-quit.\n";
   string cmd;
   long flash_addr = 0;
   long eeprom_addr = 0;
   char Buffer[20];
   int NumberOfDumpRows = 20, NumberOfDumpColumns = 0x10;
   THexType OutHexFormat = Intel;
   do
   {
      try
      {
         cout << "avr>"; cin >> cmd;
         if(cmd=="?")
         {
            cout << "AVR Terminal supports the following commands:\n"
            "ul fileName[%segs] - loads data from binary file\n"
            "vf fileName[%segs] - compare (verify) file with memory\n"
            "dl fileName[%segs] - downloads data to binary file\n"
            "b format           - sets the binary file format (UAsm, Motorola, Intel)\n"
            "                       (currently ";
            if(OutHexFormat == UAsm)
               cout << "UAsm)\n";
            else if(OutHexFormat == Motorola)
               cout << "Motorola)\n";
            else if(OutHexFormat == Intel)
               cout << "Intel)\n";

            cout <<
            "ce                 - perform chip erase option\n"
            "re addr            - read a byte from eeprom\n"
            "we addr byte       - write 'byte' to eeprom at address 'addr'\n"
            "rf addr            - read a word from flash memory\n"
            "wf addr byte       - write 'byte' to flash memory\n"
            "de addr            - dump eeprom starting at address 'addr'\n"
            "df addr            - dump flash memory starting at address 'addr'\n"
            "d rows,columns     - sets the row and columns for dumping memory\n"
            "                       (currently r=" << NumberOfDumpRows << ",c=" << NumberOfDumpColumns << ") \n"
            "rsb                - read lock and fuse bits\n"
            "wlb wr|rdwr        - write lock bits (wr=programming,rd=reading)\n"
            "\n"
            "To argument fileName segment names may be added seperated by\n"
            "comas. An example: 'ul a.out%flash' will upload only flash segments.\n"
            "'addr' and 'byte' are shown and must be entered in hex format.\n"
            "Written by Uros Platise (c) 1997, uros.platise@fov.uni-mb.si\n";
         }
         else if(cmd=="ul" || cmd == "vf")
         {
            char inputFileName[64];
            cin >> inputFileName;
            try
            {
               TAout inAout (inputFileName, "rt");
               if (cmd == "ul")
                 upload (&inAout, false);
               else
                 upload (&inAout, true);
            }
            catch(Error_Device& errDev)
            {
               errDev.print ();
            }
            catch(Error_C)
            {
               perror ("Error");
            }
         }
         else if(cmd=="dl")
         {
            char outputFileName[64];
            cin >> outputFileName;
            try
            {
               TAout outAout (outputFileName, "wt");
               download (&outAout, OutHexFormat);
            }
            catch(Error_Device& errDev)
            {
               errDev.print ();
            }
            catch(Error_C)
            {
               perror ("Error");
            }
         }
         else if(cmd=="b")
         {
            char Type[10];
            cin >> Type;
            if(stricmp ("uasm", Type)==0)
               OutHexFormat = UAsm;
            else if(stricmp ("motorola", Type)==0)
               OutHexFormat = Motorola;
            else if(stricmp ("intel", Type)==0)
               OutHexFormat = Intel;
            else
               cout << "New format not reconized '" << Type << "'\n";
         }
         else if(cmd=="ce")
            chipErase ();

         else if(cmd=="rsb")
         {
            unsigned char byte = readLockBits ();
            printf ("Lock and Fuse bits status: %.2x\n", byte );
         }
         else if(cmd=="wlb")
         {
            string mode; cin >> mode;
            if(mode=="wr")
               writeLockBits (lckPrg);

            else if(mode=="rdwr")
               writeLockBits (lckPrgRd);

            else
               cout << "Invalid parameter: " << mode << '\n';
         }
         else if(cmd=="re")
         {
            unsigned int addr;
            cin >> Buffer;  sscanf(Buffer, "%x", &addr);
            printf ("eeprom: $%.2x\n", readEEPROM (addr));
         }
         else if(cmd=="we")
         {
            unsigned int addr, byte;
            cin >> Buffer; sscanf (Buffer,"%x%x", &addr, &byte);
            writeEEPROM (addr, (unsigned char)byte);
         }
         else if(cmd=="rf")
         {
            unsigned int addr;
            cin >> Buffer;  sscanf(Buffer, "%x", &addr);
            printf ( "flash: $%.2x\n", readFLASH (addr));
         }
         else if(cmd=="wf")
         {
            unsigned int addr, byte;
            cin >> Buffer; sscanf (Buffer,"%x%x", &addr, &byte);
            writeFLASH (addr, (unsigned char)byte);
         }
         else if(cmd=="de")
         {
            cin >> Buffer; sscanf(Buffer, "%x", &eeprom_addr);
            cout << "Dumping EEPROM.  Press S to stop. Any other key to go on\n";
            do
            {
               for(int l=0; l<NumberOfDumpRows; l++)
               {
                  printf ("$%04x %c ", eeprom_addr, COLUMN_SEPERATOR);
                  for(int i=0; i<NumberOfDumpColumns; i++)
                  {
                     unsigned char Value = readEEPROM(eeprom_addr);
                     printf ("%.2x ", Value);
                     Buffer[i] = Value;
                     Buffer[i+1] = NULL;
                     ++eeprom_addr;
                  }
                  cout << COLUMN_SEPERATOR << " " << Buffer << '\n';
                  if(eeprom_addr >= segEeprom->size-1) break;
               }
               if(eeprom_addr >= segEeprom->size-1) break;
               Buffer[0] = getch();
            } while(Buffer[0] != 's' && Buffer[0] != 'S');
         }
         else if(cmd=="df")
         {
            cin >> Buffer; sscanf(Buffer, "%x", &flash_addr);
            cout << "Dumping flash.  Press S to stop. Any other key to go on\n";
            do
            {
               for(int l=0; l<NumberOfDumpRows; l++)
               {
                  printf ("$%04x %c ", flash_addr, COLUMN_SEPERATOR);
                  for(int i=0; i<NumberOfDumpColumns; i++)
                  {
                     unsigned char Value = readFLASH (flash_addr);
                     printf ("%.2x ", Value);
                     Buffer[i] = Value;
                     Buffer[i+1] = NULL;
                     ++flash_addr;
                  }
                  cout << COLUMN_SEPERATOR << " " << Buffer << '\n';
                  if(flash_addr >= segFlash->size-1) break;
               }
               if(flash_addr >= segFlash->size-1) break;
               Buffer[0] = getch();
            } while(Buffer[0] != 's' && Buffer[0] != 'S');
         }
         else if(cmd=="d")
         {
            cin >> Buffer;
            sscanf(Buffer, "%d,%d", &NumberOfDumpRows, &NumberOfDumpColumns);
         }
         else if(cmd=="q")
         {
         }
         else
            cout << "Ouch.\n";
      }
      catch(Error_MemoryRange)
      {
         printf ("Out of memory range!\n");
      }
   } while(cmd!="q");
}
