#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>


/**
 * Returns 1 if the headblockID for nodeId was found, 0 otherwise; 
 */
int getNodeInfo(char *fileName, uint16_t nodeID, uint32_t *startBlockID, uint32_t *nbrBlocks)
{
    char word[50];
    int atNodes = 0;
    int atNbrBlocks = 0;
    int returnVal = 0;
    FILE *filePtr;
 
    filePtr = fopen(fileName, "r");

    
    while (fscanf(filePtr, "%s", word) != EOF) 
    {
        if (atNbrBlocks == 1) {
            *nbrBlocks = strtoul(strtok(word, ","), NULL, 0);
            atNbrBlocks = 0;
        }
        else if (atNodes == 1) {
            int node;
            int startBlock;
            int endBlock;
            const char delimeters[] = "<,>";
            node  = strtoul(strtok(word, delimeters), NULL, 0);
            startBlock = strtoul(strtok(NULL, delimeters), NULL, 0);
            endBlock = strtoul(strtok(NULL, delimeters), NULL, 0);
            //printf("<nodeID= %u, startBlockID= %u, endBlockID= %u\n", node, startBlock, endBlock);
            if (node == nodeID) {
                *startBlockID = startBlock;
                *nbrBlocks = endBlock - startBlock;
                returnVal = 1;                
            }
        }
        else if (strcmp(word, "nbrBlocksToDownload=") == 0) {
            atNbrBlocks = 1;
        }
        else if (strcmp(word, "<nodeID,startBlockID,endBlockID>=") == 0) {
            atNodes = 1;            
        }
        
    }

    return returnVal;
}

/*
int main(int argc, char** argv)
{
    char *fileName = argv[1];
    uint16_t nodeID = strtoul(argv[2], NULL, 0);
    uint32_t headBlockID;
    uint32_t nbrBlocks;
    
    
    if (getNodeInfo(fileName, nodeID, &headBlockID, &nbrBlocks))        
        printf("--> nodeID= %u, headBlockID= %u, nbrBlocks= %u\n", nodeID, headBlockID, nbrBlocks);
    else
        printf("--> nodeID= %u, NOT FOUND\n", nodeID);
    
    
    return 0;
}
*/
