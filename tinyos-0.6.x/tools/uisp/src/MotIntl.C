/* 
	MotIntl.C
	
	Motorola and Intel Uploading/Downloading Routines
	Uros Platise (c) 1999
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "timeradd.h"
#include "Global.h"
#include "Error.h"
#include "MotIntl.h"

TByte TMotIntl::Htoi(const char* p){
  unsigned char val = 0;
  if (*p==0){throw Error_Device("Bad file format.");}
  if (*p>=0 && *p<='9'){val += *p-'0';}else{val += *p-'A'+10;}
  val <<= 4; p++;    
  if (*p==0){throw Error_Device("Bad file format.");}  
  if (*p>=0 && *p<='9'){val += *p-'0';}else{val += *p-'A'+10;}
  cc_sum += val;
  return val;
}

void TMotIntl::InfoOperation(const char* prefix, const char* seg_name){
  Info(1, "%s", prefix);
  if (!upload && !verify) { Info(1, "Downloading"); }
  if (upload){Info(1, "Uploading");}
  if (upload && verify){Info(1, "/");}
  if (verify){Info(1, "Verifying");}
  Info(1, ": %s\n", seg_name);
}

void
TMotIntl::ReportStats(float elapsed, TAddr total_bytes)
{
  float rate = (float)total_bytes / elapsed;
  Info(2, "\n(total %u bytes transferred in %.2f s (%.0f bytes/s)\n",
       total_bytes, elapsed, rate);
  if (upload) {
    unsigned int total_polled = device->GetPollCount();
    if (total_polled) {
      float min_poll_time = device->GetMinPollTime() * 1000.0;
      float max_poll_time = device->GetMaxPollTime() * 1000.0;
      float avg_poll_time = device->GetTotPollTime() * (1000.0 / total_polled);
      Info(2, "Polling: count = %u, min/avg/max = %.2f/%.2f/%.2f ms\n",
	   total_polled, min_poll_time, avg_poll_time, max_poll_time);
    }
  }
}

void TMotIntl::UploadMotorola(){
  unsigned char srec_len, buf_len, srec_cc_sum;
  char seg_name[32];
  char* p;		/* line buffer pointer */
  TAddr addr;
  TAddr total_bytes_uploaded=0;
  TAddr hash_cnt=0;
  TByte byte;
  struct timeval t1, t2;
  
  device->ResetMinMax();
  
  do{
    /* convert to upper case */
    buf_len = strlen(line_buf);
    for (int i=0;i<buf_len;i++){line_buf[i] = toupper(line_buf[i]);}
  
    if (line_buf[0]!='S'){throw Error_Device("Bad Motorola file format.");}
    
    cc_sum = 0;
    srec_len = Htoi(&line_buf[2]) - 3;
    p = &line_buf[4];
    
    /* Load address */
    addr = Htoi(p); p+=2; addr <<= 8;
    addr += Htoi(p); p+=2;
    
    switch(line_buf[1]){
    case '0':{    
	/* Load segment name */
	for (int i=0;i<srec_len;i++){seg_name[i] = Htoi(p); p+=2;}
	seg_name[srec_len]=0;
		
	/* Select Segment */
	if (device->SetSegment(seg_name)){InfoOperation("Auto-", seg_name);}
	else{InfoOperation("", device->TellActiveSegment());}
	
	/* Print first hash */
	if (device->GetSegmentSize() >= 16)
	  Info(2, "#");
	hash_cnt=0;
	
	/* Set statistic variables */	
	total_bytes_uploaded = 0;
	gettimeofday(&t1, NULL);
      } break;
          
    case '2':
        addr <<= 8; addr += Htoi(p); p+=2;
	srec_len--;
	
    case '1':{		
	/* Upload/Verify bytes */
	total_bytes_uploaded += srec_len;
	while(srec_len-->0){
	  byte = Htoi(p);
	  if (upload){device->WriteByte(addr, byte, false);}
	  if (verify){
	    TByte rbyte = device->ReadByte(addr);
	    if (rbyte != byte){
	      Info(0, "%s error at address 0x%x: file=0x%02x, mem=0x%02x\n",
	        device->TellActiveSegment(), addr, 
		(int) byte, (int) rbyte);
	    }
	  }	  
	  p+=2; addr++;
	  if (total_bytes_uploaded >= hash_cnt+hash_marker){
	    Info(2, "#");
	    hash_cnt+=hash_marker;
	  }
	}
      } break;
          
    case '9':{
        if (upload){device->FlushWriteBuffer();}
	gettimeofday(&t2, NULL);
	timersub(&t2, &t1, &t2);
	float elapsed = t2.tv_sec + t2.tv_usec*1e-6;
	ReportStats(elapsed, total_bytes_uploaded);
      } break;
      
    default: throw Error_Device("Bad Motorola S record.\n");
    }
    
    /* Read Check Sum and give a report */
    srec_cc_sum = Htoi(p);
    if (cc_sum != 0xFF){
      Info(2, "S-record check sum: %d   uisp check sum: %d\n",
        (unsigned)srec_cc_sum, (unsigned)cc_sum);
      throw Error_Device("Check sum error.\n");
    }

  } while(fgets(line_buf, MI_LINEBUF_SIZE, fd)!=NULL);
}

