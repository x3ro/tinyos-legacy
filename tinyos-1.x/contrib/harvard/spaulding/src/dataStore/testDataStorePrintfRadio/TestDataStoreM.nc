#include "PrintfUART.h"
#include "PrintfRadio.h"
#include "Block.h"


module TestDataStoreM
{
    provides interface StdControl;

    uses interface Leds;
    uses interface Timer;
    uses interface DataStore;

    uses interface PrintfRadio;   
}
implementation
{
    // ---------- Data ----------
    enum {TIMER_INTERVAL = 2000L};
    uint16_t cntTimerFired = 0;

    Block blockBuff;
    blocksqnnbr_t lastBlockSqnNbrAdded = 0;


    // ----------------------- Methods ----------
    command result_t StdControl.init()
    {
        printfUART_init();
        return SUCCESS;
    }

    command result_t StdControl.start()
    {
        //return call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);
        return call DataStore.init();        
    }

    command result_t StdControl.stop() {return SUCCESS;}

    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS) {
            call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);    
        }
        else {
            printfUART("DataStore.initDone() - FAILED!\n");
        }
    }

    void addBlock(Block *blockPtr, uint16_t startValue)
    {
        uint16_t i = 0;
        Block_init(blockPtr);
        for (i = 0; i < BLOCK_DATA_SIZE; ++i) {
            if (i == 2)  blockPtr->data[i] = 0xcc;
            else         blockPtr->data[i] = startValue +i;
        }

        printfRadio("add() id= %lu [%u %u %u %u]", blockPtr->sqnNbr, blockPtr->data[0], blockPtr->data[1], blockPtr->data[2], blockPtr->data[3]);
        Block_print(blockPtr);
        if (call DataStore.add(blockPtr) == SUCCESS) {}
        else {printfUART("addBlock() - FAILED! to schedule add(), blockPtr= %p\n", blockPtr);}
    }

    void getBlock(Block *blockPtr)
    {
        printfUART("getBlock() - called\n");
        Block_init(blockPtr);
        if (call DataStore.get(blockPtr, lastBlockSqnNbrAdded) == SUCCESS) {}
        else {printfUART("getBlock() - FAILED! to schedule get blockPtr= %p, blockSqnNbr= %lu\n", blockPtr, lastBlockSqnNbrAdded);}
    }

    event result_t Timer.fired()
    {
        ++cntTimerFired;
        call Leds.yellowToggle();
        printfUART("Timer.fired() - cntTimerFired= %u\n", cntTimerFired);
        printfRadio("Timer.fired() %u", cntTimerFired);

        if (cntTimerFired % 3 == 0)
            getBlock(&blockBuff);
        else if (cntTimerFired % 3 == 1)
            addBlock(&blockBuff, cntTimerFired);

        return SUCCESS;
    }
                                              
    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS) {
            atomic lastBlockSqnNbrAdded = blockSqnNbr;            
        }
        else {
            call Leds.redToggle();
            printfUART("DataStore.addDone() - WARNING failed to add blockPtr= %p\n", blockPtr);
        }
        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS) {}
        else {
            printfUART("DataStore.getDone() - FAILED! to ger blockPtr= %p, blockSqnNbr= %lu\n", blockPtr, blockSqnNbr);            
            call Leds.redToggle();
        }
        Block_print(blockPtr);
        printfRadio("get() id= %lu [%u %u %u %u]", blockPtr->sqnNbr, blockPtr->data[0], blockPtr->data[1], blockPtr->data[2], blockPtr->data[3]);

        return result;
    }

}
