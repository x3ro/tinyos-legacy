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
 * Blackbook Constants
 * These values can be modified here or at compile time
 * to change the RAM consumption and behavior of the
 * Blackbook file system
 * @author David Moss - dmm@rincon.com
 */

/** 
 * FILENAME_LENGTH must be an even number for word alignment
 * Each file on RAM (MAX_FILES worth of files) contains
 * a filename.  And each filemeta written to flash contains
 * a filename.  By using a smaller filename length, 
 * you're saving memory on flash and RAM while making it
 * more difficult to come up with unique and insightful names
 * for your files.  
 *
 * If you change the filename length, the 
 * flash needs to be completely erased before starting up blackbook 
 * the next time.  Otherwise, Blackbook won't know how to handle the
 * previous versions of filemeta existing on flash.
 * 
 * The last character is always '\0', leaving FILENAME_LENGTH-1
 * characters for the actual filename
 */
#ifndef FILENAME_LENGTH
#define FILENAME_LENGTH 14
#endif

/** 
 * The following is the maximum number of files on 
 * our file system
 * 
 * The amount of RAM used by Blackbook to store file info
 * can be expressed by:
 *   MAX_FILES * NODES_PER_FILE * sizeof(node)
 */
#ifndef MAX_FILES
#define MAX_FILES 8
#endif

/**
 * The following is the maximum number of nodes 
 * each file can use.  If the file system
 * boots and finds more files on flash than the 
 * RAM can support, the file system will be locked and
 * unusable. This can only happen if an application is
 * compiled with lots of RAM allocated to Blackbook and
 * fills up a bunch of nodes on flash, and then another
 * application is compiled and installed to the mote
 * that doesn't allocate as much RAM.
 * 
 * The amount of RAM used by Blackbook to store file info
 * can be expressed by:
 *   MAX_FILES * NODES_PER_FILE * sizeof(node) 
 *       + MAX_FILES * sizeof(file)
 */
#ifndef NODES_PER_FILE
#define NODES_PER_FILE 3
#endif

/**
 * The Checkpoint file is actually a Dictionary file in
 * disguise.  If it is very small, new Checkpoint
 * files will have to be created more often, and
 * sometimes a file may not be able to be created
 * if lots of other files are open for writing on 
 * the system.  If the Checkpoint file is larger,
 * new Checkpoint files will be created less often,
 * but it may take longer to boot up due to the key
 * search in the file.
 * A good tradeoff is to dedicate around 10 pages of
 * flash to the checkpoint file. That's about 158 checkpoints.
 * Feel free to alter it to meet your application's needs.
 */
#ifndef CHECKPOINT_DEDICATED_PAGES
#define CHECKPOINT_DEDICATED_PAGES 10
#endif


/**
 * Each client of the Dictionary component can 
 * have files open at the same time.  Each open file
 * can have a cache of the latest written keys for
 * quick retrieval. We can speed up key retrieval by
 * allocating more space in RAM for the key caches,
 * or we can decrease search time and increase energy 
 * consumption by allocating less RAM. 
 *
 * The amount of RAM used by the cache is defined by:
 *   uniqueCount["BDictionary"]*MAX_KEY_CACHE*12
 */
#ifndef MAX_KEY_CACHE
#define MAX_KEY_CACHE 5
#endif


/**
 * When a Dictionary becomes full from inserting values,
 * we must evaluate the file to see if we can create
 * extra space by copying the valid values to a new dictionary
 * file.  But because the values can have variable sizes
 * from 1 byte to 256 bytes, BDictionaryM needs a buffer
 * to copy data.  The buffer can be pretty small to save
 * on RAM, or large to make the copy process go faster and
 * use less energy when larger values are in the file.
 * The buffer also doubles as a filename when creating the
 * new file.  
 * So, the minimum buffer length is FILENAME_LENGTH
 * If you want to make it larger for faster and more energy
 * efficient copies at the expense of RAM, go for it.
 */
#ifndef VALUE_COPY_BUFFER_LENGTH
#define VALUE_COPY_BUFFER_LENGTH FILENAME_LENGTH
#endif





