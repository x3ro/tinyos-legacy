#include "PCH.h" // common MicroSoft/Borland Headers
/*
sdf.C

  Standard Downloading Functions
  General Implementation.
  
    Uros Platise (c) 1997
*/
#define ENDIAN_STYLE               true
#define CHECKSUM_WITH_ADDRESS      true
#define BYTE(x) x & 0xff
#include "sdf.h"// this is the header file for this source code
//String FilterSegment;
//String FileName;

//------------------------------------------------------------------------------
TAout::TAout (char* aoutFileName, char *mode)
{
  // String sFileName = aoutFileName;
  // int filtP = sFileName.Pos("%");
  // FilterSegment = ""; /* remove */
  // if(filtP > 0)
  //  {
  //    String TestString = sFileName.SubString(filtP+1, sFileName.Length()-filtP);
  //    FilterSegment = TestString;
  //    aoutFileName[filtP-1] = 0;
  // }
  
  if((fp=fopen (aoutFileName, mode))==NULL)
    throw Error_C ();
  
  HexType = Undefined;
  startofFile = true; endofFile = false; anySegWr=false;
  //   FileName = String(aoutFileName);
}

//------------------------------------------------------------------------------
TAout::~TAout ()
{
  if(anySegWr==true)
  {
    fprintf (fp, "[end]\n");
  }
  fclose (fp);
}

//------------------------------------------------------------------------------
int TAout::readData (TDataQuery* dataP)
{
  int ReturnValue=0;
  if(endofFile==true)
  {
    return 0;
  }
  /* check for correct a.out format */
  if(startofFile==true)
  {
    /* check for[code] statement */
    while(fgets (buffer, LineSize, fp)!=NULL) // go until eof
    {
      if(strncmp ("[code]", buffer, 6)==0)
      {
	startofFile = false;
	HexType = UAsm;
	break;
      }
      else if(strncmp ("S0", buffer, 2)==0)
      {
	startofFile = false;
	HexType = Motorola;
	break;
      }
      else if(buffer[0] == ':')
      {
	startofFile = false;
	HexType = Intel;
	break;
      }
    }
  }
  if(startofFile==true)
    throw Error_Device ("File is not standard Micro Asm Output File");
  
  switch(HexType)
  {
  case UAsm:
    ReturnValue =  read_UAsmHex(dataP);
    break;
    
  case Motorola:
    ReturnValue =  read_MotorolaHex(dataP);
    break;
    
  case Intel:
    ReturnValue =  read_IntelHex(dataP);
    break;
  }
  
  /* FilterSegment selected segments */
  dataP->keepOut=false;
  //   if(!FilterSegment.IsEmpty())
  //   {
  //      if(FilterSegment != dataP->segName)
  //         dataP->keepOut=true;
  //   }
  
  return ReturnValue;
}

