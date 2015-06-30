/* 
	MotIntl.h
	
	Motorola and Intel Uploading/Downloading Routines
	Uros Platise (c) 1999
*/

#ifndef __MOTINTL
#define __MOTINTL

#include <stdio.h>
#include "Global.h"

#define MI_LINEBUF_SIZE	128

class TMotIntl{
public:
  enum TFormatType{TF_MOTOROLA, TF_INTEL};

private:
  char line_buf [MI_LINEBUF_SIZE];
  unsigned char cc_sum;
  unsigned int hash_marker;
  FILE* fd;
  bool upload, verify;

  TByte Htoi(const char* p);
  void InfoOperation(const char* prefix, const char* seg_name);
  void ReportStats(float, TAddr);
  void UploadMotorola();
  void UploadIntel();
  void SrecWrite(unsigned int, const unsigned char *, unsigned int);
  void DownloadMotorola();

public:
  void Read(const char* filename, bool _upload, bool _verify);
  void Write(const char *filename);

  TMotIntl();
  ~TMotIntl(){}
};

extern TMotIntl motintl;

#endif
