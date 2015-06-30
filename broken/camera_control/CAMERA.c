#include "tos.h"
#include "CAMERA.h"
#include "dbg.h"

typedef struct {
  short id;
  short tilt;
  short pan;
  short zoom;
  short weight;
} LookupEntry;

#define MAX_ENTRIES 36
#define MESSAGE_SIZE 24

typedef enum {CAMERA_READY, CAMERA_COMPUTING, CAMERA_SENDING} State;

#define TOS_FRAME_TYPE CAMERA_obj_frame
TOS_FRAME_BEGIN(CAMERA_obj_frame) {
  TOS_Msg storage;
  TOS_MsgPtr buffer;
  LookupEntry table[MAX_ENTRIES];
  int lastEntry;
  State state;
  int one;
  int two;
  int three;
  int four;
  short tilt;
  short pan;
  short zoom;
  char cameraPacket[MESSAGE_SIZE];
}
TOS_FRAME_END(CAMERA_obj_frame);


char TOS_COMMAND(CAMERA_INIT)(){
  VAR(lastEntry) = 0;
  VAR(state) = CAMERA_READY;
  VAR(buffer) = &VAR(storage);
  return  TOS_CALL_COMMAND(CAMERA_SUB_INIT)();
}

char TOS_COMMAND(CAMERA_START)(){
  return 1;
}

char TOS_COMMAND(CAMERA_ADD_POINT)(short id, short pan, short tilt, short zoom) {
  if (VAR(lastEntry) < MAX_ENTRIES) {
    dbg(DBG_USR1, ("CAMERA: Adding point[%i]: %hx pan: %04hx, tilt: %04hx, zoom %04hx\n", (int)VAR(lastEntry), id, pan, tilt, zoom));
    VAR(table)[VAR(lastEntry)].id = id;
    VAR(table)[VAR(lastEntry)].tilt = tilt;
    VAR(table)[VAR(lastEntry)].pan = pan;
    VAR(table)[VAR(lastEntry)].zoom = zoom;
    VAR(lastEntry)++;
    return 1;
  }
  else {
    return 0;
  }
}

int getEntry(short id) {
  int i;
  dbg(DBG_USR1, ("CAMERA: Get %i\n", (int)id));
  for (i = 0; i < MAX_ENTRIES; i++) {
    if (id == (VAR(table)[i].id)) {
      dbg(DBG_USR1, ("CAMERA:  Found it: %i %hi %hi\n", i, VAR(table)[i].pan, VAR(table)[i].tilt));
      return i;
    }
  }
  //TOS_CALL_COMMAND(CAMERA_SUB_RED_LED_TOGGLE)();
  return 0;
}

TOS_TASK(controlTask) {
  int i = 0;
  // First comes the point command
  VAR(cameraPacket)[i++] = 0x81; // 129/-126  // Which camera
  VAR(cameraPacket)[i++] = 0x01; // 1         // Which command
  VAR(cameraPacket)[i++] = 0x06; // 6         // Which command
  VAR(cameraPacket)[i++] = 0x02; // 2         // Which command (abs pos)
  VAR(cameraPacket)[i++] = 0x12; // 18        // How fast to pan -- max
  VAR(cameraPacket)[i++] = 0x0e; // 14        // How fast to tilt -- max

  VAR(cameraPacket)[i++] = (char)((VAR(pan) >> 12) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(pan) >> 8) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(pan) >> 4) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(pan) >> 0) & 0xf);

  VAR(cameraPacket)[i++] = (char)((VAR(tilt) >> 12) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(tilt) >> 8) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(tilt) >> 4) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(tilt) >> 0) & 0xf);
  VAR(cameraPacket)[i++] = 0xff; // End of point command

  // Then the zoom command
  VAR(cameraPacket)[i++] = 0x81; // Which camera
  VAR(cameraPacket)[i++] = 0x01; // Which command
  VAR(cameraPacket)[i++] = 0x04; // Which command
  VAR(cameraPacket)[i++] = 0x47; // Which command (Direct zoom)
  VAR(cameraPacket)[i++] = (char)((VAR(zoom) >> 12) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(zoom) >> 8) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(zoom) >> 4) & 0xf);
  VAR(cameraPacket)[i++] = (char)((VAR(zoom) >> 0) & 0xf);
  VAR(cameraPacket)[i++] = 0xff; // End of zoom command

  {
    int i;
    dbg(DBG_USR1, ("CAMERA: Sending packet:\n"));
    for (i = 6; i < 14; i++) {
      dbg_clear(DBG_USR1, ("%02hhx ", VAR(cameraPacket)[i]));
    }
    dbg_clear(DBG_USR1, ("\n"));
  }
  if (TOS_CALL_COMMAND(CAMERA_SUB_SEND_MSG)(VAR(cameraPacket), MESSAGE_SIZE)) {
    VAR(state) = CAMERA_SENDING;
  }
