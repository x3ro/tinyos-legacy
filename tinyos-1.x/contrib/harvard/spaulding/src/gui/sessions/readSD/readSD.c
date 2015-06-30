/**
 * Konrad Lorincz
 * November 15, 2007
 */
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include "MultiChanSampling.h"
#include "nodeInfo.c"
#include <dirent.h>

#define FLASH_BLOCK_SIZE 512ul
#define DATASTORE_BLOCK_SIZE 256ul
#define BLOCK_DATA_SIZE (DATASTORE_BLOCK_SIZE-sizeof(uint32_t))

#define GLOBALTIME_RATE_HZ 32768


typedef struct FlashInfo
{
    uint32_t hash;
    uint16_t nodeID;
    uint32_t tail;
    uint32_t head;
} FlashInfo;




typedef struct Block {
    uint32_t sqnNbr;
    uint8_t data[BLOCK_DATA_SIZE];
} Block;


#define SAMPLE_CHUNK_NUM_SAMPLES ((BLOCK_DATA_SIZE - 2*sizeof(uint32_t) - 3*sizeof(uint16_t) - sizeof(channelID_t)*MCS_MAX_NBR_CHANNELS_SAMPLED) / sizeof(sample_t))


typedef struct SampleChunk {
    uint32_t    localTime;
    uint32_t    globalTime;
    uint16_t    samplingRate;
    uint16_t    timeSynched;         // true or false 
    uint16_t    nbrMultiChanSamples; // Number of samples

    channelID_t channelIDs[MCS_MAX_NBR_CHANNELS_SAMPLED];            
    sample_t    samples[SAMPLE_CHUNK_NUM_SAMPLES];
} SampleChunk;         



void getFlashInfo(FlashInfo *flashInfoPtr, FILE *filePtr)
{
    fseek(filePtr, 0, SEEK_SET);
    fread(flashInfoPtr, sizeof(FlashInfo), 1, filePtr);
}

void getBlock(Block *blockPtr, uint32_t blockID, FILE *filePtr)
{
    uint32_t blocksStartOffset = FLASH_BLOCK_SIZE;
    uint32_t offset = blocksStartOffset + (blockID-1)*FLASH_BLOCK_SIZE;

    fseek(filePtr, offset, SEEK_SET);
    fread(blockPtr, sizeof(Block), 1, filePtr);
}

uint16_t getNodeID(char *devicePath)
{
    FlashInfo flashInfo;
    FILE *sdFilePtr = fopen(devicePath, "rb");
    getFlashInfo(&flashInfo, sdFilePtr);
    fclose(sdFilePtr);
    return flashInfo.nodeID;
}


void printFlashInfo(char *devicePath)
{
    FlashInfo flashInfo;
    FILE *sdFilePtr = fopen(devicePath, "rb");
    getFlashInfo(&flashInfo, sdFilePtr);
    
    printf("hash= %u, nodeID= %u, tail= %u, head= %u\n", flashInfo.hash, flashInfo.nodeID, flashInfo.tail, flashInfo.head);
    fclose(sdFilePtr);
}