//------------------------------------------------------------------------------
int TAout::read_UAsmHex (TDataQuery* dataP)
{
  /* read segment name */
  if(fgets (buffer, LineSize, fp)==NULL)
  {
    throw Error_Device ("Unexpected end of file");
  }
  if(strncmp ("[end]", buffer, 5)==0)
  {
    endofFile=true;
    return 0;
  }
  if(buffer[0] != '@')
  {
    throw Error_Device ("Bad file format");
  }
  char *rp = strrchr (buffer, ','); *rp = 0; /* make two strings from one */
  strcpy (dataP->segName, &buffer[1]);
  dataP->offset = strtol(rp+1, (char**)NULL, 16);
  dataP->size = 0;
  /* read segment */
  while(fgets (buffer, LineSize, fp)!=NULL)
  {
    if(buffer[0] == '@')
    {
      break;
    }
    // process this line converting hex strings into numbers
    char *p = buffer;
    while(*p!='\n' && *p!=0 && *p!='\r')
    {
      unsigned int _data;
      sscanf(p, "%2x", &_data);
      dataP->buf[dataP->size++] = _data;
      p+=2;
    }
  }
  if(strncmp ("[end]", buffer, 5)==0)
  {
    endofFile=true;
  }
  if(buffer[0] == '@')
  {
    int temp = strlen (buffer);
    fseek (fp, -temp, SEEK_CUR);
  }
  fgets (buffer, LineSize, fp);
  return 1;
}
//------------------------------------------------------------------------------
int TAout::read_MotorolaHex (TDataQuery* dataP)
{
  if(fgets (buffer, LineSize, fp)==NULL)
  {
    throw Error_Device ("Unexpected end of file");
  }

  if(strncmp ("S9", buffer, 2)==0)
  {
    endofFile=true;
    return 0;
  }
  bool BigEndian = false;
  //   if(FileName.LowerCase().Pos(".eep") == 0)
  //   {
  //      BigEndian = true;
  //      strcpy (dataP->segName, "flash");
  //   }
  //   else
  strcpy (dataP->segName, "flash");
  
  fseek (fp, 0, SEEK_SET); // set to home
  dataP->offset = -1; // init for the first time only
  dataP->size = 0;
  unsigned address;
  unsigned char hi_byte, lo_byte;
  while(fgets (buffer, LineSize, fp)!=NULL)
  {
    int dataByteCount, recordType;
    unsigned lineAddress, offsetAddress = 0;
    unsigned tmp, checksum = 0;
    sscanf(&buffer[1], "%1x", &recordType);
    checksum += recordType;
    sscanf(&buffer[2], "%2x", &dataByteCount);
    checksum += dataByteCount;
    sscanf(&buffer[4], "%4x", &lineAddress);
    if(dataP->offset == -1)
      dataP->offset = lineAddress;
    sscanf(&buffer[4], "%2x", &tmp);
    checksum += tmp;
    sscanf(&buffer[6], "%2x", &tmp);
    checksum += tmp;
    
 
    if(recordType == 0)
    {
      // Look to see if we are actually reading an eeprom file.
      if (strncmp("eeprom",&buffer[2],6))
      {
	strcpy (dataP->segName, "eeprom");
	dataP->offset = -1;
      }

    }
    else if(recordType == 1)
    {
      // 4 less for address, and 2 more less for chechsum
      if ((8 + (dataByteCount * 2) - 6 ) > LineSize)
	throw Error_Device("Exceeded Maximum Line Size");
      int idx;
      for(idx = 8; idx < (8 + (dataByteCount * 2) - 6); idx += 2)
      {
	unsigned byte_data;
	sscanf(&buffer[idx], "%2x", &byte_data); /* Use word addresses for the AT90S1200 2-byte data format */
	if(lineAddress & 0x0001)   // is it an odd address?
	{
	  hi_byte = (unsigned char) byte_data; // yes -- set MSB of data
	  address = lineAddress + (offsetAddress * 0x10) - 1;
	  if (BigEndian)
	  {
	    dataP->buf[address++] = hi_byte;
	    dataP->buf[address++] = lo_byte;
	  }
	  else
	  {
	    dataP->buf[address++] = lo_byte;
	    dataP->buf[address++] = hi_byte;
	  }
	}
	else // even address
	  lo_byte = (unsigned char) byte_data; // no -- set LSB of data
	
	dataP->size++;
	lineAddress++;
	checksum += byte_data;
      }
      checksum = (unsigned char) (0x100 - (unsigned char) checksum);
      sscanf(&buffer[idx], "%2x", &tmp);
      if(checksum != tmp)
	throw Error_Device("Bad Checksum");
    } // end of if (record == 1)
#if 0
    else if(recordType == 2) // Record type 02 means update offset address
    {
      sscanf(&buffer[9], "%4x", &offsetAddress);
      sscanf(&buffer[9], "%2x", &tmp);
      checksum += tmp;
      sscanf(&buffer[11], "%2x", &tmp);
      checksum += tmp;
      checksum = (unsigned char) (0x100 - (unsigned char) checksum);
      sscanf(&buffer[13], "%2x", &tmp);
      if(checksum != tmp)
	throw Error_Device("Bad Checksum");
      
    }  // end of if(record == 2) 
#endif
    else if(recordType == 9)
    {
      if (!BigEndian)
	dataP->buf[address++] = lo_byte;
      
      endofFile=true;
      break;
    }
  }
  return 1;
}

