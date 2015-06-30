/*
  M e d i a n I n d e x . n c

  This file (c) Copyright 2004 The MITRE Corporation (MITRE)

  This file is part of the NEST Acoustic Subsystem. It is licensed
  under the conditions described in the file LICENSE in the root
  directory of the NEST Acoustic Subsystem.
*/

includes Fixed;

interface MedianIndex {
  command void start
    (uint8_t len, uint8_t *data, uint8_t *indexToData,
     uint8_t *dataToIndex, result_t *status);

  command void SetData(uint8_t dataPos, uint8_t value, result_t *status);
  command ufix16_1_t MedianValue(result_t *status);
} // MedianIndex