void TMotIntl::UploadIntel(){
  unsigned char srec_len, buf_len, srec_cc_sum;
  char* p;		/* line buffer pointer */
  TAddr addr;
  TAddr total_bytes_uploaded=0;
  TAddr hash_cnt=0;
  TByte byte;
  struct timeval t1, t2;

  InfoOperation("", device->TellActiveSegment());
  
  /* Print first hash */
  if (device->GetSegmentSize() >= 16)
    Info(2, "#");
  
  /* Set statistic variables */	
  total_bytes_uploaded = 0;
  gettimeofday(&t1, NULL);

  device->ResetMinMax();

  do{
    /* convert to upper case */
    buf_len = strlen(line_buf);
    for (int i=0;i<buf_len;i++){line_buf[i] = toupper(line_buf[i]);}
  
    if (line_buf[0]!=':'){throw Error_Device("Bad Intel file format.");}

    cc_sum = 0;
    srec_len = Htoi(&line_buf[1]);
    p = &line_buf[3];
    
    /* Load address */
    addr = Htoi(p); p+=2; addr <<= 8;
    addr += Htoi(p); p+=2;
    Htoi(p); p+=2;	/* read control byte: 00-data, 01-end */

    /* Upload/Verify bytes */
    total_bytes_uploaded += srec_len;
    while(srec_len-->0){
      byte = Htoi(p);
      if (upload){device->WriteByte(addr, byte, false);}
      if (verify){
	TByte rbyte = device->ReadByte(addr);
	if (rbyte != byte){
	  Info(0, "%s error at address 0x%x: file=0x%02x, mem=0x%02x\n",
	    device->TellActiveSegment(), addr, 
	    (int) byte, (int) rbyte);
	}
      }
      p+=2; addr++;
      if (total_bytes_uploaded >= hash_cnt+hash_marker){
	Info(2, "#");
	hash_cnt+=hash_marker;
      }      
    }
    
    /* Read Check Sum and give a report */
    srec_cc_sum = Htoi(p);
    if (cc_sum != 0x0){
      Info(2, "Intel check sum: %d   uisp check sum: %d\n",
        (unsigned)srec_cc_sum, (unsigned)cc_sum);
      throw Error_Device("Check sum error.\n");
    }
    
  
  } while(fgets(line_buf, MI_LINEBUF_SIZE, fd)!=NULL);
  
  if (upload){device->FlushWriteBuffer();}  
  
  /* Print transfer statistics */        
  gettimeofday(&t2, NULL);  
  timersub(&t2, &t1, &t2);
  float elapsed = t2.tv_sec + t2.tv_usec*1e-6;
  ReportStats(elapsed, total_bytes_uploaded);
}

void TMotIntl::Read(const char* filename, bool _upload, bool _verify){
  upload = _upload;
  verify = _verify;
  if ((fd=fopen(filename,"rt"))==NULL){throw Error_C();}
  
  /* Set-up Hash Marker */
  const char* val = GetCmdParam("--hash");
  if (val!=NULL){hash_marker = atoi(val);}  
  
  /* auto-detect Motorola or Intel file format */
  fgets(line_buf, MI_LINEBUF_SIZE, fd);
  if (strncasecmp(line_buf, "S0", 2)==0){UploadMotorola();}
  else if (line_buf[0]==':'){UploadIntel();}
  else {throw Error_Device("Unknown file format.");}  
  
  fclose(fd);
}

void
TMotIntl::SrecWrite(unsigned int type, const unsigned char *buf,
		    unsigned int len)
{
  unsigned i, sum;

  fprintf(fd, "S%01X%02X", type, len + 1);
  sum = len + 1;
  for (i = 0; i < len; i++) {
    sum += buf[i];
    fprintf(fd, "%02X", (unsigned int) buf[i]);
  }
  fprintf(fd, "%02X\r\n", (unsigned int)(~sum & 0xFF));
}

void
TMotIntl::DownloadMotorola()
{
  TAddr addr, size;
  TAddr total_bytes_uploaded=0;
  TAddr hash_cnt=0;
  struct timeval t1, t2;
  unsigned char buf[40];
  const char *seg;

  seg = device->TellActiveSegment();
  InfoOperation("", seg);
  
  /* Set statistic variables */	
  total_bytes_uploaded = 0;
  gettimeofday(&t1, NULL);

  device->ResetMinMax();

  size = device->GetSegmentSize();

  /* Print first hash (except for fuse bits) */
  if (size >= 16)
    Info(2, "#");

  buf[0] = 0;
  buf[1] = 0;
  strncpy((char *) buf, seg, 16);
  buf[18] = 0;
  SrecWrite(0, buf, 2 + strlen((const char *) buf + 2));

  /* FIXME: S2, S8 required for ATmega103 - see uisp-0.2.1JPK */
  for (addr = 0; addr < size; addr += 16) {
    int i, len;

    len = size - addr;
    if (len > 16)
      len = 16;
    buf[0] = (addr >> 8) & 0xFF;
    buf[1] = addr & 0xFF;
    for (i = 0; i < len; i++) {
      TByte rbyte = device->ReadByte(addr + i);
      buf[2 + i] = rbyte;
      total_bytes_uploaded++;
      if (total_bytes_uploaded >= hash_cnt + hash_marker) {
	Info(2, "#");
	hash_cnt += hash_marker;
      }
    }
    SrecWrite(1, buf, 2 + len);
  }

  buf[0] = 0;
  buf[1] = 0;
  SrecWrite(9, buf, 2);

  /* Print transfer statistics */        
  gettimeofday(&t2, NULL);  
  timersub(&t2, &t1, &t2);
  float elapsed = t2.tv_sec + t2.tv_usec*1e-6;
  ReportStats(elapsed, total_bytes_uploaded);
}

void
TMotIntl::Write(const char *filename)
{
  if (filename) {
    fd = fopen(filename, "wb");
    if (!fd) {
      throw Error_C();
    }
    DownloadMotorola();
    fclose(fd);
  } else {
    fd = stdout;
    DownloadMotorola();
  }
}

TMotIntl::TMotIntl():
  hash_marker(32){
}
