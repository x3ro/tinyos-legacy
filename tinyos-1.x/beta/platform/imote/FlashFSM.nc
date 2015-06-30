/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * This file system is loosely modeled after the unix file system with the
 * following paramters:
 *   Block size = 128B (page size == block size)
 *   i-node structure = 40B
 *   File i-nodes are limited to block 0
 *   Used page bitmask occupies block 1 => 128KB max
 *   i-node contains 4 direct block indexes
 *   i-node contains 8 1st level index blocks so max theoretical size =
 *       (4 + 8 * 64) * 128B ~= 66 KB
 *
 * No attempt is made to load balance the writes.
 */

module FlashFSM {

  provides {
    interface StdControl as Control;
    interface FlashFS;
  }

  uses {
    interface Flash;
  }    
}

implementation
{
  #define MAX_FD    3         // can't be larger than MAX_INODE
  #define MAX_BLOCKS 1024     // arbitrary
  #define INDEXES_PER_BLOCK (BLOCK_SIZE >> 1) // assume 2B per index

  // macros to generate the index of a block within the first and second level
  // tables
  #define FINDEX(block) (((block) - ZERO_LEVEL_BLOCKS) & (INDEXES_PER_BLOCK -1))
  #define SINDEX(block) (((block) - ZERO_LEVEL_BLOCKS) >> IndexBits)

  typedef struct fileDescriptor {
    uint32     inode;          // index into FInode structure
    uint32     fileOffset;     // current pointer offset into the file
    bool       valid;          // whether this fd is currently valid
    int        Mode;           // Current file access mode R, W, RW
    int        currentBlock;   // index of physical block of current pointer
                               // -1 if no blocks are open for writting
    char       *mptr;          // pointer to page currently open for writting
    int        fBlock;         // block id of the first level block open for
                               // writing; -1 if no blocks are open
    int16_t    *fptr;          // pointer to currently open first level index
                               // page
  } fileDescriptor;

  fileDescriptor fDesc[MAX_FD];// statically allocate space for the maximum
                               // number of files
  uint32  FlashBase;           // starting block id for lower level flash
                               // filesystem
  FInode  *inode;              // array pointer to the 0-page inode table
                               // When inode == NULL, there are no open files
  char    *usedPages;          // array pointer to the 1-page bit mask of 
                               // used blocks
  int     lastEmptyPage;       // index into usedPages array indicating where
                               // the last empty page came from.  This is just
                               // an optimization to accellerate finding the
                               // next empty page.
  int     BlockBits;           // optimization for manipulating offsets
  int     IndexBits;           // optimization for manipulating offsets

/*
 * Start of StdControl interface.
 */

  command result_t Control.init() {
    int i;

    inode = NULL;
    usedPages = NULL;
    lastEmptyPage = 0;

    for (i = 0; i < MAX_FD; i++) {
      fDesc[i].valid = FALSE;
      fDesc[i].currentBlock = -1;
      fDesc[i].mptr = NULL;
      fDesc[i].fBlock = -1;
      fDesc[i].fptr = NULL;
    }

    BlockBits = -1; for (i = BLOCK_SIZE; i != 0; i>>=1) BlockBits++;
    IndexBits = -1; for (i = INDEXES_PER_BLOCK; i != 0; i>>=1) IndexBits++;

    return SUCCESS;
  }



  command result_t Control.start() {
    // load the 0-page from flash by casting the inode array on top of it
    // this page stays open until the filesystem is stopped
    inode = (FInode *) call Flash.getWriteBlock(0);
    usedPages = (char *) call Flash.getWriteBlock(1);

    // mark first two pages as used for inode and used pages mask
    usedPages[0] = usedPages[0] | 0xC0;

    return SUCCESS;
  }



  command result_t Control.stop() {
    if (inode != NULL) {
      call Flash.commitBlock(0);
    }
    if (usedPages != NULL) {
      call Flash.commitBlock(1);
    }
  }

/*
 * End of StdControl interface.
 */



  /*
   * Look through the usedPages bitmask to find an unused page.  If one is found
   * mark it as used and return the physical block index.  If no empty pages are
   * found, return -1.
   */

  int AllocateEmptyBlock() {
    int i, j;

    for (i = 0; i < BLOCK_SIZE; i++) {
      if (usedPages[lastEmptyPage] != 0xff) {

        // find first empty bit corresponding to first unused block
        for (j = 0; j < 8; j++) {
          if ((usedPages[lastEmptyPage] & (0x80 >> j)) == 0) {

            // mark block as used and return index
            usedPages[lastEmptyPage] |= (0x80 >> j);
            return ((lastEmptyPage << 3) | j);
          }
        }
        // shouldn't get here
      }
      lastEmptyPage = (lastEmptyPage < (MAX_BLOCKS - 1)) ? lastEmptyPage+1 : 0;
    }

    // if flow gets to this point, there are no pages left
    return -1;
  }
  



  /*
   * Figure out which physical block contains the byte at <offset> in the
   * given inode.
   */

  int GetBlockIndex(int fd, int offset) {
    int     inumber;
    int     block;  // virtual block offset within this inode
    int     sindex;// virtual block offset within 1st level
    int     ind;    // physical block index of 1st level table
    int16_t *table; // pointer used to access blocks which contain block indexes

    inumber = fDesc[fd].inode;
    block = offset >> BlockBits;

    if (block < ZERO_LEVEL_BLOCKS) { 

      // block index is in the inode structure
      return (inode[inumber].dataBlock[block]);

    } else {

      // block index is accessed through first level index
      sindex = SINDEX(block);

      // if the requested block shares the same first level table as the current
      // block and that table is in core, use the cached version
      if ((inode[inumber].firstLevel[sindex] == fDesc[fd].fBlock) &&
          (fDesc[fd].fptr != NULL)) {
        table = fDesc[fd].fptr;
      } else {
        ind = inode[inumber].firstLevel[sindex];
        table = (int16_t *) call Flash.getReadBlock(ind);
      }
      return table[FINDEX(block)];

    }

    // shouldn't get here
    return -1;
  }



  /*
   * Allocate blocks and update the inode structure to a file size of offset.
   * Update file size.
   */

  result_t AppendBlocksToOffset (int fd, int offset) {
    int      curBlocks;  // current number of blocks in the file
    int      newBlocks;  // new number of blocks needed
    int      block;      // physical index of new block
    int      foffset;    // virtual block offset within 1st level array
    int      fInd;       // virtual block index in first level table
    int16_t  *fptr;      // pointer to first level index table
    int      inumber;
    int      tmp;
    char     *buf;

    inumber = fDesc[fd].inode;
    curBlocks = inode[inumber].fileSize >> BlockBits;
    newBlocks = offset >> BlockBits;

    fptr = fDesc[fd].fptr;
    while (curBlocks < newBlocks) {
      if ((block = AllocateEmptyBlock()) == -1) return FAIL; // should clean up?

      curBlocks++;
      if (curBlocks < ZERO_LEVEL_BLOCKS) {
        inode[inumber].dataBlock[curBlocks] = block;
      } else {
        foffset = (curBlocks - ZERO_LEVEL_BLOCKS) >> IndexBits;
        fInd = (curBlocks - ZERO_LEVEL_BLOCKS) & (INDEXES_PER_BLOCK - 1);
        if (fInd == 0) {
          // allocate 1st level page
          if ((inode[inumber].firstLevel[foffset]=AllocateEmptyBlock()) == -1) {
            return FAIL; // should clean up?
          }
          if (fptr != NULL) { // close previous page
            call Flash.commitBlock(inode[inumber].firstLevel[foffset - 1]);
            fptr = NULL;
          }
        }
        if (fptr == NULL) { // allocate page for writting
          tmp = inode[inumber].firstLevel[foffset];
          buf = call Flash.getWriteBlock(tmp);
          fptr = (int16_t *) buf;
          fDesc[fd].fptr = fptr;
          fDesc[fd].fBlock = tmp;
          if (fptr == NULL) {
            return FAIL;
          }
        }
        fptr[fInd] = block;
      }
      inode[inumber].fileSize = curBlocks << BlockBits;
    }

    // leave page open and cache pointer
/*    // close open pages
    if (fptr != NULL) {
      call Flash.commitBlock(inode[inumber].firstLevel[foffset]);
    }
*/

    if (inode[inumber].fileSize > offset) { // don't shrink the file
      inode[inumber].fileSize = offset;
    }

    return SUCCESS;
  }



  /*
   * Allocate an entry in the inode table and initialize the contents.
   * Return -1 if the entry could not be created.
   */

  int CreateInode(char *name) {
    int i, j, block;

    // find an empty inode and set the valid flag
    for (i = 0; i < MAX_INODE; i++) {
      if (inode[i].flags != FINODE_VALID) {
        // make sure there is at least one empty block before setting up inode
        if ((block = AllocateEmptyBlock()) == -1) {
          return -1;
        }

        strncpy (&(inode[i].name[0]), name, MAX_NAME_LENGTH);
        if (strlen(name) >= MAX_NAME_LENGTH) inode[i].name[MAX_NAME_LENGTH-1]=0;
        inode[i].flags = FINODE_VALID;
        inode[i].fileSize = 0;
        inode[i].dataBlock[0] = block;
        for (j = 1; j < ZERO_LEVEL_BLOCKS; j++) inode[i].dataBlock[j] = 0;
        for (j = 0; j < FIRST_LEVEL_BLOCKS; j++) inode[i].firstLevel[j] = 0;
        return i;
      }
    }
    return -1;
  }



  /*
   * Match string name to the file descriptor
   */
  int GetInode(char *name) {
    int i;

    for (i = 0; i < MAX_INODE; i++) {
      if (inode[i].flags == FINODE_VALID) {
        if (strcmp(name, inode[i].name) == 0) return i;
      }
    }

    return -1;   // not found
  }



  /*
   * Match string name to the file descriptor
   */
  int GetFileDescriptor(int inumber) {
    int i;

    for (i = 0; i < MAX_FD; i++) {
      if ((fDesc[i].valid == TRUE) && (fDesc[i].inode == inumber)) {
        return i;
      }
    }

    return -1;   // not found
  }



  /*
   * Return the lowest file descriptor which is not currently valid.  If all
   * of the file descriptors are taken, return -1.
   */
  int AllocateNewFileDescriptor(int inumber) {
    int i;

    for (i = 0; i < MAX_FD; i++) {
      if (fDesc[i].valid == FALSE) {
        fDesc[i].valid = TRUE;
        fDesc[i].currentBlock = -1;
        fDesc[i].mptr = NULL;
        fDesc[i].fBlock = -1;
        fDesc[i].fptr = NULL;
        return i;
      }
    }

    return -1;
  }



  int GetLowestFileDescriptor() {
    int i;

    for (i = 0; i < MAX_FD; i++) {
      if (fDesc[i].valid == FALSE) return i;
    }

    return -1;
  }



  /*
   * Start of FlashFS interface.
   */


  bool ValidFD(int fd) {
    return ((fd >= 0) && (fd < MAX_FD) && (fDesc[fd].valid == TRUE));
  }


  /*
   * Opens a file for reading or writing.  If the file does not exist and the
   * FFS_CREAT flag is set then a new file is created.  The return value is
   * a file descriptor used by the other file io functions or a -1 if there
   * was an error.
   */

  command int FlashFS.open(char *name, int flags) {
    int inumber; // inode index associated with name
    int fd;      // file descriptor associated with name

    // make sure the inode page is in core
    if (inode == NULL) {
      inode = (FInode *) call Flash.getWriteBlock(0);
      usedPages = (char *) call Flash.getWriteBlock(1);
    }

    inumber = GetInode(name);
    if ((inumber == -1) && (flags & FFS_O_CREAT)) {
      inumber = CreateInode(name);
    }
    if (inumber == -1) {
      return -1;  // file doesn't exist and we didn't create it
    }

    // If file is already open make sure that that access modes match.
    // The file must be closed and reopened to change the access mode.
    fd = GetFileDescriptor(inumber);
    if ((fd != -1) && (fDesc[fd].Mode != (flags & 0x3))) {
      return -1;
    }

    if (fd == -1) { // try to open the file
      if ((fd = AllocateNewFileDescriptor(inumber)) == -1) return -1;
      fDesc[fd].Mode = flags & 0x03;
      if ((flags & FFS_O_APPEND) && (flags & (FFS_O_WRONLY | FFS_O_RDWR))) {
        fDesc[fd].fileOffset = inode[inumber].fileSize;
      } else {
        fDesc[fd].fileOffset = 0;
      }
      fDesc[fd].inode = inumber;
    }

    // if the current access mode is write enabled, load the current page
    if (flags & (FFS_O_WRONLY | FFS_O_RDWR)) {
      fDesc[fd].currentBlock =
        GetBlockIndex(fd, fDesc[fd].fileOffset);
      fDesc[fd].mptr = call Flash.getWriteBlock(fDesc[fd].currentBlock);
      if ((fDesc[fd].fileOffset >> BlockBits) >= ZERO_LEVEL_BLOCKS) {
        fDesc[fd].fBlock = inode[inumber].firstLevel[SINDEX(fDesc[fd].fileOffset >> BlockBits)];
        fDesc[fd].fptr = call Flash.getWriteBlock(fDesc[fd].fBlock);
      }
    }

    return (fd);
  }



  /*
   * Moves the read/ write pointer within a file.  The whence flag indicates
   * whether the new location is relative to the beginning, current location,
   * or end of the file.
   */
  command void FlashFS.lseek(int fd, int offset, int whence) {
    int curOffset, newOffset, curSize;
    int oldFL, newFL;

    // verify that file descriptor is valid 
    if (ValidFD(fd) == FALSE) return;

    curOffset = fDesc[fd].fileOffset;
    curSize = inode[fDesc[fd].inode].fileSize;
    if (whence == FFS_SEEK_SET) {
      newOffset = offset;
    } else if (whence == FFS_SEEK_CUR) {
      newOffset = curOffset + offset;
    } else if (whence == FFS_SEEK_END) {
      newOffset = curSize + offset;
    }

    // if we've scanned past the last block of the file, allocate more blocks
    if (newOffset > curSize) {
      if (AppendBlocksToOffset (fd, newOffset) == FAIL) {
        return;
      };
    }

    // if the file is write enable and the seek enters a new block, close the
    // old one and open the new one for writting
    if ((fDesc[fd].currentBlock != -1) &&
        (fDesc[fd].Mode & (FFS_O_WRONLY | FFS_O_RDWR))) {
      if ((curOffset >> BlockBits) != (newOffset >> BlockBits)) {
        call Flash.commitBlock(fDesc[fd].currentBlock);
        fDesc[fd].currentBlock = GetBlockIndex(fd, newOffset);
        fDesc[fd].mptr = call Flash.getWriteBlock(fDesc[fd].currentBlock);

        // If the seek enters a block indexed by a different first level entry
        // then close the old entry and open the new one
        oldFL = ((fDesc[fd].fileOffset >> BlockBits) - ZERO_LEVEL_BLOCKS)
                >> IndexBits;
        newFL = ((newOffset >> BlockBits) - ZERO_LEVEL_BLOCKS) >> IndexBits;
        if (oldFL != newFL) {
          call Flash.commitBlock(oldFL);
          fDesc[fd].fptr = (int16_t *) call Flash.getWriteBlock(newFL);
        }
      }
    }

    fDesc[fd].fileOffset = newOffset;
    return;
  }



  /*
   * Copy the contents of the file to the buffer and advance the index pointer
   * by size.  The return value is the nuber of bytes read.
   */
  command int FlashFS.read (int fd, char *inbuf, int size) {
    int    i;
    int    block;         // physical block index of the current block
    int    offset;
    int    fileSize;
    char   *fbuf;
    int    oldFL, newFL;

    // verify that file descriptor is valid 
    if (ValidFD(fd) == FALSE) return 0;

    // verify access mode
    if ((fDesc[fd].Mode != FFS_O_RDONLY) && (fDesc[fd].Mode != FFS_O_RDWR)) {
      return 0;
    }

    offset = fDesc[fd].fileOffset;
    fileSize = inode[fDesc[fd].inode].fileSize;
    block = GetBlockIndex(fd, offset);
    fbuf = call Flash.getReadBlock(block);

    for (i = 0; (i < size) && ((offset + i) < fileSize); i++) {
       if (((offset + i) & (BLOCK_SIZE - 1)) == 0) {
         block = GetBlockIndex(fd, offset + i);
         fbuf = call Flash.getReadBlock(block);
       }
       ((char *)inbuf)[i] = fbuf[(offset + i) & (BLOCK_SIZE - 1)];

    }

    // if the current access mode is read/ write and we've entered a new block,
    // close the old block and open the new block for writing
    if ((fDesc[fd].currentBlock != -1) && (fDesc[fd].Mode & FFS_O_RDWR)) {
      if ((fDesc[fd].fileOffset >> BlockBits) !=
          ((fDesc[fd].fileOffset + i) >> BlockBits)) {
        call Flash.commitBlock(fDesc[fd].currentBlock);
        fDesc[fd].currentBlock =
          GetBlockIndex(fd, fDesc[fd].fileOffset + i);
        fDesc[fd].mptr = call Flash.getWriteBlock(fDesc[fd].currentBlock);

        // If the seek enters a block indexed by a different first level entry
        // then close the old entry and open the new one
        oldFL = ((offset >> BlockBits) - ZERO_LEVEL_BLOCKS) >> IndexBits;
        newFL = (((offset + i) >> BlockBits) - ZERO_LEVEL_BLOCKS) >> IndexBits;
        if (oldFL != newFL) {
          call Flash.commitBlock(oldFL);
          fDesc[fd].fptr = (int16_t *) call Flash.getWriteBlock(newFL);
        }
      }
    }

    fDesc[fd].fileOffset += i;

    return (i);
  }

      

  /*
   * Copy the contents of the buffer to the file and advance the index pointer.
   * The return value is the number of bytes copied.
   */
  command int FlashFS.write (int fd, char *outbuf, int size) {
    int    i;
    int    block;         // physical block index of the current block
    int    offset;
    int    fileSize;
    char   *bufptr;

    // verify that file descriptor is valid 
    if (ValidFD(fd) == FALSE) return 0;

    // verify acces mode
    if ((fDesc[fd].Mode != FFS_O_WRONLY) && (fDesc[fd].Mode != FFS_O_RDWR)) {
      return 0;
    }

    offset = fDesc[fd].fileOffset;
    fileSize = inode[fDesc[fd].inode].fileSize;
    block = fDesc[fd].currentBlock;
    bufptr = fDesc[fd].mptr;

    // make sure there is enough space to write
    if ((offset + size) > fileSize) {   
      if (AppendBlocksToOffset (fd, offset + size) == FAIL) {
        return 0;
      }
    }

    for (i = 0; i < size; i++) {
      if (((offset + i) & (BLOCK_SIZE - 1)) == 0) {
        if (block != -1) {
          call Flash.commitBlock(block);
        }
        block = GetBlockIndex(fd, offset + i);
        bufptr = call Flash.getWriteBlock(block);
      }
      bufptr[(offset + i) & (BLOCK_SIZE - 1)] = ((char *)outbuf)[i];
    }

    fDesc[fd].fileOffset += i;
    if (fDesc[fd].fileOffset > inode[fDesc[fd].inode].fileSize) {
      inode[fDesc[fd].inode].fileSize = fDesc[fd].fileOffset;
    }
    fDesc[fd].currentBlock = block;
    fDesc[fd].mptr = bufptr;

    return (i);
  }



  /*
   * Test whether there are any open file descriptors.  If there are not, write
   * the 0-page and 1-page back to flash.
   */
  void TestAndFlushInodes() {
    int i;

    for (i = 0; i < MAX_FD; i++) {
      if (fDesc[i].valid == TRUE) return;
    }

/* leave them open for testing
    call Flash.commitBlock(0);
    call Flash.commitBlock(1);
    inode = NULL;
    usedPages = NULL;
*/
  }



  /* 
   * Close the file and commit all of the changes to flash.  The return value
   * is -1 if there was an error.
   */
  command int FlashFS.close (int fd) {
    if (ValidFD(fd) == FALSE) return -1;

    if (fDesc[fd].currentBlock != -1) {
      call Flash.commitBlock(fDesc[fd].currentBlock);
      fDesc[fd].mptr = NULL;
    }
    if (fDesc[fd].fBlock != -1) {
      call Flash.commitBlock(fDesc[fd].fBlock);
      fDesc[fd].fptr = NULL;
    }

    fDesc[fd].valid = FALSE;

    TestAndFlushInodes();

    return 0;
  }



  /*
   * Write the in-core contents of the file back to the storage device
   * and leave the block open for writing.
   */

  command int FlashFS.flush (int fd) {
    int block, i;

    // flush all files to avoid inode synchronization issues

    if (ValidFD(fd) == FALSE) return -1;

    for (i = 0; i < MAX_FD; i++) {
      if ((block = fDesc[i].currentBlock) != -1) {
        call Flash.commitBlock(block);
        fDesc[i].mptr = (char *)call Flash.getWriteBlock(block);
      }
      if ((block = fDesc[i].fBlock) != -1) {
        call Flash.commitBlock(block);
        fDesc[i].fptr = (int16_t *) call Flash.getWriteBlock(block);
      }
    }

    call Flash.commitBlock(0);
    inode = (FInode *) call Flash.getWriteBlock(0);
    call Flash.commitBlock(1);
    usedPages = (char *) call Flash.getWriteBlock(1);
    
    return 0;
  }



  /*
   * Release the storage associated with the file name.  The contents of the
   * file may not be 0'd out.  If an error occurs, -1 is returned.
   */

  command int FlashFS.delete (char *name) {
    int    inumber;           // inode index corresponding to name
    int    blocks;            // number of block in this inode
    int16_t *fptr;            // index pointer to first and second level tables
    int    ind, fInd;         // physical block index for direct, first, and
                              // second level tables
    int    i;

    inumber = GetInode(name);

    // Make sure there are no open descriptors for this inode
    for (i = 0; i < MAX_FD; i++) {
      if ((fDesc[i].valid == TRUE) && (fDesc[i].inode == inumber)) return 0;
    }

    // Mark pages as available
    if (usedPages == NULL) {
      usedPages = (char *) call Flash.getWriteBlock(1);
    }

    blocks = inode[inumber].fileSize >> BlockBits;

    // free up direct data blocks;
    for (i = 0; (i < ZERO_LEVEL_BLOCKS) && (i < blocks); i++) {
      ind = inode[inumber].dataBlock[i];
      usedPages[ind >> 3] &= ~(1 << (ind & 0x7));
    }

    // free up first level data blocks
    blocks -= ZERO_LEVEL_BLOCKS;
    if (blocks > 0) {
      for (i = 0; (i < FIRST_LEVEL_BLOCKS) && (i < (blocks >> IndexBits)); i++){
        fInd = inode[inumber].firstLevel[i];
        fptr = (int16_t *) call Flash.getReadBlock(fInd);
        for (i = 0; (i < INDEXES_PER_BLOCK) && (i < blocks); i++) {
          ind = fptr[i];
          usedPages[ind >> 3] &= ~(1 << (ind & 0x7)) ;
        }
        usedPages[fInd >> 3] &= ~(1 << (fInd & 0x7)) ;
      }
    }

    // close any open write pages
    TestAndFlushInodes();

    return 0;
  }



  /*
   * Return a pointer to the inode structure for printing.
   */

  command FInode *FlashFS.getInode (int *next) {
    int i;

    if (next < 0) return NULL;
    for (i = *next; i < MAX_INODE; i++) {
      if (inode[i].flags == FINODE_VALID) {
        *next = i + 1;
        return (&(inode[i]));
      }
    }
    *next = -1;
    return (NULL);
  }


/*
 * End of FlashFS interface.
 */

}

