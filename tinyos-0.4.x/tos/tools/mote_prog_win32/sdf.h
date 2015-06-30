/*
  sdf.h
  Standard Downloading Functions
  Uros Platise (c) 1997, November
*/

#ifndef __SDF
#define __SDF

#include <stdio.h>

const unsigned char LineSize=100;
const unsigned char COLUMN_SEPERATOR=(char)186;
enum THexType { Undefined, UAsm, Motorola, Intel };
typedef unsigned int TMem;
struct TDataQuery
{
   char*          segName; /* dest/source segment name */
   unsigned char* buf;     /* input/output buffer */
   TMem           size;    /* max size of transferred data */
   TMem           offset;  /* segment offset address */
   bool           keepOut; /* filter */
};

class TAout
{
public:
   TAout (char* aoutFileName, char* mode);
   ~TAout ();

   int readData (TDataQuery* dataP);
   int read_UAsmHex (TDataQuery* dataP);
   int read_MotorolaHex (TDataQuery* dataP);
   int read_IntelHex (TDataQuery* dataP);
   bool segRequest (char* segName);
   void writeData (TDataQuery* dataP, THexType inHexType=Undefined);
   void write_UAsmHex (TDataQuery* dataP);
   void write_MotorolaHex (TDataQuery* dataP);
   void write_IntelHex (TDataQuery* dataP);

private:
   FILE *fp;
   char buffer[LineSize];
   bool startofFile, endofFile;
   bool anySegWr;
//   String curSegmentName;
   THexType HexType;
};

class TSDF
{
public:
   virtual void upload (TAout* aout, bool verifyOnly=false) = 0;
   virtual void download (TAout* aout, THexType inHexType) = 0;
   virtual ~TSDF ()   {};
};

#endif
