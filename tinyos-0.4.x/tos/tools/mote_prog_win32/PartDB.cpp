#include "PCH.h" // common MicroSoft/Borland Headers
/*
  PartDB.C

  Part Database
  Uros Platise (c) 1997
*/

#include "PartDB.h"// this is the header file for this source code
//------------------------------------------------------------------------------
TPartDB::TPart TPartDB::parts[] = {
   { "at90s1200", FAMILY_AVR, AVR_AT90S1200, segTable_avr1200},
   { "at90s2313", FAMILY_AVR, AVR_AT90S2313, segTable_avr2313},
   { "at90s4414", FAMILY_AVR, AVR_AT90S4414, segTable_avr4414},
   { "at90s8515", FAMILY_AVR, AVR_AT90S8515, segTable_avr8515},
   { "atmega163", FAMILY_AVR, AVR_ATMEGA163, segTable_atmega163},

   { "Not specified", FAMILY_AVR, PART_NONE, segTable_avr1200},
   { "",              FAMILY_NONE,PART_NONE, segTable_avr1200}
};
//------------------------------------------------------------------------------
TSegTable TPartDB::segTable_avr1200[] = {
   { "flash", 1024, 0},
   { "eeprom",  64, 0},
   { "sram",     0, 0},
   { "", 0, 0}
};
//------------------------------------------------------------------------------
TSegTable TPartDB::segTable_avr2313[] = {
   { "flash", 2048, 0},
   { "eeprom", 128, 0},
   { "sram",   128, 0},
   { "", 0, 0}
};
//------------------------------------------------------------------------------
TSegTable TPartDB::segTable_avr4414[] = {
   { "flash", 4096, 0},
   { "eeprom", 256, 0},
   { "sram",   256, 0},
   { "eram", 65535, 0},
   { "", 0, 0}
};
//------------------------------------------------------------------------------
TSegTable TPartDB::segTable_avr8515[] = {
   { "flash", 8192, 0},
   { "eeprom", 512, 0},
   { "sram",   512, 0},
   { "eram", 65535, 0},
   { "", 0, 0}
};

TSegTable TPartDB::segTable_atmega163[] = {
   { "flash", 16384, 0},
   { "eeprom", 1024, 0},
   { "sram",   1024, 0},
   { "eram", 65535, 0},
   { "", 0, 0}
};
//------------------------------------------------------------------------------
TPartDB::TPartDB (char* partName): curPartIdx (0)
{
   setPart (partName);
}
//------------------------------------------------------------------------------
void TPartDB::setPart (char* partName)
{
   int i;
   for(i=0; parts[i].familyNo != FAMILY_NONE; i++)
   {
      if(strcmp (partName, parts[i].partName)==0)
      {
         familyNo = parts[i].familyNo;
         partNo = parts[i].partNo;
         segTableP = parts[i].segTableP;
         curPartIdx = i;
         return;
      }
   }
   throw UnknownPart ();
}
//------------------------------------------------------------------------------
long TPartDB::segSize (char* segName)
{
   int i;
   for(i=0; segTableP[i].segName[0] != 0; i++)
   {
      if(strcmp (segName, segTableP[i].segName)==0)
      {
         return segTableP[i].size;
      }
   }
   return -1;
}
//------------------------------------------------------------------------------
void TPartDB::listParts ()
{
   int i;
   printf ("Supported MCUs:\n  ");
   for(i=0; parts[i].partNo != PART_NONE; i++)
   {
      printf ( "%s ", parts[i].partName);
      if(((i+1)%5)==0)
      {
         printf ("\n  ");
      }
   }
   printf ("\n");
}
//------------------------------------------------------------------------------
int TPartDB::verify (char* cmpPart)
{
   for(int i=0; parts[i].familyNo != FAMILY_NONE; ++i)
   {
      if(strcmp (cmpPart, parts[i].partName)==0)
      {
         if(parts[i].familyNo == parts[curPartIdx].familyNo &&
            i <= curPartIdx)
         {
            return 0;
         }
         return -1;
      }
   }
   return -1;
}