#ifdef TOSSIM
  else {
    VAR(state) = CAMERA_READY;
  }
#endif // TOSSIM
}

TOS_TASK(computeTask) {
  short weightSum;
  long pan, tilt, zoom;
  tilt = 0;
  pan  = 0;
  zoom = 0;

  if (VAR(one) >= 0) {
    tilt = (long)VAR(table)[VAR(one)].tilt * (long)VAR(table)[VAR(one)].weight;
    pan = (long)VAR(table)[VAR(one)].pan * (long)VAR(table)[VAR(one)].weight;
    zoom = (long)VAR(table)[VAR(one)].zoom * (long)VAR(table)[VAR(one)].weight;
    weightSum = VAR(table)[VAR(one)].weight;
  }
  
  if (VAR(two) >= 0) {
    tilt += (long)VAR(table)[VAR(two)].tilt * (long)VAR(table)[VAR(two)].weight;
    pan += (long)VAR(table)[VAR(two)].pan * (long)VAR(table)[VAR(two)].weight;
    zoom += (long)VAR(table)[VAR(two)].zoom * (long)VAR(table)[VAR(two)].weight;
    weightSum += VAR(table)[VAR(two)].weight;
  }

  if (VAR(three) >= 0) {
    tilt += (long)VAR(table)[VAR(three)].tilt * (long)VAR(table)[VAR(three)].weight;
    pan += (long)VAR(table)[VAR(three)].pan * (long)VAR(table)[VAR(three)].weight;
    zoom += (long)VAR(table)[VAR(three)].zoom * (long)VAR(table)[VAR(three)].weight;
    weightSum += VAR(table)[VAR(three)].weight;
  }

  if (VAR(four) >= 0) {
    tilt += (long)VAR(table)[VAR(four)].tilt * (long)VAR(table)[VAR(four)].weight;
    pan += (long)VAR(table)[VAR(four)].pan * (long)VAR(table)[VAR(four)].weight;
    zoom += (long)VAR(table)[VAR(three)].zoom * (long)VAR(table)[VAR(three)].weight;
    weightSum += VAR(table)[VAR(four)].weight;
  }
  
  if (weightSum > 0) {
    zoom /= (long)weightSum;
    tilt /= (long)weightSum;
    pan /= (long)weightSum;
    VAR(zoom) = (short)zoom;
    VAR(tilt) = (short)tilt;
    VAR(pan) = (short)pan;
    dbg(DBG_USR1, ("CAMERA: Pan: %hx, tilt: %hx, zoom: %hx\n", VAR(pan), VAR(tilt), VAR(zoom)));
    
  }
  else {
    VAR(zoom) = 0;
    VAR(tilt) = 0;
    VAR(pan) = 0;
  }
  TOS_POST_TASK(controlTask);
}

/* If id == 0xffff, then ignore that point. */

char TOS_COMMAND(CAMERA_GOTO)(short id1, char weight1,
			      short id2, char weight2,
			      short id3, char weight3,
			      short id4, char weight4) {
  
  if (VAR(state) != CAMERA_READY) {return 0;}
  else {
    //dbg(DBG_USR1, ("CAMERA: Goto  %hx[%hhi], %hx[%hhi], %hx[%hhi], %hx[%hhi]\n", id1, weight1, id2, weight2, id3, weight3, id4, weight4));
    VAR(state) = CAMERA_COMPUTING;
    VAR(one)   = getEntry(id1);
    VAR(two)   = getEntry(id2);
    VAR(three) = getEntry(id3);
    VAR(four)  = getEntry(id4);
    // Clear out previous weightsd
    if (VAR(one) >= 0) {VAR(table)[VAR(one)].weight   = 0;}
    if (VAR(two) >= 0) {VAR(table)[VAR(two)].weight   = 0;}
    if (VAR(three) >= 0) {VAR(table)[VAR(three)].weight = 0;}
    if (VAR(four) >= 0) {VAR(table)[VAR(four)].weight  = 0;}
    // Use += in case one id appears multiple times
    if (VAR(one) >= 0) {VAR(table)[VAR(one)].weight   += weight1;}
    if (VAR(two) >= 0) {VAR(table)[VAR(two)].weight   += weight2;}
    if (VAR(three) >= 0) {VAR(table)[VAR(three)].weight += weight3;}
    if (VAR(four) >= 0) {VAR(table)[VAR(four)].weight  += weight4;}

    TOS_POST_TASK(computeTask);
    return 1;
  }
}
  
TOS_MsgPtr TOS_EVENT(CAMERA_UART_RECEIVE)(TOS_MsgPtr msg) {
  return msg;
}

char TOS_EVENT(CAMERA_SEND_DONE)(TOS_MsgPtr msg) {
  if (VAR(state) == CAMERA_SENDING) {
    VAR(state) = CAMERA_READY;
  }
  return 1;
}
