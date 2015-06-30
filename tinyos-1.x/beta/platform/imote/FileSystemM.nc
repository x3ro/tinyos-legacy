/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

//#define FS_DEBUG

//#define DD_DEBUG
module FileSystemM {
  provides{ 
     interface StdControl;
     interface FileSystem;
  }
 // #ifdef FS_DEBUG
 //  uses interface Leds; //file system test
 // #endif
 // #ifdef DD_DEBUG
 //  uses interface Leds8;
//  #endif
}

implementation{

//  #define FRAGMENT_SIZE 8 //settings for testing (SFT)
 #define FRAGMENT_SIZE 1024
  #define BOOT_RECORD_ID_1  TM_FLASH_LAST_USER_ID - TM_FLASH_MAX_RECS + 1
  #define BOOT_RECORD_ID_2 BOOT_RECORD_ID_1+1 
  #define FRAGMENTNO_ZEEVOID(id) BOOT_RECORD_ID_2 + id + 1
  #define ZEEVOID_FRAGMENTNO(id) id-BOOT_RECORD_ID_2-1
//  #define MAX_FILES 4 //SFT
   #define MAX_FILES 16
//  #define MAX_FRAGMENTS 8 //SFT
  #define MAX_FRAGMENTS 64
  #define LAST_FRAGMENT 0xffff
  #define ERROR 0xffff

  #define NONEXIST 0
  #define CREATED 0x01
  #define COMMITED 0x02
  #define VALID 0x03 //created and committed
  #define BEING_WRITTEN 0x04 //someone opened the file for writing
  #define BEING_DELETED 0x08 // can't read if file is being deleted
  #define BEING_CREATED 0X10// being created
  
  #define MAGIC_NUMBER1 0x55 //01010101
  #define MAGIC_NUMBER2 0xAA //10101010
  #define MAGIC_NUMBER3 0xDB //11011011


  #define DEBUG_ON 1

  void debug_msg (char *str) {
#if DEBUG_ON
    trace(DBG_USR1, str);
#endif
}
  
typedef struct{
  uint8_t flags;
  userId_t userId; //the user defined file name
  uint16_t size; //the size of the data in bytes
  zeevoId_t firstFragment; //the beggining fragment
} BootRecord;

typedef struct{
  BootRecord record[MAX_FILES];
  magicNum_t magic_number;
}BootSector;

//in the fragment header size means byte position in the file
typedef struct{
  uint8_t flags;
  userId_t userId;
  uint16_t position;//byte position in file
  uint16_t nextFragment;
}FragmentRecord;


typedef struct{
  FragmentRecord hdr;
  uint8_t data[FRAGMENT_SIZE]; //number of bytes to read from this
  uint8_t chkSum;
}ZeevoRecord;


#define ZEEVO_RECORD_SIZE sizeof(ZeevoRecord)
#define BOOT_SECTOR_SIZE sizeof(BootSector)
#define FRAGMENT_RECORD_SIZE sizeof(FragmentRecord) 
#define BOOT_RECORD_SIZE sizeof(BootRecord)



  BootSector bootSector; //the current boot sector 
  magicNum_t magicNumbers[3] = {MAGIC_NUMBER1, MAGIC_NUMBER2, MAGIC_NUMBER3};
  uint8_t curBootRecordNumber; //which boot sector to write to
  magicNum_t curMagicNumber; //the next magic number

  FragmentRecord fragments[MAX_FRAGMENTS];//this keeps track of fragment info

  uint16_t curWriteOffset[MAX_FILES]; //for each file
  uint8_t noUsers[MAX_FILES]; //number of readers actively reading a file
 
  uint16_t lastFreeFragment; 
  
  uint16_t noFreeFragments = MAX_FRAGMENTS;
  
  #ifdef WRITE_CRASH_ID
  bool write_crash=false;//this if for simulating node dies while writing
                           //boot sector
  #endif
/***BASIC READ AND WRITE TO FLASH**********************/

/*these take the zeevo id and write to flash, these ids
are NOT user ids, the functions are also very general****/

  uint8_t* read_from_flash(zeevoId_t id){
       return TM_API_GetFlashReadPtr(id);
  }

/**the record chksum covers the data and is a simple xoring**/

uint8_t chk_sum(ZeevoRecord* bfr){
 uint8_t chksum=0;
 uint8_t *temp;
 uint16_t i;

 temp = (uint8_t*)bfr;

 for(i=0;i<ZEEVO_RECORD_SIZE;i++)
   chksum=chksum^temp[i];
 chksum=chksum^((uint8_t)(bfr->chkSum)); //remove the chkSum from the chkSum
 
 return(chksum);
}

/******basic function to read and write a fragment to flash***********/

ZeevoRecord* read_fragment_from_flash(zeevoId_t id){
    ZeevoRecord* bfr;
    bfr = (ZeevoRecord*)read_from_flash(id);
    if(bfr->hdr.flags){ //check of this was created in the first place
       if(chk_sum(bfr)!=bfr->chkSum) //bad chksum
	   return NULL;      
    }
    else
      return NULL;
    return bfr;
}

/***reading and writing from bootsector ***************/
 

/*read bootsector from flash, sel =0 - selects boot sector 0
sel = 1 selects boot sector 1. There are two for redundancy.
We keep alternating between the two flash memories to update,
so that the old copy can be used to salvage incase node
dies during boot up.
To determine the latest valid copy I use a sequence 
three magic numbers, which keep circulating, say M1->m2->M3.
Boot record is updated only after the actual record has been 
successfully updated.
If both boots sectors have valid magic numbers, then 
the rule to choose which boot record is as follows:
between M1 and M2 choose M2, between M2 and M3 choose M3,
between M3 and M1 choose M1. This simple rule makes
sure that only the latest successfully written boot copy
is loaded.
*/ 

/*this function reads the boot sector and returns NULL
if theres nothing there or theres something without a 
valid magic number, otherwise it returns the 
pointer to memory (in zeevo space) pointing to
the boot record*/

  BootSector* read_boot_sector(uint8_t sel){
    BootSector *boot_ptr;
    magicNum_t magic_num;
    zeevoId_t id;
 
     switch(sel){
     case 0 : id = BOOT_RECORD_ID_1;break;
     case 1 : id = BOOT_RECORD_ID_2;break;
     default : break; 
     }	

    boot_ptr= (BootSector*)read_from_flash(id);
    if(boot_ptr){
       magic_num = boot_ptr->magic_number;
       if(!(magic_num==MAGIC_NUMBER1 || magic_num==MAGIC_NUMBER2 || magic_num==MAGIC_NUMBER3))
          return NULL;
    }
    return boot_ptr;     
  }


/*****write to the boot sector on flash*****************************/
 
result_t commit_boot_sector(uint8_t bootnumber){
     zeevoId_t id;
     uint8_t *bfr;
     result_t success = SUCCESS;

     switch(bootnumber){
     case 0 : id = BOOT_RECORD_ID_1;break;
     case 1 : id = BOOT_RECORD_ID_2;break;
     default : return !SUCCESS; 
     }

     if((bfr = TM_API_GetFlashWritePtr(id,BOOT_SECTOR_SIZE))!=NULL){
       memcpy(bfr,&bootSector,BOOT_SECTOR_SIZE); 
       TM_API_FlashWriteDone(id); 
     }  
     else
       success= !SUCCESS;
    return success;
}


/****getting magic number index from the magic number*********/

  uint8_t get_magic_number_index(magicNum_t num){
   uint8_t mn; 
   switch(num){
    case MAGIC_NUMBER1 : mn= 0;break;
    case MAGIC_NUMBER2 : mn= 1;break;
    case MAGIC_NUMBER3 : mn= 2;break;
    default : mn=0xff; 
   }
   return mn;
  }

/*increments of the cur magic number and boot record id in use*/

  void updateMagicNumberandBootSector(){
     curMagicNumber=(curMagicNumber+1)%3;
     curBootRecordNumber=(curBootRecordNumber+1)%2;
  }


   magicNum_t rewind_skip_magic_number(magicNum_t m){
    switch(m){ 
    case MAGIC_NUMBER1 : return(MAGIC_NUMBER2);
    case MAGIC_NUMBER2 : return(MAGIC_NUMBER3);
    case MAGIC_NUMBER3 : return(MAGIC_NUMBER1);
    }
    return ERROR;
   }

/*update the bootsector, write to proper sector with the proper magic number*/

  result_t update_boot_sector(){
     result_t success;
     atomic{
      updateMagicNumberandBootSector();
      #ifdef WRITE_CRASH_ID //to simulate node failure while writing
                             //to boot sector
       if(write_crash) 
         bootSector.magic_number=rewind_skip_magic_number(magicNumbers[curMagicNumber]);
       else
         bootSector.magic_number=magicNumbers[curMagicNumber];   
      #else
        bootSector.magic_number=magicNumbers[curMagicNumber];   
      #endif   
      success = commit_boot_sector(curBootRecordNumber);
     }
     return success;
  }


/*determine the latest valid copy of the boot sector considering
that the node might have died before completely updating the flash**/

  uint8_t find_latest_valid_boot_sector(BootSector* boot_ptr1,BootSector* boot_ptr2){
     uint8_t valid_boot=0;
     magicNum_t magic_number1,magic_number2;

      if(boot_ptr1){
        valid_boot=1;
        magic_number1=boot_ptr1->magic_number;
      } 
  
     if(boot_ptr2){
      magic_number2=boot_ptr2->magic_number;    
      if(!valid_boot || (magic_number1==MAGIC_NUMBER1 && magic_number2==MAGIC_NUMBER2) || (magic_number1==MAGIC_NUMBER2 && magic_number2==MAGIC_NUMBER3) || (magic_number1==MAGIC_NUMBER3 && magic_number2==MAGIC_NUMBER1))
          valid_boot=2;
   }

   return valid_boot;
  }  

/***UserID to Starting Fragment mapping***/
//simply searh through all, there could be a potentially
//smarter scheme, I chose to follow KISS

uint16_t getBootIndex(uint16_t userId){
 uint16_t i,ret=ERROR;

 for(i=0;i<MAX_FILES;i++){
   if(bootSector.record[i].userId==userId && bootSector.record[i].flags&CREATED){
      ret=i;
      break;
   }
  }
  return ret;
}

/******fragment management***************/
//a fragment is returned atomically

uint16_t reserve_next_free_fragment(userId_t id, uint16_t position){
  uint16_t i,ret;

  ret=ERROR;


  atomic{
   if(noFreeFragments){
     for(i=lastFreeFragment;i<MAX_FRAGMENTS;i++){
      if(!fragments[i].flags){        
         fragments[i].flags=BEING_CREATED;
        fragments[i].userId=id;
        fragments[i].position = position;
        fragments[i].nextFragment=LAST_FRAGMENT; //by default
        ret=i;
        noFreeFragments--;
        lastFreeFragment=i;
        break;
      }
     }
    }
  }
    return ret;
}



/***********FREEING A FRAGMENT FROM FLASH AND STRUCTURE***********/
//if its been written, the fragment is bzeroed in flash
//its removed from the local RAM structure
result_t free_fragment(uint16_t fragmentNo){
   result_t success = !SUCCESS;
   ZeevoRecord* bfr;

  if(fragments[fragmentNo].flags&CREATED){ //this fragment has been written to flash
   bfr = (ZeevoRecord*)TM_API_GetFlashWritePtr(FRAGMENTNO_ZEEVOID(fragmentNo),ZEEVO_RECORD_SIZE);
     if(bfr){
       bzero((uint8_t*)bfr,ZEEVO_RECORD_SIZE);
       bfr->hdr.nextFragment=LAST_FRAGMENT;
       bfr->chkSum = chk_sum(bfr);
       TM_API_FlashWriteDone(FRAGMENTNO_ZEEVOID(fragmentNo));
       success=SUCCESS; 
     }
   }
   if(success || fragments[fragmentNo].flags&BEING_CREATED){
    atomic{
     bzero((uint8_t*)&fragments[fragmentNo],FRAGMENT_RECORD_SIZE);
     fragments[fragmentNo].nextFragment=LAST_FRAGMENT; 
     if(fragmentNo<lastFreeFragment)
        lastFreeFragment=fragmentNo;  
     noFreeFragments++;
    }
   }   
   return success;
}

/********COMMITING A CREATED FILE TO FLASH*************************/
//after creating a file logically write it to flash
result_t commit_created_file_to_flash(uint16_t startFragment){
  uint16_t curFragment = startFragment;
  uint16_t nextFragment;
  bool success = SUCCESS; 
  ZeevoRecord* bfr;
 
  do{   
      #ifdef MAX_ZEEVO_IDS
       if(curFragment>MAX_ZEEVO_IDS){
         bfr=NULL;
       }
       else
        bfr = (ZeevoRecord*)TM_API_GetFlashWritePtr(FRAGMENTNO_ZEEVOID(curFragment),ZEEVO_RECORD_SIZE);  
     #else
        bfr = (ZeevoRecord*)TM_API_GetFlashWritePtr(FRAGMENTNO_ZEEVOID(curFragment),ZEEVO_RECORD_SIZE);  
     #endif
      if(bfr){
        bzero((uint8_t*)bfr,ZEEVO_RECORD_SIZE);
        memcpy(&(bfr->hdr),&fragments[curFragment],FRAGMENT_RECORD_SIZE);
        bfr->hdr.flags=CREATED;
        bfr->chkSum=chk_sum(bfr);
        TM_API_FlashWriteDone(FRAGMENTNO_ZEEVOID(curFragment)); 
        fragments[curFragment].flags=CREATED;
      }
      else{
         success=!SUCCESS;
         break;
      }
    curFragment = fragments[curFragment].nextFragment;
  }while(curFragment!=LAST_FRAGMENT);  

 return success;
}


/*********file creation deletion reading writing***********/

/**this is function that goes through all file integrity going
through all the fragments, it checks for 
this runs only at bootup time
i)are all fragments created and committed
ii)are the size fields perfect
iii)are the userIds right
iv)are the chksums intact
************************************/

bool populate_fragments_and_chk_sanity(uint16_t fileIndex){
  ZeevoRecord *bfr;
  userId_t user_id;
  uint16_t size;
  uint16_t curFrag;
  bool success = false;

  //delete any invalid sectors at bootup
  if(bootSector.record[fileIndex].flags!=VALID)
    return false;
  curFrag = bootSector.record[fileIndex].firstFragment;
  user_id = bootSector.record[fileIndex].userId;
  size = bootSector.record[fileIndex].size;
  do{
   success=false;
   if((bfr = read_fragment_from_flash(FRAGMENTNO_ZEEVOID(curFrag)))!=NULL){
    if((bfr->hdr.flags&COMMITED) && bfr->hdr.userId == user_id){
      if(chk_sum(bfr)==bfr->chkSum){
        success = true;
      } 
   }
  }
  if(!success)
    break;


  memcpy((uint8_t*)&fragments[curFrag],(uint8_t*)&bfr->hdr,FRAGMENT_RECORD_SIZE);

  if(size>FRAGMENT_SIZE)
    size-=FRAGMENT_SIZE;
  else
   size=0;
  noFreeFragments--;
  curFrag = bfr->hdr.nextFragment;
  }while(curFrag!=LAST_FRAGMENT && size);



 if(size>0)
   success=!SUCCESS;  //the advertized size does not match, theres
                      //something wrong
 return success;
}


/*******DELETING A FILE*************************/

result_t delete_file(uint16_t ndex){
  uint16_t curFrag,nextFrag;

  //if no users are using it, first take it out of the boot sector
  //to avoid problems of crasing while deleting

  //if now the thing fails while deleting, since we update the
  //boot sector first, it will be claned at next bootup

    curFrag = bootSector.record[ndex].firstFragment;
     do{ 
      nextFrag =  fragments[curFrag].nextFragment;
      free_fragment(curFrag);  
      curFrag = nextFrag;
    }while(curFrag!=LAST_FRAGMENT);

   atomic{
    bzero((uint8_t*)&bootSector.record[ndex],BOOT_RECORD_SIZE);
    curWriteOffset[ndex]=0;
   }
  
 return SUCCESS;
}


/*****STDCONTORL INTERFACE STARTS************/

/*read the boot sector from flash and get the latest valid copy
of boot sector. Otherwise create anew boot sector.*/

  command result_t StdControl.init(){
   // #ifdef DD_DEBUG
   //   call Leds8.init();
   // #endif
   // #ifdef FS_DEBUG
   //  call Leds.init();
   // #endif
   return SUCCESS;        
  }



   command result_t StdControl.start(){
    uint16_t i;
    BootSector *boot_ptr1,*boot_ptr2;
    uint8_t sel;
    result_t success;
    bool needRewrite=false;


  

    boot_ptr1 = read_boot_sector(0); //read the first boot sector
    boot_ptr2 = read_boot_sector(1);  //read the second boot sector
		
    sel = find_latest_valid_boot_sector(boot_ptr1,boot_ptr2);


     switch(sel){
      case 1 : curBootRecordNumber=0;memcpy(&bootSector,boot_ptr1,BOOT_SECTOR_SIZE);
               curMagicNumber=get_magic_number_index(boot_ptr1->magic_number);break;
      case 2 : curBootRecordNumber=1;memcpy(&bootSector,boot_ptr2,BOOT_SECTOR_SIZE);
               curMagicNumber=get_magic_number_index(boot_ptr2->magic_number);break;
      case 0 : curBootRecordNumber=0;
               bzero((uint8_t*)&bootSector,BOOT_SECTOR_SIZE);
               bootSector.magic_number=MAGIC_NUMBER1;
               curBootRecordNumber=0;
               commit_boot_sector(curBootRecordNumber);
	       curBootRecordNumber=1;
               bootSector.magic_number=MAGIC_NUMBER2;
               curMagicNumber=1;
               commit_boot_sector(curBootRecordNumber);
               break;
      default : success = !SUCCESS;break;
    }

   for(i=0;i<MAX_FRAGMENTS;i++){
     bzero((uint8_t*)&fragments[i],FRAGMENT_RECORD_SIZE);
     fragments[i].nextFragment=LAST_FRAGMENT;
   }

   noFreeFragments=MAX_FRAGMENTS;

   bzero((uint8_t*)curWriteOffset,MAX_FILES*sizeof(uint16_t));

   for(i=0;i<MAX_FILES;i++){
     if(bootSector.record[i].flags){ 
        if(!populate_fragments_and_chk_sanity(i)){
           if(bootSector.record[i].flags==VALID)
             delete_file(i);
           bzero((uint8_t*)&bootSector.record[i],BOOT_RECORD_SIZE);
           needRewrite=true;
      }
      else{           
         curWriteOffset[i]=bootSector.record[i].size;
      }
     }
   }

   if(needRewrite)
    success = update_boot_sector();

   return success;
   }

   command result_t StdControl.stop(){
      return SUCCESS;
   }

  /**********END OF STDCONTROL IMPLEMENTATION *****/
   

/*START OF THE FILE SYSTEM INTERFACE****/


/*****FILE CREATION********************************************/

  result_t async command FileSystem.create(userId_t ID, uint16_t size){
    uint16_t freeIndex;
    result_t success=!SUCCESS;
    uint16_t firstRecord;
    uint16_t newRecord;
    uint16_t prevRecord;
    uint16_t temp;
    uint16_t length;
    uint16_t noFragmentsNeeded;
    uint16_t startPosition;

   length=size;

   debug_msg("CreateFileSytem\r\n");
  
   if(!length)   {	//if size is zero return immideatly
     debug_msg("0 len\r\n");
     return !SUCCESS;
   }

  //check if there are enough free fragments
  //note that this does not guarantee anything since zeevo may fail
  //when trying to get the fragment
  noFragmentsNeeded = size/FRAGMENT_SIZE;
  if(size%FRAGMENT_SIZE)
    noFragmentsNeeded++;

  atomic{
    if(getBootIndex(ID)==ERROR){ //if the ID is not already used up  
     for(freeIndex=0;freeIndex<MAX_FILES;freeIndex++){
      if(!bootSector.record[freeIndex].flags){
            success=SUCCESS;break;
      }
    }

    if(success){
     bootSector.record[freeIndex].flags=BEING_CREATED;//reserve this
     bootSector.record[freeIndex].userId=ID; 
    }
   }
 }
  
    debug_msg("1\r\n");


  if(success){ 
     if((firstRecord = reserve_next_free_fragment(ID,0))==ERROR){
          //was not able to get even a single free fragment, so free the bootsector
          //space and return
         atomic{
          bootSector.record[freeIndex].flags=0;
          bootSector.record[freeIndex].userId=0;
         }
          debug_msg("no free segs \r\n");
          return !SUCCESS;
    }
    if(size>FRAGMENT_SIZE)
      size-=FRAGMENT_SIZE;
    else
      size=0;
    prevRecord=firstRecord;

    //allocate enough fragments for the file
    startPosition=0;
    while(size){
       startPosition+=FRAGMENT_SIZE;
       if((newRecord = reserve_next_free_fragment(ID,startPosition))!=ERROR){
        fragments[prevRecord].nextFragment=newRecord;  
        prevRecord=newRecord;
        if(size>FRAGMENT_SIZE)
         size-=FRAGMENT_SIZE;
        else
         size=0;
 
      }
      else{//could not allocate enough fragments for the file, so clean up
           //allocated space, ideally this should never happen, cos we have already
          //assured that there enough space
        success=!SUCCESS;
        debug_msg("Can't allocate enough frags\r\n");
        break;
      }
    }
   }


    debug_msg("2\r\n");

    //things worked and now we can commit file to flash
    if(success){

    debug_msg("3\r\n");

     success = commit_created_file_to_flash(firstRecord); //this function cleans up
     //if its not able to commit
     if(success){
      debug_msg("4\r\n");
      atomic{
       bootSector.record[freeIndex].flags=CREATED; //now its been created
       bootSector.record[freeIndex].size = length;
       bootSector.record[freeIndex].firstFragment = firstRecord;
      }
     } else {
      debug_msg("5\r\n");
     }
    }

      //things went wrong so cleanup everything that was allocated
    if(!success){
     prevRecord=firstRecord;
     do{
     newRecord = fragments[prevRecord].nextFragment;
     free_fragment(prevRecord);
     prevRecord=newRecord;
    }while(prevRecord!=LAST_FRAGMENT);
    atomic{
        bootSector.record[freeIndex].flags=0;
        bootSector.record[freeIndex].userId=0;
    }
   }
   return success;
  }

/**********************FILE CREATION OVER*******************/

/************FILE DELETION*******************************/

  result_t async command FileSystem.delete(userId_t ID){
    uint16_t ndex;
    result_t success=!SUCCESS;
    bool needs_update=false;
    atomic{
       if((ndex = getBootIndex(ID))!=ERROR){
         if(!noUsers[ndex]){
           if(bootSector.record[ndex].flags==VALID)
            needs_update=true;
           bootSector.record[ndex].flags=BEING_DELETED;
           success=SUCCESS;
         }
       }
    }
    if(needs_update)
      success = update_boot_sector();
    if(success)
      success = delete_file(ndex);
//    if(success)
  //    success = update_boot_sector();
    return success;
  }
  
/*************APPEND TO AND READ FROM FILE*********************/ 

  //returns the fragment with beggining of the location
  uint16_t seekFragment(uint16_t ndex, uint16_t location){
    uint16_t curFragment;
    uint16_t bytesLeft;
    uint16_t retVal = ERROR;
    result_t success;
    char temps[100];

      bytesLeft=location;
      curFragment = bootSector.record[ndex].firstFragment;
      do{
       if(bytesLeft < FRAGMENT_SIZE){
         retVal=curFragment;
         break;
       }
       curFragment = fragments[curFragment].nextFragment;
       bytesLeft-=FRAGMENT_SIZE;
    }while(curFragment!=LAST_FRAGMENT);
   return retVal;
  }

   void doNothing(){
    }

  uint16_t async command FileSystem.append(userId_t ID, uint8_t *buffer, uint16_t size){ 
     uint16_t curFragment;
     uint16_t writableBytesInRecord;
     uint16_t bytesLeftToWrite;
     uint16_t bytesToWriteToRecord = 0;
     uint16_t finPos=0;
     bool firstFragment = true;
     uint16_t bytesWritten=0;
     uint16_t ndex;
     ZeevoRecord *rd_bfr,*wr_bfr;
     bool written = false;
     uint16_t *de_num;
     char temps[100];

     //if input arguments are flawed
     if(!(buffer && size))
       return 0;


     atomic{
       if((ndex = getBootIndex(ID))!=ERROR){
        if(!(bootSector.record[ndex].flags&COMMITED) && !(bootSector.record[ndex].flags&BEING_WRITTEN) && bootSector.record[ndex].size+1 > (size + curWriteOffset[ndex])){
            noUsers[ndex]++;
            bootSector.record[ndex].flags|=BEING_WRITTEN;
            written=true;
         }
       }
     }
  
     if(!written){
       if(ndex == ERROR){
         sprintf(temps,"append failed: file %d not found in boot sector\r\n",ID);
         debug_msg(temps);
       }
       if(bootSector.record[ndex].flags&COMMITED){
         sprintf(temps,"append failed : file %d already commited\r\n",ID);
         debug_msg(temps);
       }
       if(bootSector.record[ndex].flags&BEING_WRITTEN){
         sprintf(temps,"append failed : file %d being written\r\n",ID);
         debug_msg(temps);
       }
       if(bootSector.record[ndex].size < (size + curWriteOffset[ndex]) ){
         sprintf(temps,"append failed : file %d file size = %d current offset = %d size = %d\r\n",ID,bootSector.record[ndex].size,curWriteOffset[ndex],size);
         debug_msg(temps);
       }
       return 0;
     }
  
     if((curFragment = seekFragment(ndex,curWriteOffset[ndex]))==ERROR){
        atomic{
           noUsers[ndex]--; //can delete
           bootSector.record[ndex].flags=bootSector.record[ndex].flags^BEING_WRITTEN;             
           }
           sprintf(temps,"append failed : file %d could not get first fragment\r\n",ID);
           debug_msg(temps);      
	   return 0;
         }

     bytesLeftToWrite=size;
     do{
         writableBytesInRecord = FRAGMENT_SIZE;
         if(firstFragment){
           writableBytesInRecord -= (curWriteOffset[ndex]-fragments[curFragment].position);         
         }

         if(bytesLeftToWrite < writableBytesInRecord){
            bytesToWriteToRecord = bytesLeftToWrite;
         }
         else{  
          bytesToWriteToRecord = writableBytesInRecord;
         }
         if(firstFragment && curWriteOffset[ndex]-fragments[curFragment].position>0){
             if((rd_bfr = read_fragment_from_flash(FRAGMENTNO_ZEEVOID(curFragment)))==NULL){
                written=false;
         sprintf(temps,"append failed : file %d couldn't read fragment no %d\r\n",ID,curFragment);
         debug_msg(temps);
                break;    
             }
         }
       
         if(written){
         //  if((wr_bfr = (ZeevoRecord*)TM_API_GetFlashWritePtr(FRAGMENTNO_ZEEVOID(curFragment),ZEEVO_RECORD_SIZE))!=NULL){
            if(1){
          //   bzero((uint8_t*)wr_bfr,ZEEVO_RECORD_SIZE);
            // memcpy((uint8_t*)&wr_bfr->hdr,(uint8_t*)&fragments[curFragment],FRAGMENT_RECORD_SIZE);
            // wr_bfr->hdr.flags|=COMMITED;                
             if(firstFragment && curWriteOffset[ndex]-fragments[curFragment].position>0){
             //  memcpy((uint8_t*)wr_bfr->data,(uint8_t*)rd_bfr->data,curWriteOffset[ndex]-fragments[curFragment].position);
             //  memcpy((uint8_t*)&(wr_bfr->data[curWriteOffset[ndex]-fragments[curFragment].position]),buffer,bytesToWriteToRecord);
               firstFragment=false;
             }
             else{
	       //memcpy((uint8_t*)&(wr_bfr->data),&buffer[bytesWritten],bytesToWriteToRecord);   
             }
             wr_bfr->chkSum = chk_sum(wr_bfr);
             //TM_API_FlashWriteDone(FRAGMENTNO_ZEEVOID(curFragment)); 
             atomic{
               fragments[curFragment].flags|=COMMITED; //mark this commited
               curWriteOffset[ndex]+=bytesToWriteToRecord; //you have successfully 
                                                           //  read so many now
             }
             written=true;
             bytesLeftToWrite-=bytesToWriteToRecord;
             bytesWritten+=bytesToWriteToRecord; 
             curFragment = fragments[curFragment].nextFragment;
           }
           else{
          sprintf(temps,"append failed : file %d couldn't write to the fragment\r\n",ID);
         debug_msg(temps);             
           }
         }
         else
            break;
    }while(curFragment!=LAST_FRAGMENT && bytesLeftToWrite);

    //make it free for deletion and for others to write to it
    atomic{
       noUsers[ndex]--; //cannot delete
       bootSector.record[ndex].flags=bootSector.record[ndex].flags^BEING_WRITTEN;             
    }

    return bytesWritten;   
 }




  uint16_t async command FileSystem.write(userId_t ID, uint8_t *buffer, uint16_t  location, uint16_t size){ 
     uint16_t oldOffset,ndex,bytesWritten;
     
     atomic{
       if((ndex = getBootIndex(ID))!=ERROR){
          oldOffset = curWriteOffset[ndex];
          curWriteOffset[ndex]=location;
       }
     }

    if(!(bytesWritten = call FileSystem.append(ID,buffer,size))){
       atomic{
          curWriteOffset[ndex] = oldOffset;
       }
    }
   return bytesWritten;
  }




 uint16_t async command FileSystem.getFileSize(userId_t ID){
    uint16_t ndex;
    uint16_t size=0;
    atomic{
     if((ndex = getBootIndex(ID))!=ERROR)
       size=bootSector.record[ndex].size;   
     } 
    return size;
 }


 uint16_t async command FileSystem.read(userId_t ID, uint8_t *buffer, uint16_t location, uint16_t length){
     uint16_t curFragment;
     uint16_t startPositionInFragment;
     uint16_t endPositionInFragment;
     uint16_t validBytesInFragment;
     uint16_t bytesLeftToRead = length;
     uint16_t bytesToReadFromRecord = 0;
     bool firstFragment = true;
     uint16_t bytesRead=0;
     ZeevoRecord *bfr;
     uint16_t ndex;
     result_t success=!SUCCESS;
     uint16_t *de_num;

  //perform basic sanity checks for input parameters


   if(!(buffer && length))
     return 0;

   bzero(buffer,length);

  atomic{
    if((ndex = getBootIndex(ID))!=ERROR){ 
          //if there was something ever written to the portion you want tp read 
          //it only then read something
          if( curWriteOffset[ndex] > location){
            
	   if((curFragment = seekFragment(ndex,location))!=ERROR){ 
             noUsers[ndex]++; //increment no of users, 
                               //so file cannot be deleted now
             success=SUCCESS;
           }
        }
    }   
   }

   if(!success)
     return 0;

   bytesLeftToRead=length;
    do{
 
     atomic{        
      if(!(fragments[curFragment].flags&COMMITED))   //read if the fragment has been 
                success=!SUCCESS;                             //actually written
      }
      if(!success) 
        break;    

 

     startPositionInFragment=0;
     endPositionInFragment=FRAGMENT_SIZE-1;  

     if(firstFragment)
       startPositionInFragment+=(location - fragments[curFragment].position);

     atomic{
     //if(fragments[curFragment].nextFragment==LAST_FRAGMENT || )
      if(fragments[curFragment].position+FRAGMENT_SIZE > curWriteOffset[ndex])
       endPositionInFragment = curWriteOffset[ndex] - fragments[curFragment].position-1;
     }
     validBytesInFragment = endPositionInFragment - startPositionInFragment+1;

    //how many bytes are to be read from this fragment
      if(bytesLeftToRead < validBytesInFragment)
         bytesToReadFromRecord = bytesLeftToRead;
      else
         bytesToReadFromRecord = validBytesInFragment;
      
      bfr = read_fragment_from_flash(FRAGMENTNO_ZEEVOID(curFragment));

 
  
      if(bfr){
        memcpy((uint8_t*)&buffer[bytesRead],(uint8_t*)&bfr->data[startPositionInFragment],bytesToReadFromRecord);
        bytesLeftToRead-=bytesToReadFromRecord;
        bytesRead+=bytesToReadFromRecord;
      }
      else
        break;

      if(firstFragment)
        firstFragment=false;

      

      curFragment = fragments[curFragment].nextFragment;

    }while(curFragment!=LAST_FRAGMENT && bytesLeftToRead);

   //release the file for possible deletion       
    atomic{
     noUsers[ndex]--;
    }
    

   return bytesRead;
  }


 result_t async command FileSystem.commit(userId_t ID){
    uint16_t ndex;
    result_t success=!SUCCESS;

    atomic{
    if((ndex=getBootIndex(ID))!=ERROR){
     if(!(bootSector.record[ndex].flags&BEING_WRITTEN)){ //you cannot commit it while
                                                        //its still being written
      bootSector.record[ndex].flags=VALID;
      success=SUCCESS;
     }
    }
   }

  if(success){
    #ifdef WRITE_CRASH_ID
     if(ID==WRITE_CRASH_ID)
      write_crash=true;
    else
     write_crash=false;
    #endif
    success = update_boot_sector();
  }
  
   return success;
  }
 
   result_t async command FileSystem.getFileInfo(FileInfo* fi){
     uint16_t i,j;
     result_t success=!SUCCESS;
     j=0;
     atomic{
     for(i=0;i<MAX_FILES;i++){
       if(bootSector.record[i].flags&CREATED){
          fi[j].ID = bootSector.record[i].userId;
          fi[j].size = bootSector.record[i].size;
          j++;
          success=SUCCESS;
       }
      }
    }
   return success;
  }

}
