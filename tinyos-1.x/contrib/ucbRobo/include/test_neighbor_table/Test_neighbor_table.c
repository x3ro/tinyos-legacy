/* This file is used to test neighbor_table.h in C before trying to
 * test/debug it on a Sensor Network Mote.
 * 
 * To compile this file, you need to include the paths to all of the
 * header files used by neighbor_table.h
 * ex. (this directory path might not be correct)
 *     gcc -I$TOSROOT/contrib/ucb/tos/lib -g Test_neighbor_table.c -o \
 *         Test_neighbor_table.exe
 */


#include <inttypes.h>
#include "C_Test_hacks.h"

#include "../neighbor_table.h"

uint32_t staleAge = 100;
#define TABLESIZE 3

NeighborTableEntry_t myTable[TABLESIZE];
NeighborTableEntry_t* myTableEnd =  myTable + TABLESIZE;

void Test_checkInRange() {
  uint32_t num0, num1, num2, num3, num4;

  num0 = 0;
  num1 = 1;
  num2 = 2;
  num3 = 3;
  num4 = 4;

  if (checkInRangeA(num2,num3,num1) && 
      !checkInRangeA(num4,num3,num1) && 
      !checkInRangeA(num0,num3,num1)) {
    printf("checkInRangeA is working properly\n");
  } else {
    printf("ERROR checkInRangeA\n");
  }

  if (checkInRangeB(num0,num1,num3) &&
      checkInRangeB(num4,num1,num3) &&
      !checkInRangeB(num2,num1,num3)) {
    printf("checkInRangeB is working properly\n");
  } else {
    printf("ERROR checkInRangeB\n");
  }
}


/* void Test_64Operations() { */
/*   uint64_struct_t sum0, sum1, sum2, sum3, sum4, sum5; */

/*   printf("maximum uint32_t is: %u\n",UINT32_MAX); */
  
/*   sum0 = sum64(UINT32_MAX, UINT32_MAX); */
/*   sum1 = sum64(0, 0); */
/*   sum2 = sum64(UINT32_MAX-5, 6); */
/*   sum3 = sum64(0,4); */
/*   sum4 = sum64(UINT32_MAX, UINT32_MAX-3); */
/*   sum5 = sum64(5,5); */

/*   printf("sum of two UINT32_MAX is hi:%x lo:%x\n",sum0.hi, sum0.lo); */
/*   printf("sum of 5 and 5 is hi:%x lo:%x\n",sum5.hi, sum5.lo); */
/*   if (compareGTE64(sum0, sum0) && //equality when 1 in hi */
/*       compareGTE64(sum1, sum1) && //equality when 0 in hi */
/*       compareGTE64(sum0, sum4) && //gt when 1 in hi, 1 in hi */
/*       compareGTE64(sum2, sum3)) { //gt when 1 in hi, 0 in hi */
/*     printf("compareGTE64 (and sum64) is working properly\n"); */
/*   } else { */
/*     printf("ERROR compareGTE64 (or sum64)\n"); */
/*   } */

/* } */


void Test_initTable() {
  NeighborTableEntry_t *i;
  int count = 1;
  bool working = 1;
  initTable(myTable,myTableEnd);
  for (i = myTable; i < myTableEnd; i++) {
    if (i->valid) {
      working = 0;
    }
    printf("myTable at %d has a valid flag %u\n", count, i->valid);
    count++;
  }
  if (working) {
    printf("initTable is working\n");
  } else {
    printf("initTable is not working\n");
  }
}


void printTable() {
  NeighborTableEntry_t *i;
  int count = 1;  
  for (i = myTable; i < myTableEnd; i++) {
    printf("myTable at %d has valid flag: %u;", count, i->valid);
    printf("sourceMoteID: %u; timeStamp: %u;", i->sourceMoteID, i->timeStamp);
    printf("magX: %u; magY: %u\n", i->magData.val.x, i->magData.val.y);
    count++;
  }
  printf("\n");
}

