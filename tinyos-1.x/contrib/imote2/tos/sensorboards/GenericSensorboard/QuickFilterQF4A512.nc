interface QuickFilterQF4A512 {

  command result_t initializeQF4A512();
  
  event result_t initializeQF4A512Done();

  command result_t calibrateQF4A512(bool offset, uint8_t channel);
  
}