void printBlock(FILE *filePtr, Block *blockPtr)
{
    uint16_t i = 0;
    uint16_t samp = 0;
    SampleChunk *scPtr = (SampleChunk*) blockPtr->data;
    int nbrChansSampled = 0;
    fprintf(filePtr, "# blockID= %u:  localTime= %u, globalTime= %u, samplingRate= %u, timeSynched= %u, nbrMultiChanSamples= %u, channelIDs= {",
            blockPtr->sqnNbr, scPtr->localTime, scPtr->globalTime, scPtr->samplingRate, scPtr->timeSynched, scPtr->nbrMultiChanSamples);

    for (i = 0; i < MCS_MAX_NBR_CHANNELS_SAMPLED; ++i) {
        if (i < MCS_MAX_NBR_CHANNELS_SAMPLED - 1)
            fprintf(filePtr, "%u ", scPtr->channelIDs[i]);
        else
            fprintf(filePtr, "%u}", scPtr->channelIDs[i]);

        if (scPtr->channelIDs[i] != CHAN_INVALID)
            nbrChansSampled++;
    }    
    

    
    for (samp = 0; samp < scPtr->nbrMultiChanSamples &&
                   samp < SAMPLE_CHUNK_NUM_SAMPLES; ++samp) {
        if (samp % nbrChansSampled == 0) {
            double globalTimeSec = scPtr->globalTime / (double)GLOBALTIME_RATE_HZ;
            double sampleTimeSec = globalTimeSec + (double)(samp/nbrChansSampled)/
                                                   (double)scPtr->samplingRate;
            fprintf(filePtr, "\n%.6f ", sampleTimeSec);
        }
        fprintf(filePtr, "%u ", scPtr->samples[samp]);
    }
    fprintf(filePtr, "\n");
    

    #if 0
    {    // Hex Dump
        uint32_t i = 0;
        uint8_t hexVal = 0x0;
        for (i = 0; i < sizeof(blockPtr->data); ++i) {
            hexVal = (uint8_t) *(((uint8_t*)&blockPtr->data) + i);
            if (hexVal <= 0x0f)
                {fprintf(filePtr, "0%x ", hexVal);} 
            else
                {fprintf(filePtr, "%x ", hexVal);}
            
            if ( (i+1) == sizeof(blockPtr->data) ||
                 (i+1) % 16 == 0 ) 
                {fprintf(filePtr, "\n");}
            else if ((i+1) % 4 == 0)
                {fprintf(filePtr, "   ");}        
        }
    }
    #endif
}


int downloadSession(char *sessionDir, char *sessionInfoFile, char *devicePath)
{
    uint16_t nodeID = getNodeID(devicePath);
    uint32_t startBlockID;
    uint32_t nbrBlocks;
    char infoFilePath[128];
    sprintf(infoFilePath, "%s/%s", sessionDir, sessionInfoFile);

    printf("=> nodeID= %d: %s\n", nodeID, infoFilePath);

    // (1) Print the FlashInfo
    printFlashInfo(devicePath);
    //return 0;


    if (getNodeInfo(infoFilePath, nodeID, &startBlockID, &nbrBlocks)) {
        //printf("   found sessionInfo for nodeID= %u, startBlockID= %u, nbrBlocks= %u\n", nodeID, startBlockID, nbrBlocks);

        // (1) - Open the SD card
        Block block;
        uint32_t i = 0;
        FILE *sdFilePtr = fopen(devicePath, "rb");
        FILE *outFilePtr;
        char outFile[128];
        sprintf(outFile, "%s/node-%u.samplesSD", sessionDir, nodeID);
        outFilePtr = fopen(outFile, "w");


        for (i = startBlockID; i < (startBlockID + nbrBlocks); ++i) {
            getBlock(&block, i, sdFilePtr);
            printBlock(outFilePtr, &block);
        }
    
        fclose(outFilePtr);
        fclose(sdFilePtr);
    }
    else
        printf("  nodeID= %u, NOT FOUND\n", nodeID);

        
    return 0;
}


// sudo dd if=/dev/sdd of=out.raw count=1

char* SD_DEVICE_PATH = "/dev/sda"; // Spaulding device
//char* SD_DEVICE_PATH = "/dev/sdb";//"/dev/sdd";   // Konrad's device


int main(int argc, char** argv)
{
    // (1) - Print Header only
    if (argc == 2 && (strcmp(argv[1],"-h")==0)) {
        printFlashInfo(SD_DEVICE_PATH);
        return 0;
    }


    // (2) - Download sessions
    struct dirent **namelist;
    int nbrFiles = scandir(".", &namelist, 0, alphasort);
    int i = 0;
    
    for (i = 0; i < nbrFiles; ++i) {
        char* fileName = namelist[i]->d_name;
        free(namelist[i]);
        
        // Check current direcotry
        if (strcmp(fileName, "sessionInfo.txt") == 0) {
            downloadSession(".", "sessionInfo.txt", SD_DEVICE_PATH);
        }
        // check subdirectory
        else if (strncmp(fileName, "subj-", 5) == 0) {
            downloadSession(fileName, "sessionInfo.txt", SD_DEVICE_PATH);
        }
    }
    free(namelist);

    
    return 0;
}
