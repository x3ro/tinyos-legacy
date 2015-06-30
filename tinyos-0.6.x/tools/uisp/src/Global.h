/* Global.h, Uros Platise (c) 1999 */

#ifndef __GLOBAL
#define __GLOBAL

#include <assert.h>

typedef unsigned char TByte;
typedef unsigned TAddr;


/* Smart Pointer Class 
*/
template <class TRec>
class TPt{
private:
  TRec* Addr;
  void MkRef(){if (Addr!=NULL){Addr->CRef++;}}
  void UnRef(){if (Addr!=NULL){Addr->CRef--;if (Addr->CRef==0){delete Addr;}}}
public:
  TPt():Addr(NULL){}
  TPt(TRec* _Addr): Addr(_Addr){MkRef();}
  TPt(const TPt& Pt): Addr(Pt.Addr){MkRef();}
  ~TPt(){UnRef();}

  TPt& operator=(const TPt& Pt){
    if (this!=&Pt){UnRef(); Addr=Pt.Addr; MkRef();} return *this;}
  TPt& operator=(TRec* _Addr){
    if (Addr!=_Addr){UnRef();Addr=_Addr;MkRef();} return *this;}
  bool operator==(const TPt& Pt) const {return Addr==Pt.Addr;}

  TRec* operator->() const {assert(Addr!=NULL); return Addr;}
  TRec& operator*() const {assert(Addr!=NULL); return *Addr;}
  TRec& operator[](int RecN) const {assert(Addr!=NULL); return Addr[RecN];}
  TRec* operator()() const {return Addr;}
  
  /* think once more! */
  bool operator<(const TPt& Pt){return Addr < Pt.Addr;}
};


class TDevice{
private:
  int CRef;
  
public:
  /* Set active segment. 
     Returns true if segment exists, otherwise false 
  */
  virtual bool SetSegment(const char* segment_name)=0;
  
  /* Returns char pointer of current active segment name.
  */
  virtual const char* TellActiveSegment()=0;

  /* Returns char pointer of the indexed segment name.
     Index is in range [0,no_of_segments].
     When index is out of range NULL is returned.
  */
  virtual const char* ListSegment(unsigned index)=0;

  virtual TAddr GetSegmentSize()=0;

  /* Read byte from active segment at address addr. */
  virtual TByte ReadByte(TAddr addr)=0;
  
  /* Read byte description at address addr (as security bits) */
  virtual const char* ReadByteDescription(TAddr addr)=0;
  
  /* Write byte to active segment at address addr */
  virtual void WriteByte(TAddr addr, TByte byte, bool flush_buffer=true)=0;
  virtual void FlushWriteBuffer(){}
  
  /* Chip Erase */
  virtual void ChipErase()=0;

  /* lock bits */
  virtual void WriteLockBits(TByte bits)=0;
  virtual TByte ReadLockBits(){return 0;}
  
  /* Transfer Statistics in Bytes/Seconds */
  virtual unsigned int GetPollCount(){return 0;}
  virtual float GetMinPollTime(){return 0;}
  virtual float GetTotPollTime(){return 0;}
  virtual float GetMaxPollTime(){return 0;}
  virtual void ResetMinMax(){}
  
  TDevice():CRef(0){}
  virtual ~TDevice(){}
  
  friend class TPt<TDevice>;
};

typedef TPt<TDevice> PDevice;

extern PDevice device;

/* Find command line parameter's value.
   It searches the command line parameters of the form:
   
	argv_name=value
	
   Returns pointer to the value. 
*/
const char* GetCmdParam(const char* argv_name, bool value_required=true);


/* Print Status Information to the Standard Error Output.
*/
bool Info(unsigned _verbose_level, const char* fmt, ...)
  __attribute__((format (printf, 2, 3)));

#endif
