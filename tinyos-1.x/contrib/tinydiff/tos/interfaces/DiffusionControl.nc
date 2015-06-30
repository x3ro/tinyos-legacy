interface DiffusionControl {

  // add a list of nodes that comprise the gradient for a set of attributes 
  // NOTE: this *replaces* the gradient list if already in place.
  command result_t addGradientOverride(Attribute *attrList, uint8_t numAttrs,
                                       uint16_t *gradients, uint8_t numGrads);

  // simply remove an override that's already in place
  // We are not allowing partial removal of gradient nodes comprising the
  // gradient override entry in order to keep the code simple... since this
  // is only a very short-term measure... where you would want to add an
  // override and later remove it... and no incremental additions removals
  // would be needed...
  command result_t removeGradientOverride(Attribute *attrList, uint8_t numAttrs);

  // placeholder for future controls...
} 