//------------------------------------------------------------------------------
int TAout::read_IntelHex (TDataQuery* dataP)
{
  if(strncmp (":00", buffer, 3)==0)
  {
    endofFile=true;
    return 0;
  }
  bool BigEndian = false;
  //   if(FileName.LowerCase().Pos(".eep") == 0)
  //   {
  //      BigEndian = true;
  //      strcpy (dataP->segName, "flash");
  //   }
  //   else
  strcpy (dataP->segName, "eeprom");
  
  fseek (fp, 0, SEEK_SET); // set to home
  dataP->offset = -1; // init for the first time only
  dataP->size = 0;
  unsigned address;
  unsigned char hi_byte, lo_byte;
  while(fgets (buffer, LineSize, fp)!=NULL)
  {
    int dataByteCount, recordType;
    unsigned tmp, checksum = 0;
    sscanf(&buffer[1], "%2x", &dataByteCount);
    checksum += dataByteCount;
    unsigned lineAddress, offsetAddress = 0;
    sscanf(&buffer[3], "%4x", &lineAddress);
    if(dataP->offset == -1)
      dataP->offset = lineAddress;
    sscanf(&buffer[3], "%2x", &tmp);
    checksum += tmp;
    sscanf(&buffer[5], "%2x", &tmp);
    checksum += tmp;
    sscanf(&buffer[7], "%2x", &recordType);
    checksum += recordType;
    
    if(recordType == 2) // Record type 02 means update offset address
    {
      sscanf(&buffer[9], "%4x", &offsetAddress);
      sscanf(&buffer[9], "%2x", &tmp);
      checksum += tmp;
      sscanf(&buffer[11], "%2x", &tmp);
      checksum += tmp;
      checksum = (unsigned char) (0x100 - (unsigned char) checksum);
      sscanf(&buffer[13], "%2x", &tmp);
      if(checksum != tmp)
	throw Error_Device("Bad Checksum");
      
    }  // end of if(record == 2)
    else if(recordType == 0)
    {
      if ((8 + (dataByteCount * 2) - 6 ) > LineSize)
	throw Error_Device("Exceeded Maximum Line Size");
      int idx;
      for(idx = 9; idx < 9 + dataByteCount * 2; idx += 2)
      {
	unsigned byte_data;
	sscanf(&buffer[idx], "%2x", &byte_data); /* Use word addresses for the AT90S1200 2-byte data format */
	if(lineAddress & 0x0001)   // is it an odd address?
	{
	  hi_byte = (unsigned char) byte_data; // yes -- set MSB of data
	  address = lineAddress + (offsetAddress * 0x10) - 1;
	  if (BigEndian)
	  {
	    dataP->buf[address++] = hi_byte;
	    dataP->buf[address++] = lo_byte;
	  }
	  else
	  {
	    dataP->buf[address++] = lo_byte;
	    dataP->buf[address++] = hi_byte;
	  }
	}
	else // even address
	  lo_byte = (unsigned char) byte_data; // no -- set LSB of data
	
	dataP->size++;
	lineAddress++;
	checksum += byte_data;
      }
      checksum = (unsigned char) (0x100 - (unsigned char) checksum);
      sscanf(&buffer[idx], "%2x", &tmp);
      if(checksum != tmp)
	throw Error_Device("Bad Checksum");
    } // end of if (record == 0)
    else if(recordType == 1)
    {
      if (!BigEndian)
	dataP->buf[address++] = lo_byte;
      
      endofFile=true;
      break;
    }
  }
  return 1;
}
//------------------------------------------------------------------------------
bool TAout::segRequest (char* segName)
{
  //   if(!FilterSegment.IsEmpty())
  //   {
  //      if(FilterSegment == segName)
  //         return false;
  //  }
  return true;
}
//------------------------------------------------------------------------------
void TAout::writeData (TDataQuery* dataP, THexType inHexType)
{
  if(inHexType != Undefined)
    HexType = inHexType;
  
  switch(inHexType)
  {
  case UAsm:
    write_UAsmHex(dataP);
    break;
    
  case Motorola:
    write_MotorolaHex(dataP);
    break;
    
  case Intel:
    write_IntelHex(dataP);
    break;
  }
}
//------------------------------------------------------------------------------
void TAout::write_UAsmHex (TDataQuery* dataP)
{
  anySegWr=true;
  if(startofFile==true)
  {
    fprintf (fp, "[code]\n");
    startofFile=false;
  }
  fprintf (fp, "@%s,%x\n", dataP->segName, dataP->offset);
  bool newLine=false;
  for(unsigned int fi=0; fi<dataP->size; fi++)
  {
    fprintf (fp, "%.2x", (unsigned char)dataP->buf[fi]);
    newLine = false;
    if(((fi+1)%16)==0)
    {
      fprintf (fp, "\n"); newLine = true;
    }
  }
  if(newLine==false)
    fprintf (fp, "\n");
}
//------------------------------------------------------------------------------
void TAout::write_MotorolaHex (TDataQuery* dataP)
{
  unsigned Address = dataP->offset;
  unsigned char checksum=0, length=0x10; // 16 bytes
  fprintf(fp, "S003000FC\n"); // dump ?? I don't know the meaning of this info
  fprintf(fp, "S1%02X%04X", length + 3 , Address); // 2 for address, 16 bytes and 1 for checksum
  checksum = length + 3;
#ifndef NO_CHECKSUM_WITH_ADDRESS
  checksum += BYTE(Address / 0x0100) + BYTE(Address);
#endif
  bool NewLine = false;
  for(unsigned int fi=0; fi<dataP->size; fi+=2)
  {
    // bit endian vs little endian
    unsigned char hi_byte, lo_byte;
    //      if(strcmp (dataP->segName, "flash")==0)
    //      { // low byte first
    //         lo_byte = dataP->buf[fi];
    //         hi_byte = dataP->buf[fi+1];
    //      }
    //      else
    //      { // high byte first
    hi_byte = dataP->buf[fi];
    lo_byte = dataP->buf[fi+1];
    //      }
    
    checksum += hi_byte;
    fprintf (fp, "%02X", hi_byte);
    checksum += lo_byte;
    fprintf (fp, "%02X", lo_byte);
    NewLine = false;
    if(((fi+2)%16)==0 && fi != 0)
    {
      NewLine = true;
      fprintf(fp, "%02X\n", BYTE(0x00FF-checksum));
      if(((dataP->size-2) - fi) < 0x10)
	length = (dataP->size-2) - fi;
      
      if(length > 0)
      {
	Address += length;
	fprintf(fp, "S1%02X%04X", length + 3 , Address); // 2 for address, 16 bytes and 1 for checksum
	checksum = length + 3;
#ifndef NO_CHECKSUM_WITH_ADDRESS
	checksum += BYTE(Address / 0x00FF) + BYTE(Address);
#endif
      }
    }
  }
  if(NewLine==false)
    fprintf(fp, "%02X\n", BYTE(0x0100-checksum));
  
  fprintf(fp, "S903000FC\n");
}
//------------------------------------------------------------------------------
void TAout::write_IntelHex (TDataQuery* dataP)
{
  unsigned Address = dataP->offset;
  unsigned char checksum=0, length=0x10;
  fprintf(fp, ":%02X%04X00", length, Address);
  checksum = length;
#ifdef CHECKSUM_WITH_ADDRESS
  checksum += BYTE(Address / 0x0100) + BYTE(Address);
#endif
  bool NewLine = false;
  for(unsigned int fi=0; fi<dataP->size; fi+=2)
  {
    // bit endian vs little endian
    unsigned char hi_byte, lo_byte;
#ifdef ENDIAN_STYLE
    if(strcmp (dataP->segName, "flash")==0)
    { // low byte first
      lo_byte = dataP->buf[fi];
      hi_byte = dataP->buf[fi+1];
    }
    else
#endif
    { // high byte first
      hi_byte = dataP->buf[fi];
      lo_byte = dataP->buf[fi+1];
    }
    
    checksum += hi_byte;
    fprintf (fp, "%02X", hi_byte);
    checksum += lo_byte;
    fprintf (fp, "%02X", lo_byte);
    NewLine = false;
    if(((fi+2)%16)==0 && fi != 0)
    {
      NewLine = true;
      fprintf(fp, "%02X\n", BYTE(0x0100-checksum));
      if(((dataP->size-2) - fi) < 0x10)
	length = (dataP->size-2) - fi;
      
      if(length > 0)
      {
	Address += length;
	fprintf(fp, ":%02X%04X00", length, Address);
	checksum = length;
#ifdef CHECKSUM_WITH_ADDRESS
	checksum += BYTE(Address / 0x0100) + BYTE(Address);
#endif
      }
    }
  }
  if(NewLine==false)
    fprintf(fp, "%02X\n", BYTE(0x0100-checksum));
  
  fprintf(fp, ":00000001FF\n");
}
//------------------------------------------------------------------------------