void Test_addTable() {
  NeighborTableEntry_t entry = {
    sourceMoteID: 1,
    valid: 1,
    timeStamp: 1,
    magData: {
      val: {
	x: 1,
	y: 2
      },
      bias: {
	x: 10,
	y: 10
      }
    },
    loc: {
      pos: {
	x: 0,
	y: 0
      }
    }
  }; //entry

  addTable(myTable,myTableEnd,staleAge,1,&entry);

  entry.sourceMoteID = 2;
  entry.timeStamp = 10;
  entry.magData.val.x = 10; //can check that it's modifying this
  entry.magData.val.y = 10; 
  addTable(myTable,myTableEnd,staleAge,30,&entry);

  entry.sourceMoteID = 3;
  entry.timeStamp = 30;
  addTable(myTable,myTableEnd,staleAge,50,&entry);

  //TABLESIZE should be 3... should be full...
  printf("just inserted 3 entries...\n");
  printTable();

  //Testing overwrite same node eviction policy
  entry.sourceMoteID = 2;
  entry.timeStamp = 40;
  addTable(myTable,myTableEnd,staleAge,60,&entry);
  printf("entry for sourceMoteID 2 should change...\n");
  printTable();

  //Testing overwrite oldest policy
  entry.sourceMoteID = 4;
  entry.timeStamp = 50;
  addTable(myTable,myTableEnd,staleAge,70,&entry);
  printf("oldest entry should change...\n");
  printTable();

  printf("***finished testing addTable\n");
}


void Test_invalidFromStale() {
  uint32_t time = 140;
  NeighborTableEntry_t entry = {
    sourceMoteID: 10,
    valid: 1,
    timeStamp: UINT32_MAX - 50,
    magData: {
      val: {
	x: 1,
	y: 2
      },
      bias: {
	x: 10,
	y: 10
      }
    },
    loc: {
      pos: {
	x: 0,
	y: 0
      }
    }
  }; //entry


  printf("***testing invalidFromStale\n");
  printTable();
  printf("Now all entries between currenTime %d ",time);
  printf("and currentTime-staleAge %d should remain valid.", time-staleAge);
  invalidFromStale(myTable, myTableEnd, staleAge, time);
  printTable();


  initTable(myTable,myTableEnd);

  //test wrap-around counter
  addTable(myTable,myTableEnd,staleAge,UINT32_MAX - 30,&entry);

  entry.sourceMoteID = 11;
  entry.timeStamp = UINT32_MAX - 10;
  entry.magData.val.x = 5000;
  addTable(myTable,myTableEnd,staleAge,UINT32_MAX - 10,&entry);

  entry.sourceMoteID = 12;
  entry.timeStamp = 2;
  entry.magData.val.x = 5000;
  addTable(myTable,myTableEnd,staleAge,3,&entry);

  //TABLESIZE should be 3... should be full...
  printf("just erased and inserted 3 entries...\n");
  printTable();

  invalidFromStale(myTable,myTableEnd,staleAge,staleAge-20);
  printf("just ran invalidFromStale using currentTime %d\n", staleAge-20);
  printTable();
}



void Test_getMaxValidValue() {
  NeighborTableEntry_t entry = {
    sourceMoteID: 100,
    valid: 1,
    timeStamp: 10,
    magData: {
      val: {
	x: 10,
	y: UINT16_MAX
      },
      bias: {
	x: 10,
	y: 10
      }
    },
    loc: {
      pos: {
	x: 0,
	y: 0
      }
    }
  }; //entry

  uint32_t value1, value2;

  printf("***testing getMaxValidValue\n");
  initTable(myTable,myTableEnd);
  addTable(myTable,myTableEnd,staleAge,20,&entry);
  

  entry.sourceMoteID = 200;
  entry.timeStamp = 30;
  entry.magData.val.x = 20;
  entry.magData.val.y = 20;
  addTable(myTable,myTableEnd,staleAge,30,&entry);

  //hee hee, add an invalid entry for kicks
  entry.sourceMoteID = 300;
  entry.magData.val.x = UINT16_MAX;
  entry.magData.val.y = UINT16_MAX;
  entry.valid = 0;
  entry.timeStamp = 31;
  addTable(myTable,myTableEnd,staleAge,31,&entry);
  printTable();
  value1 = getMaxValidValue(myTable,myTableEnd,30,35);
  value2 = getMaxValidValue(myTable,myTableEnd,10,35);
  
  if ((value1 == UINT16_MAX+10) &&
      (value2 == 40)) {
    printf("getMaxValidValue is working\n");    
  } else {
    printf("ERROR: getMaxValidValue is not working\n");
  }
}




main() {
  printf("Testing neighbor_table.h\n");
  printf("********************\n");
/*   Test_checkInRange(); */
/*   printf("\n"); */
/*   Test_64Operations(); */
/*   printf("\n"); */
/*   Test_initTable(); */
/*   printf("\n"); */
  Test_addTable();
  printf("\n");
  Test_invalidFromStale();
  printf("\n");
  Test_getMaxValidValue();
  printf("\n"); //always have an extra return, so the command prompt
		//does not overwrite the result
}
