/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors:Tian He, Brian Blum 
 */

includes Triang;

module TriangM {
  provides interface Triang as T;
}

implementation {
  DataRecordTable dataTable;
  Position aggregatePosition;
  char mutex;
  char prev;

  char refreshTable();
  char calculateTriangulatedPosition();
  char insert(char, float, float, float, uint16_t);
  char delete(uint16_t);
    
  bool isPending;
  
  /************************************************************************/
  command result_t T.init() {	
	 int i = MAX_RECORD_NUMBER;
	 
	 for(i = 0; i < MAX_RECORD_NUMBER; i++) {
		dataTable.record[i].nodeId = (uint16_t) 0xffff;
		dataTable.size = 0;
	 }	 
	 aggregatePosition.x = -1;
	 aggregatePosition.y = -1;
	 aggregatePosition.z = -1;
	 isPending = FALSE;
	 return SUCCESS;
  }
  
  /************************************************************************/
  command result_t T.reset() {

	  result_t	retval;		  
	  if(isPending)	return FAIL;  		  
	  isPending = TRUE;
	  retval = refreshTable();
	  isPending = FALSE;
	  return retval;	    
  }
  
  /***********************************************************************/
  command result_t T.insertData(char data, float x, float y, float z, uint16_t nodeId) {

	  result_t	retval;		  
	  if(isPending)	return FAIL;  		  
	  isPending = TRUE;
	  retval = insert(data, x, y, z, nodeId);
	  isPending = FALSE;
	  return retval;	
	  	  
  }
  
  /**********************************************************************/
  command result_t T.deleteData(uint16_t nodeId) {
 
 	  result_t	retval;		  
	  if(isPending)	return FAIL;  		  
	  isPending = TRUE;
	  retval = delete(nodeId);
	  isPending = FALSE;
	  return retval;	
	  	         
  }
  
  /***********************************************************************/
  command result_t T.aggregate() {

  	  result_t	retval;		  
	  if(isPending)	return FAIL;  		  
	  isPending = TRUE;
	  retval = calculateTriangulatedPosition();
	  isPending = FALSE;
	  return retval;	
	  	  	 	 
  }
  
  /************************************************************************/
  command float T.getX() {
	 return aggregatePosition.x;
  }

  /*************************************************************************/
  command float T.getY() {
	 return aggregatePosition.y;
  }

  /*************************************************************************/
  command float T.getZ() {
	 return aggregatePosition.z;
  }

  command uint8_t  T.getSize() {
    return dataTable.size;
  }

  /*************************************************************************/
  char refreshTable() {
	 int i ;
	 char isPurged = 0;

	 for(i = 0; i < MAX_RECORD_NUMBER ; i++) {
      if(dataTable.record[i].nodeId != (uint16_t) 0xffff && 
			dataTable.record[i].numResets > MAX_RESETS) {
		  dataTable.record[i].nodeId = (uint16_t) 0xffff;
		  dataTable.size--;
		  isPurged = 1;	  
		}
      else
		  dataTable.record[i].numResets++;
    }

	 return isPurged;
  }

  /*************************************************************************/
  char calculateTriangulatedPosition() {
		int count = 0;
		int totalSensorValue = 0;
		
		Position estimation;
		estimation.x = 0.0;
		estimation.y = 0.0;
		estimation.z = 0.0; 
		
		if(dataTable.size == 0 ) return 0;

#ifdef WEIGHTED_AVERAGE		  
		for(count = 0 ; count < MAX_RECORD_NUMBER ; count ++){
		  if(dataTable.record[count].nodeId != (uint16_t)0xffff){
			 estimation.x += dataTable.record[count].position.x * 
				dataTable.record[count].sensorValue;
				estimation.y += dataTable.record[count].position.y * 
				  dataTable.record[count].sensorValue;
				estimation.z += dataTable.record[count].position.z * 
				  dataTable.record[count].sensorValue;
				totalSensorValue += dataTable.record[count].sensorValue;	
		  }
		}	
#else
		for(count = 0 ; count < MAX_RECORD_NUMBER ; count ++){
		  if(dataTable.record[count].nodeId != (uint16_t)0xffff){
			 estimation.x += dataTable.record[count].position.x;
				estimation.y += dataTable.record[count].position.y;
				estimation.z += dataTable.record[count].position.z;
				totalSensorValue++;
		  }
		}	
#endif			  
		aggregatePosition.x = estimation.x / totalSensorValue;
		aggregatePosition.y = estimation.y / totalSensorValue;
		aggregatePosition.z = estimation.z / totalSensorValue;
		
		dbg(DBG_USR1, "TRIANG: the estimation is (%f,%f,%f)\n", 
			 aggregatePosition.x,
			 aggregatePosition.y,
			 aggregatePosition.z);

		return 1;		
	 }	 

  /**************************************************************************/
  char insert(char sensorValue, float x, float y, float z, uint16_t nodeId) {
	 int i = 0;
	 
	 dbg(DBG_USR1, "TRIANG: Inserting %d for %d at (%f,%f,%f)\n", 
		  sensorValue, nodeId, x, y, z);
	 
	 /* check for an entry in the table with matching NODE ID */
	 for(i = 0; i < MAX_RECORD_NUMBER ; i++){
		
		if(dataTable.record[i].nodeId == nodeId){
		  dataTable.record[i].sensorValue = sensorValue;  
		  dataTable.record[i].numResets = 0;
		  dbg(DBG_USR1, "TRIANG: Table Replace: now size is %d\n",
				dataTable.size);
		  return 0;
		}
	 }
    
	 /* insert a new entry into the table when appropriate */
	 if(i == MAX_RECORD_NUMBER ){
		
		for(i = 0; i < MAX_RECORD_NUMBER ; i++){
		  if(dataTable.record[i].nodeId == (uint16_t) 0xffff){
			 dataTable.record[i].nodeId = nodeId;       
			 dataTable.record[i].position.x = x;
			 dataTable.record[i].position.y = y;
			 dataTable.record[i].position.z = z;
			 dataTable.record[i].sensorValue = sensorValue;
			 dataTable.record[i].numResets = 0;
			 dataTable.size++;
			 dbg(DBG_USR1, "TRIANG: Add Value  %d at location (%f,%f,%f) from node %d\n Now table size is %d\n",
				  dataTable.record[i].sensorValue,
				  dataTable.record[i].position.x,
				  dataTable.record[i].position.y,
				  dataTable.record[i].position.z,
				  dataTable.record[i].nodeId,  
				  dataTable.size);
			 return 1;
		  }    
		}
	 }
	 
	 return 0;
  }

  /*************************************************************************/  
  char delete(uint16_t nodeId){
	 int i = 0;
	 
	 dbg(DBG_USR1, "TRIANG: delete %d\n", nodeId);
	 
	 /* check for an entry in the table with matching NODE ID */
	 for(i = 0; i < MAX_RECORD_NUMBER ; i++){  
		if(dataTable.record[i].nodeId == nodeId){
		  dataTable.record[i].nodeId = (uint16_t)0xffff ; 
		  dataTable.size--;
		  dbg(DBG_USR1, "TRIANG: Table delete: now size is %d\n",
				dataTable.size); 
		  return 1;
		}
	 }
	 return 0;
  }

  command result_t T.clear(){
     int i;
     
  	 for(i = 0; i < MAX_RECORD_NUMBER ; i++){  
		  dataTable.record[i].nodeId = (uint16_t)0xffff ; 
		}
	 
     dataTable.size = 0;     
     return SUCCESS;
  }
  
}
