/*
 *I2C Bus Sequence definitions
 *
 *
 *@authors Lama Nachman, Robbie Adler
 *
 */

#ifndef __I2CBUSSEQUENCE_H__
#define __I2CBUSSEQUENCE_H__

enum {
  I2C_OP_WRITE=0,
  I2C_OP_READ=1
};

enum {
  I2C_START=0,
  I2C_END=1,
  I2C_READ=2,
  I2C_WRITE=3
};


typedef struct i2c_op_t {
   uint8_t op;
   uint8_t param;
   uint8_t res;
} i2c_op_t;

#endif // __I2CBUSSEQUENCE_H__

