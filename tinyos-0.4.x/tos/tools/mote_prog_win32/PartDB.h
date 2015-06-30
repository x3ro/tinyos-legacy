/*
  PartDB.h
  Uros Platise (c) 1997
*/

#ifndef __PartDB
#define __PartDB

#define MAX_BASESEG 16

/* Global Part No */
#define PART_NONE   0
#define FAMILY_NONE 0
#define FAMILY_AVR  1
#define FAMILY_HC11 2

/* AVR specifications */
#define AVR_AT90S1200 1
#define AVR_AT90S2313 2
#define AVR_AT90S4414 3
#define AVR_AT90S8515 4
#define	AVR_ATMEGA163 5

/* Used by Segment and others .... */
struct TSegTable
{
   char* segName;
   long size;
   long start;
};

class TPartDB
{
private:
   struct TPart
   {
      char* partName;
      int familyNo;
      int partNo;
      TSegTable* segTableP;
   };
public:
   TPartDB (char* partName);     /* can throw UnknownPart error */
   virtual ~TPartDB () { }
   void setPart (char* partName); /* change part */
   long segSize (char* segName); /* returns -1 if unknown seg is entered */
   void listParts ();
   int verify (char* cmpPart);
   char* getPartName () { return parts[curPartIdx].partName; }

public:
   class UnknownPart { }; /* one and only possible error */
   int familyNo;
   int partNo;
   TSegTable* segTableP;

  /*********** DATA BASE ***********/
private:
   static TPart parts[];
   int curPartIdx;

  /* AVR MCUs */
   static TSegTable segTable_avr1200[];
   static TSegTable segTable_avr2313[];
   static TSegTable segTable_avr4414[];
   static TSegTable segTable_avr8515[];
   static TSegTable segTable_atmega163[];
};

#endif
