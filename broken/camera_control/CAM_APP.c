#include "tos.h"
#include "CAM_APP.h"
#include "dbg.h"
#include <math.h>

const char MAX = 80;

#define TOS_FRAME_TYPE CAM_APP_obj_frame
TOS_FRAME_BEGIN(CAM_APP_obj_frame) {
  short offsetX;
  short offsetY;
  short offsetZ;
  float sinCameraTilt;
  float cosCameraTilt;
  float cameraTilt;
  char count;
  char rows;
  char columns;
  short colSpacing;
  short rowSpacing;
  char ready;
  char state;
  
  char weight;
  char dir;
}
TOS_FRAME_END(CAM_APP_obj_frame);


char TOS_COMMAND(APP_INIT)(){
  dbg(DBG_BOOT, ("CAM_APP initialized.\n"));
  TOS_CALL_COMMAND(APP_SUB_INIT)();
  VAR(weight) = 0;
  VAR(dir) = 0;
  VAR(ready) = 0;
  VAR(state) = 0;
  return 1;
}

char TOS_COMMAND(APP_START)(){
  dbg(DBG_BOOT, ("CAM_APP started.\n"));
  TOS_CALL_COMMAND(APP_SUB_START)();
  TOS_CALL_COMMAND(APP_SET_CONSTANTS)(135, 24, -55, (M_PI/4));
  TOS_CALL_COMMAND(APP_POPULATE)(4, 4, -24, -36);
  TOS_CALL_COMMAND(APP_SUB_CLOCK_INIT)(tick1ps);
  return 1;
}

char TOS_COMMAND(APP_SET_CONSTANTS)(short offsetX,
				    short offsetY,
				    short offsetZ,
				    float cameraTilt) {
  VAR(cameraTilt) = cameraTilt;
  VAR(sinCameraTilt) = sin(cameraTilt);
  VAR(cosCameraTilt) = cos(cameraTilt);
  dbg(DBG_USR1, ("CAM_APP: Constants set: cameraTilt: %f sinCameraTilt: %f cosCameraTilt: %f\n", cameraTilt, VAR(sinCameraTilt), VAR(cosCameraTilt)));
  VAR(offsetX) = offsetX;
  VAR(offsetY) = offsetY;
  VAR(offsetZ) = offsetZ;
  return 1;
}

static const float PAN_COEFF = 820.0/90.0;
static const float TILT_COEFF = 1300.0/90.0;

void addMote(short id, short x, short y, short z) {

  float xRot;
  float yRot;
  float zRot;
  float pan, tilt, hypotenuse;

  
  x += VAR(offsetX);
  y += VAR(offsetY);
  z += VAR(offsetZ);
  xRot = ((float)x * VAR(cosCameraTilt)) - ((float)z * VAR(sinCameraTilt));
  yRot = (float)y;
  zRot = ((float)z * VAR(cosCameraTilt)) + ((float)x * VAR(sinCameraTilt));

  //x = xRot;
  //y = yRot;
  //z = zRot;
  
  hypotenuse = sqrt(xRot*xRot + yRot*yRot);
  pan = atan(yRot / xRot) / M_PI / 2.0 * 360.0 * PAN_COEFF;
  tilt = atan(zRot / hypotenuse) / M_PI / 2.0 * 360.0 * TILT_COEFF;

  //dbg(DBG_USR1, ("CAM_APP: 2%02hhx xrot: %f, yrot: %f, zrot: %f\n", VAR(count), xRot, yRot, zRot));

  dbg(DBG_USR3, ("CAM_APP: Adding mote 2%02hx with pan %04hx and tilt %04hx\n", id,(short)pan, (short)tilt));
  TOS_CALL_COMMAND(APP_SUB_ADD_POINT)(id, (short)pan, (short)tilt, 200);

}

TOS_TASK(calcMote) {
  short y = VAR(count) & 0xf;
  short x = (VAR(count) & 0xf0) >> 4;
  addMote(VAR(count), y * VAR(colSpacing), x * VAR(rowSpacing), 0);
  VAR(count++);
  if ((VAR(count) & 0xf) == VAR(rows)) {
    VAR(count) += 0x10;
    VAR(count) &= ~(0xf);
  }
  if (((VAR(count) & 0xf0) >> 4) < VAR(columns)) {
    TOS_POST_TASK(calcMote);
  }
  else {
    VAR(count) = 0;
    VAR(ready) = 1;
  }
}

typedef struct {
   char nodeID;
   unsigned int value;
} dataReading;

typedef struct {
   char type;
   char pack_ID;
   char from;
   dataReading readings[4];
} agroDataPacket;

TOS_MsgPtr TOS_EVENT(APP_REL_MSG)(TOS_MsgPtr msg) {
  TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
  if (msg->crc && VAR(state) == 0 &&
      ((msg->addr & 0xff)  == 0)) { // Message sent to origin
    int i;
    agroDataPacket* data  = (agroDataPacket*)msg->data;
    if (data->type != 0) {return msg;} // Not magnetometer reading
    dataReading* readings = data->readings;
    for (i = 0; i < 4; i++) { // There are at most 4 readings in a packet
      char tmp = (data->readings[i].value >> 11);
      if (!tmp && readings[i].value) {
	tmp = 1;
      }
      data->readings[i].value = tmp;
    }
    if ((readings[0].value +
	 readings[1].value +
	 readings[2].value +
	 readings[3].value) > 0) {
      
      TOS_CALL_COMMAND(APP_SUB_GOTO)(readings[0].nodeID, readings[0].value,
				     readings[1].nodeID, readings[1].value,
				     readings[2].nodeID, readings[2].value,
				     readings[3].nodeID, readings[3].value);
      // Reset the timer: only move camera twice a second
      TOS_CALL_COMMAND(APP_SUB_CLOCK_INIT)(tick4ps);
      TOS_CALL_COMMAND(APP_SUB_CLOCK_INIT)(tick2ps);
      VAR(state) = 1;
    }
  }
  return msg;
}


char TOS_COMMAND(APP_POPULATE)(char rows, char columns, 
			       short rowSpacing, short colSpacing) {
  VAR(rows) = rows;
  VAR(columns) = columns;
  VAR(colSpacing) = colSpacing;
  VAR(rowSpacing) = rowSpacing;
  VAR(count) = 0;
  TOS_POST_TASK(calcMote);
  return 1;
}



TOS_TASK(runTask) {
  dbg(DBG_USR1, ("CAM_APP: Goto 2%02hhx\n", VAR(count)));
  
  TOS_CALL_COMMAND(APP_SUB_GOTO)((short)1, 1,
				 (short)1, 1,
				 (short)1, 1,
				 (short)1, 1);

  VAR(count)++;
  if ((VAR(count) & 0xf) == VAR(rows)) {
    VAR(count) += 0x10;
    VAR(count) &= ~(0xf);
  }
  if (((VAR(count) & 0xf0) >> 4) >= VAR(columns)) {
    VAR(count) = 0;
  }
}

void TOS_EVENT(APP_SUB_CLOCK)() {
  dbg(DBG_USR2, ("CAM_APP: Clock interrupt.\n"));
  TOS_CALL_COMMAND(APP_SUB_YELLOW_LED_TOGGLE)();
  VAR(state) = 0;
}

char TOS_EVENT(APP_SEND_DONE)(TOS_MsgPtr msg) {
  return 1;
}
