/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * Blackbook NodeMap Module
 * Allows access to general file system information through NodeMap interface
 * File system modifications through NodeBooter interface
 * File allocation and services through NodeLoader interface
 * @author David Moss (dmm@rincon.com)
 */
 
includes Blackbook;

module NodeMapM {
  provides {
    interface NodeMap;
    interface NodeBooter;
    interface StdControl;
  }
  
  uses {
    interface SectorMap;
    interface Util;
  }
}

implementation {

  /** The array of files in memory */
  file files[MAX_FILES];
  
  /** The array of nodes in memory */
  flashnode nodes[MAX_FILES*NODES_PER_FILE];
  
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i; 

    for(i = 0; i < call NodeMap.getMaxNodes(); i++) {
      nodes[i].filenameCrc = 0;
      nodes[i].nextNode = NULL;
      nodes[i].state = NODE_EMPTY;
    }
    
    for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
      files[i].filenameCrc = 0;
      files[i].firstNode = NULL;
      files[i].state = FILE_EMPTY;
    }
    
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** NodeBooter Commands *****************/
  /**
   * Request to add a flashnode to the file system.
   * It is the responsibility of the calling function
   * to properly setup:
   *   > flashAddress
   *   > dataLength
   *   > reserveLength
   *   > dataCrc
   *   > filenameCrc
   *   > fileElement
   * 
   * Unless manually linked, state and nextNode are handled by NodeMap.
   * @return a pointer to an empty flashnode if one is available
   *     NULL if no more exist
   */
  command flashnode *NodeBooter.requestAddNode() {
    int i;

    for(i = 0; i < call NodeMap.getMaxNodes(); i++) {
      if(nodes[i].state == NODE_EMPTY) {
        nodes[i].nextNode = NULL;
        return &nodes[i];
      }
    }
    return NULL;
  }
  
  /**
   * Request to add a file to the file system
   * It is the responsibility of the calling function
   * to properly setup:
   *   > filename
   *   > filenameCrc
   *   > type
   *
   * Unless manually linked, state and nextNode are handled in NodeMap.
   * @return a pointer to an empty file if one is available
   *     NULL if no more exist
   */
  command file *NodeBooter.requestAddFile() {
    int i;
    for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
      if(files[i].state == FILE_EMPTY) {
        files[i].firstNode = NULL;
        return &files[i];
      }
    }
    return NULL;
  }
  
  /**
   * After booting, the nodes loaded from flash must
   * be corrected linked. 
   * The node.fileelement will represent the fileElement from the nodemeta
   * before the file is finished being linked.
   *
   */
  command result_t NodeBooter.link() {
    int fileIndex;
    int nodeIndex;
    flashnode *lastLinkedNode;
    uint8_t currentElement;
    
    // Link all files and nodes
    for(fileIndex = 0; fileIndex < call NodeMap.getMaxFiles(); fileIndex++) {
      if(files[fileIndex].state != FILE_EMPTY && files[fileIndex].state != FILE_WRITING) {
        files[fileIndex].state = FILE_IDLE;
        lastLinkedNode = NULL;
        currentElement = 0;
        
        // locate all nodes associated with the file in the correct order
        for(nodeIndex = 0; nodeIndex < call NodeMap.getMaxNodes(); nodeIndex++) {
          // Check out the next node
          if(nodes[nodeIndex].state != NODE_EMPTY) {
            // This flashnode needs to be linked
            if(nodes[nodeIndex].filenameCrc == files[fileIndex].filenameCrc) {
              // and it belongs to the current file we're linking
              if(nodes[nodeIndex].fileElement == currentElement) {
                // in fact it's the next flashnode we're looking for
                if(currentElement == 0) {
                  // This is the first flashnode of the file
                  files[fileIndex].firstNode = &nodes[nodeIndex];
                } else {
                  // This is the next flashnode of the file
                  lastLinkedNode->nextNode = &nodes[nodeIndex];
                }
                
                nodes[nodeIndex].fileElement = 0xFF;
                nodes[nodeIndex].nextNode = NULL;
                lastLinkedNode = &nodes[nodeIndex];
                currentElement++;
                nodeIndex = -1;  // -1 because the for loop immediately adds 1
              }
            }
          }
        }
      }
    }
    
    // Remove all the dangling nodes - although this should never happen,
    // we take some precautions.  One issue is this will not erase
    // the node's checkpoint, so the checkpoint for this flashnode will 
    // be around forever, until another flashnode is written to its location
    // I'd rather have a lingering 18 byte checkpoint hanging around
    // than a sector-long undeletable node
    for(nodeIndex = 0; nodeIndex < call NodeMap.getMaxNodes(); nodeIndex++) {
      if(nodes[nodeIndex].state != NODE_EMPTY && nodes[nodeIndex].state != NODE_VALID) {
        if(nodes[nodeIndex].fileElement != 0xFF) {
          nodes[nodeIndex].state = NODE_DELETED;
          call SectorMap.removeNode(&nodes[nodeIndex]);
          nodes[nodeIndex].state = NODE_EMPTY;
        }
      }
    }
    
    return SUCCESS;
  }
  
  /***************** NodeMap Commands ****************/
  /**
   * @return the maximum number of nodes allowed
   */
  command uint16_t NodeMap.getMaxNodes() {
    return MAX_FILES * NODES_PER_FILE;
  }
  
  /** 
   * @return the maximum number of files allowed
   */
  command uint8_t NodeMap.getMaxFiles() {
    return MAX_FILES;
  }
  
  /** 
   * @return the total nodes used by the file system
   */
  command uint16_t NodeMap.getTotalNodes() {
    int i;
    uint16_t totalNodes = 0;
    for(i = 0; i < call NodeMap.getMaxNodes(); i++) {
      if(nodes[i].state != NODE_EMPTY) {
        totalNodes++;
      }
    }
    return totalNodes;
  }
    
  
  /**
   * Get the flashnode and offset into the flashnode that represents
   * an address in a file
   * @param focusedFile - the file to find the address in
   * @param fileAddress - the address to find
   * @param returnOffset - pointer to a location to store the offset into the node
   * @return the flashnode that contains the file address in the file.
   */
  command flashnode *NodeMap.getAddressInFile(file *focusedFile, uint32_t fileAddress, uint16_t *returnOffset) {
    flashnode *focusedNode;
    uint16_t nodeLength;
    uint32_t currentAddress = 0;
    
    for(focusedNode = focusedFile->firstNode; focusedNode != NULL; focusedNode = focusedNode->nextNode) {
      if(focusedNode->state == NODE_LOCKED) {
        nodeLength = focusedNode->dataLength;
      } else {
        nodeLength = focusedNode->reserveLength;
      }
      
      if(fileAddress - currentAddress < nodeLength) {
        // The address is in this node
        *returnOffset = fileAddress - currentAddress;
        return focusedNode;
        
      } else {
        currentAddress += nodeLength;
      }
    }
    
    return NULL;     
  }
  
  
  /**
   * @return the total nodes allocated to the given file
   */
  command uint8_t NodeMap.getTotalNodesInFile(file *focusedFile) {
    flashnode *currentNode;
    uint8_t totalNodes = 0;
   
    if((focusedFile != NULL) && focusedFile->state != FILE_EMPTY) {
      currentNode = focusedFile->firstNode;
      while(currentNode != NULL) {
        totalNodes++;
        currentNode = currentNode->nextNode;
      }
    }
    return totalNodes;
  }
  
  /**
   * @return the total files used by the file system
   */
  command uint8_t NodeMap.getTotalFiles() {
    int i;
    uint8_t totalFiles = 0;
    for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
      if(files[i].state != FILE_EMPTY) {
        totalFiles++;
      }
    }
    return totalFiles;
  }
  
  /**
   * @return the node's position in a file, 0xFF if not valid
   *
  command uint8_t NodeMap.getElementNumber(flashnode *focusedNode) {
    file *parentFile;
    
    if((parentFile = call NodeMap.getFileFromNode(focusedNode)) == NULL) {
      return 0xFF;
    }
    
    return call NodeMap.getElementNumberFromFile(focusedNode, parentFile);
  }
    
    
  /**
   * If you already know the file, this is faster than getElementNumber(..)
   * @return the node's position in the given file, 0xFF if not valid
   *
  command uint8_t NodeMap.getElementNumberFromFile(flashnode *focusedNode, file *focusedFile) {
    flashnode *currentNode;
    uint8_t elementNumber = 0;
    
    if(focusedNode == NULL || focusedFile == NULL 
        || focusedNode->state == NODE_EMPTY || focusedFile->state == FILE_EMPTY) {
      return 0xFF;
    }
    
    currentNode = focusedFile->firstNode;
   
    // 0 indexed
    while(currentNode != focusedNode && (currentNode = currentNode->nextNode) != NULL) {
      elementNumber++;
    }
    
    return elementNumber;
  }
  
  
  /**
   * @return the file with the given name if it exists, NULL if it doesn't
   */
  command file *NodeMap.getFile(filename *focusedFilename) {
    int i;
    uint16_t focusedFileCrc = call Util.filenameCrc(focusedFilename);
    for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
      if(focusedFileCrc == files[i].filenameCrc && files[i].state != FILE_EMPTY) {
        return &files[i];
      }
    }
    return NULL;
  }
  
  /**
   * @return the file associated with the given node, NULL if n/a.
   */
  command file *NodeMap.getFileFromNode(flashnode *focusedNode) {
    int i;
    if(focusedNode == NULL || focusedNode->state == NODE_EMPTY) {
      return NULL;
    }
    
    for(i = 0; i < call NodeMap.getMaxFiles(); i++) {
      if(focusedNode->filenameCrc == files[i].filenameCrc 
          && files[i].state != FILE_EMPTY) {
        return &files[i];
      }
    }
    return NULL;
  }
  
   
  /**
   * Traverse the files on the file system from
   * 0 up to (max files - 1).
   * If performing a DIR, be sure to hide
   * Checkpoint files on the way out.
   * @return the file at the given index
   */
  command file *NodeMap.getFileAtIndex(uint8_t fileIndex) {
    if(fileIndex < call NodeMap.getMaxFiles()) {
      return &files[fileIndex];
    }
    return NULL;
  }
  
  /**
   * Get a flashnode at a given index
   * @return the flashnode if it exists, NULL if it doesn't.
   */
  command flashnode *NodeMap.getNodeAtIndex(uint8_t nodeIndex) {
    if(nodeIndex < call NodeMap.getMaxNodes()) {
      return &nodes[nodeIndex];
    }
    return NULL;
  }
  
  /** 
   * Get the total length of data of a given file
   * @return the length of the file's data
   */
  command uint32_t NodeMap.getDataLength(file *focusedFile) {
    flashnode *focusedNode;
    uint32_t dataLength = 0;
    
    for(focusedNode = focusedFile->firstNode; focusedFile != FILE_EMPTY && focusedNode != NULL; focusedNode = focusedNode->nextNode) {
      dataLength += focusedNode->dataLength;
    }
    
    return dataLength;
  }
  
  /**
   * @return the reserve length of all nodes in the file
   */
  command uint32_t NodeMap.getReserveLength(file *focusedFile) {
    flashnode *focusedNode;
    uint32_t reserveLength = 0;
    
    for(focusedNode = focusedFile->firstNode; focusedFile != FILE_EMPTY && focusedNode != NULL; focusedNode = focusedNode->nextNode) {
      reserveLength += focusedNode->reserveLength;
    }
    
    return reserveLength;
  }
  
  /**
   * @return TRUE if there exists another node
   *     that belongs to the same file with the same element
   *     number.
   */
  command bool NodeMap.hasDuplicate(flashnode *focusedNode) {
    int i;
    uint8_t numNodes = 0;
    
    for(i = 0; i < call NodeMap.getMaxNodes(); i++) {
      if(nodes[i].state != NODE_EMPTY) {
        if(nodes[i].filenameCrc == focusedNode->filenameCrc) {
          if(nodes[i].fileElement == focusedNode->fileElement) {
            numNodes++;
          }
        }
      }
    }
    
    return (numNodes > 1);
  }
}

