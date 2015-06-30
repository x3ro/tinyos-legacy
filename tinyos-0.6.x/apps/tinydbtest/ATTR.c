/* component to register all the attributes */
#include "tos.h"
#include "dbg.h"
#include "ATTR.h"

#define TOS_FRAME_TYPE ATTR_obj_frame
TOS_FRAME_BEGIN(ATTR_obj_frame) {
	CommandCallInfo *tempCallInfo;
	CommandCallInfo *lightCallInfo;
	CommandCallInfo *voltageCallInfo;
	CommandCallInfo *accelxCallInfo;
	CommandCallInfo *accelyCallInfo;
}
TOS_FRAME_END(ATTR_obj_frame);

char TOS_COMMAND(ATTR_INIT)(void)
{
	VAR(tempCallInfo) = NULL;
	VAR(lightCallInfo) = NULL;
	VAR(voltageCallInfo) = NULL;
	TOS_CALL_COMMAND(SCHEMA_INIT)();
	TOS_CALL_COMMAND(ADD_ATTR)("temp", INTTWO, 2, getTemp, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("light", INTTWO, 2, getLight, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("voltage", INTTWO, 2, getVoltage, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("nodeid", INTTWO, 2, getId, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("parent", INTTWO, 2, getParent, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("accel_x", INTTWO, 2, getAccelX, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("accel_y", INTTWO, 2, getAccelY, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("mag_x", INTTWO, 2, getMagX, NULL);
	TOS_CALL_COMMAND(ADD_ATTR)("mag_y", INTTWO, 2, getMagY, NULL);
	TOS_CALL_COMMAND(ADD_COMMAND)("SetPot", (func_ptr)setPot, VOID, 0, 1, INTONE);
	TOS_CALL_COMMAND(ADD_COMMAND)("SetTopo", (func_ptr)setTopology, VOID, 0, 1, INTONE);
	TOS_CALL_COMMAND(ADD_COMMAND)("SetCent", (func_ptr)setCentralized, VOID, 0, 1, INTONE);
	TOS_CALL_COMMAND(ADD_COMMAND)("Reset", (func_ptr)selfDestruct, VOID, 0, 0);
	TOS_CALL_COMMAND(ADD_COMMAND)("FixComm", (func_ptr)useFixedComm, VOID, 0, 1, INTONE); 
	TOS_CALL_COMMAND(ADD_COMMAND)("StopMag", (func_ptr)stopMag, VOID, 0, 0);
	TOS_CALL_COMMAND(ATTR_SUB_INIT)();
	return TOS_Success;
}

char TOS_COMMAND(ATTR_START)(void)
{
		return TOS_Success;
}

char setPot(int1 *pot, CommandCallInfo *callInfo)
{
	TOS_CALL_COMMAND(SET_POT)(*pot);
	callInfo->errorNo = SCHEMA_SUCCESS;
	return TOS_Success;
}

char setTopology(int1 *fanout, CommandCallInfo *callInfo)
{
	TOS_CALL_COMMAND(FORCE_TOPOLOGY)(*fanout);
	callInfo->errorNo = SCHEMA_SUCCESS;
	return TOS_Success;
}

char setCentralized(int1 *on, CommandCallInfo *callInfo)
{
	TOS_CALL_COMMAND(SET_CENTRALIZED)(*on);
	callInfo->errorNo = SCHEMA_SUCCESS;
	return TOS_Success;
}

char useFixedComm(int1 *fix, CommandCallInfo *callInfo)
{
	TOS_CALL_COMMAND(SET_FIXED_COMM)(*fix);
	callInfo->errorNo = SCHEMA_SUCCESS;
	return TOS_Success;
}


char selfDestruct(CommandCallInfo *callInfo) {
  TOS_CALL_COMMAND(SELF_DESTRUCT)();
  callInfo->errorNo = SCHEMA_SUCCESS;
  return TOS_Success;
}

char stopMag(CommandCallInfo *callInfo) {
  TOS_CALL_COMMAND(ATTR_MAGNET_STOP)();
  callInfo->errorNo = SCHEMA_SUCCESS;
  return TOS_Success;
}

char getTemp(CommandCallInfo *callInfo)
{
	char success;
	TOS_CALL_COMMAND(ATTR_TEMP_INIT)();
  success = TOS_CALL_COMMAND(ATTR_TEMP_GET_DATA)();
  callInfo->errorNo = SCHEMA_RESULT_PENDING;
  VAR(tempCallInfo) = callInfo;
  return success;
}

char getLight(CommandCallInfo *callInfo)
{
	char success;
	TOS_CALL_COMMAND(ATTR_PHOTO_INIT)();
  success = TOS_CALL_COMMAND(ATTR_PHOTO_GET_DATA)();
  callInfo->errorNo = SCHEMA_RESULT_PENDING;
  VAR(lightCallInfo) = callInfo;
  return success;
}

char getVoltage(CommandCallInfo *callInfo)
{
  char success = TOS_CALL_COMMAND(ATTR_VOLTAGE_GET_DATA)();
  callInfo->errorNo = SCHEMA_RESULT_PENDING;
  VAR(voltageCallInfo) = callInfo;
  return success;
}
char getAccelX(CommandCallInfo *callInfo)
{
	char success;
  success = TOS_CALL_COMMAND(ATTR_ACCELX_GET_DATA)();
  callInfo->errorNo = SCHEMA_RESULT_PENDING;
  VAR(accelxCallInfo) = callInfo;
  return success;
}

char getAccelY(CommandCallInfo *callInfo)
{
	char success;
  success = TOS_CALL_COMMAND(ATTR_ACCELY_GET_DATA)();
  callInfo->errorNo = SCHEMA_RESULT_PENDING;
  VAR(accelyCallInfo) = callInfo;
  return success;
}

char getMagX(CommandCallInfo *callInfo)
{
	*(int2*)(callInfo->resultBuf) = TOS_CALL_COMMAND(ATTR_MAGX_GET_DATA)();
	callInfo->errorNo = SCHEMA_RESULT_READY;
	return TOS_Success;
}

char getMagY(CommandCallInfo *callInfo)
{
	*(int2*)(callInfo->resultBuf) = TOS_CALL_COMMAND(ATTR_MAGY_GET_DATA)();
	callInfo->errorNo = SCHEMA_RESULT_READY;
	return TOS_Success;
}

char getId(CommandCallInfo *callInfo)
{
	*(int2*)(callInfo->resultBuf) = TOS_LOCAL_ADDRESS;
	callInfo->errorNo = SCHEMA_RESULT_READY;
	return TOS_Success;
}

char getParent(CommandCallInfo *callInfo)
{
	*(int2*)(callInfo->resultBuf) = TOS_CALL_COMMAND(GET_PARENT)();
	callInfo->errorNo = SCHEMA_RESULT_READY;
	return TOS_Success;
}

char TOS_EVENT(ATTR_TEMP_DATA_READY)(short data)
{
	*(int2*)(VAR(tempCallInfo)->resultBuf) = data;
	VAR(tempCallInfo)->errorNo = SCHEMA_RESULT_READY;
	TOS_CALL_COMMAND(ATTR_TEMP_PWR)(0);
	SCHEMA_END_COMMAND(ATTR_COMMAND_COMPLETE, VAR(tempCallInfo));
	return TOS_Success;
}

char TOS_EVENT(ATTR_PHOTO_DATA_READY)(short data)
{

  *(int2*)(VAR(lightCallInfo)->resultBuf) = data;
  VAR(lightCallInfo)->errorNo = SCHEMA_RESULT_READY;
	TOS_CALL_COMMAND(ATTR_PHOTO_PWR)(0);
  SCHEMA_END_COMMAND(ATTR_COMMAND_COMPLETE, VAR(lightCallInfo));
  return TOS_Success;
}

char TOS_EVENT(ATTR_VOLTAGE_DATA_READY)(short data)
{
  *(int2*)(VAR(voltageCallInfo)->resultBuf) = data;
  VAR(voltageCallInfo)->errorNo = SCHEMA_RESULT_READY;
  SCHEMA_END_COMMAND(ATTR_COMMAND_COMPLETE, VAR(voltageCallInfo));
  return TOS_Success;
}
char TOS_EVENT(ATTR_ACCELX_DATA_READY)(short data)
{
  *(int2*)(VAR(accelxCallInfo)->resultBuf) = data;
  VAR(accelxCallInfo)->errorNo = SCHEMA_RESULT_READY;
  SCHEMA_END_COMMAND(ATTR_COMMAND_COMPLETE, VAR(accelxCallInfo));
  return TOS_Success;
}

char TOS_EVENT(ATTR_ACCELY_DATA_READY)(short data)
{
  *(int2*)(VAR(accelyCallInfo)->resultBuf) = data;
  VAR(accelyCallInfo)->errorNo = SCHEMA_RESULT_READY;
  SCHEMA_END_COMMAND(ATTR_COMMAND_COMPLETE, VAR(accelyCallInfo));
  return TOS_Success;
}
