/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

includes McCORD;

module NodeListM {
    provides interface NodeList;
}

implementation {

    command result_t NodeList.addToList(uint16_t * list, uint8_t size,  uint16_t node) {
        uint8_t i;
        for (i = 0; i < size - 1; i++) {
            // We don't care if node is at the end of the list,
            // since it will be shifted out anyway.
            if (list[i] == node || list[i] == INVALID_NODE_ADDR)
                break;
        }
#ifdef PLATFORM_PC
        if (i == (size - 1) // not found node in the list
            && list[i] != node
            && list[i] != INVALID_NODE_ADDR) {
            dbg(DBG_USR1, "List (0x%X) overflows.\n", list);
        }
#endif
        for (; i >= 1; i--) {
            list[i] = list[i-1];
        }
        list[0] = node;

        return SUCCESS;
    }

    command result_t NodeList.removeFromList(uint16_t * list, uint8_t size, uint16_t node) {
        uint8_t i;
        for (i = 0; i < size; i++) {
            if (list[i] == node) {
                break;
            } 
        } 
        if (i < size) {
            // Found.
            for (; i < size - 1; i++) {
                list[i] = list[i+1];
            } 
            list[size-1] = INVALID_NODE_ADDR;
        }
        return SUCCESS;
    }

    command bool NodeList.searchList(uint16_t * list, uint8_t size, uint16_t node) {
        int i;
        for (i = 0; i < size; i++) {
            if (list[i] == node) return TRUE;
            else if (list[i] == INVALID_NODE_ADDR) break;
        }
        return FALSE;
    }

    command uint8_t NodeList.countList(uint16_t * list, uint8_t size) {
        uint8_t i;
        uint8_t count = 0;
        for (i = 0; i < size; i++) {
            if (list[i] != INVALID_NODE_ADDR) count++;
        }
        return count;
    }

    command void NodeList.printList(uint16_t * list, uint8_t size) {
#ifdef PLATFORM_PC
        char buf[128];
        int len = 0;
        int i;
        for (i = 0; i < size; i++) {
             if (list[i] == INVALID_NODE_ADDR) break;
             len += sprintf(&(buf[len]), "%d ", list[i]);
        }
        buf[len] = '\0';
        dbg(DBG_USR1, "%s\n", buf);
#endif
    }

}
