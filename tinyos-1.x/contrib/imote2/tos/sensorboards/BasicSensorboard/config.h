#ifndef __CONFIG_H__
#define __CONFIG_H__

//ONLY CONSTANTS MAY GO IN HERE!!!!

//total number of channels that the board exposes...be sure to include a "Fake" data channel if one exists for your board
#define TOTAL_CHANNELS (3)

//total number of data interfaces that this board utilizes for sampling
//each data interface is interlocked such that once sampling has been started
//on a data interface or a member of its simultaneous sampling group, another sampling instance may not be started until
//the current one is finished.
#define TOTAL_DATA_CHANNELS 3


//#define DOCHUNKING 1
#define CHUNKSIZE (100)  //in samples

//#define DOPRETRIGGER

#define BLUSH_TRIGGER

#endif //__CONFIG_H__



