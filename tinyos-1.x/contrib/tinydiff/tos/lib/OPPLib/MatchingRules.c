
/*
 * Implementation file for matching rules
 * Authors: Moshe Golan, Mohan Mysore
 */

#include "MatchingRules.h"


// ================ Functions Implementation  =======================

// Note: if "to" is larger than "from", the "to" array
// will first be wiped clean and then attributes from "from" copied over
// there --> possible side effect on trailing items of the "to" array...
result_t copyAttribs(Attribute *to, uint8_t toMaxSize, 
		     Attribute *from, uint8_t numFrom)
{
  if (numFrom > toMaxSize)
  {
    return FAIL;
  }

  memset((char *)to, 0, sizeof(Attribute) * toMaxSize);
  memcpy((char *)to, (char *)from, numFrom * sizeof(Attribute));
  return SUCCESS;
}

// TODO: change arguments "a" and "b" to pointers... less stack space.
BOOL areAttribsEqual(Attribute a, Attribute b)
{
  if (a.key != b.key)
  {
    return FALSE;
  }
  
  if (a.op != b.op)
  {
    return FALSE;
  }

  if (a.value != b.value)
  {
    return FALSE;
  }

  return TRUE;
}

SEARCH_STATUS foundAttribInArray(Attribute attrib, 
				   AttributePtr array, uint8_t numAttrs)
{
  uint8_t i;

  if (array == NULL || numAttrs == 0)
  {
    return NOT_FOUND;
  }

  for (i = 0; i < numAttrs; i++)
  {
    if (areAttribsEqual(attrib, array[i]))
    {
      return FOUND;
    }
  }
  return NOT_FOUND;
}

BOOL areAttribArraysEquiv(Attribute *attributes1, uint8_t numAttrs1,
			Attribute *attributes2, uint8_t numAttrs2)
{
  uint8_t i = 0;

  if (numAttrs1 != numAttrs2)
  {
    dbg(DBG_USR3, "areAttribArraysEquiv: numAttrs1 = %d while numAttrs2 = %d\n",
	numAttrs1, numAttrs2); 
    return FALSE;
  }

  // approach: each attribute in 1 should be in 2 and vice versa
  // this approach is necessary because two attribute arrays can have
  // attributes in different orders but have the same attributes... 
  // check if every attribute in 1 can be found in 2
  for (i = 0; i < numAttrs1; i++)
  {
    if (NOT_FOUND == foundAttribInArray(attributes1[i], attributes2, numAttrs2))
    {
      dbg(DBG_USR3, "areAttribArraysEquiv: attrib %d of 1 (%d:%d:%d) not found "
	  "in 2\n", i, attributes1[i].key, attributes1[i].op, 
	  attributes1[i].value);
      return FALSE;
    }
  }

  // check if every attribute in 2 can be found in 1
  for (i = 0; i < numAttrs2; i++)
  {
    if (NOT_FOUND == foundAttribInArray(attributes2[i], attributes1, numAttrs1))
    {
      dbg(DBG_USR3, "areAttribArraysEquiv: attrib %d of 2 (%d:%d:%d) not found "
	  "in 1\n", i, attributes2[i].key, attributes2[i].op, 
	  attributes2[i].value);
      return FALSE;
    }
  }

  dbg(DBG_USR2, "areAttribArraysEquiv: attribs equiv\n");
  return TRUE;
}


// ====================== One attribute Match data -> interest ======
 
MATCH_STATUS attMatch(Attribute *interestAtt, Attribute *dataAtt)
// Post: Returns true if attributes match as defined in the matching rules
//       One way match- dataAtt(data) is matched against interestAtt(interest).
// 
{
  // If key is different return false.
  if (interestAtt->key != dataAtt->key) 
  {
       return NO_MATCH;
  }

  // Check operator value pair
  switch (interestAtt->op) {

  case EQ:
    if ((dataAtt->op == IS) && (dataAtt->value == interestAtt->value  )) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;
    }
    // not reached...
    break;

  case NE:
    if (( dataAtt->op == IS) && (dataAtt->value != interestAtt->value  )) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;
    }
    // not reached...
    break;

  case GT:
    if (( dataAtt->op == IS) && (dataAtt->value > interestAtt->value  )) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;
    }
    // not reached...
    break;

  case GE:
    if (( dataAtt->op == IS) && (dataAtt->value >= interestAtt->value  )) 
    {
	 return MATCH;
    }
    else
    {
      return NO_MATCH;
    }
    // not reached...
    break;

  case LT:
    if (( dataAtt->op == IS) && (dataAtt->value < interestAtt->value  )) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;  
    }
    // not reached...
    break;

  case LE:
    if (( dataAtt->op == IS) && (dataAtt->value <= interestAtt->value  )) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;  
    }
    // not reached...
    break;

  case EQ_ANY:
    if (dataAtt->op == IS) 
    {
      return MATCH;
    }
    else
    {
      return NO_MATCH;
    }
    // not reached...
    break;

  default:
    // Undefined Operators
    dbg(DBG_ERROR, "attMatch: unknown operator %d in interestAtt\n",
	interestAtt->op);
    return NO_MATCH;
    break;
  } // end switch
}

// =======  One interest attribute Match coming -> cached  ======

MATCH_STATUS attInterestMatch( Attribute  * att1, Attribute  * att2  )
// Post: Returns true if attribute of one intrest match
//       the attributes of another interest with the exepthion that 
//       interval can change.

{
  // If key is different return false.
  if ((att1->key != att2->key) || 
      (att1->op != att2->op) || 
      ((att1->key != INTERVAL) &&
       (att1->value != att2->value)))
  {
    return NO_MATCH;
  }

  return MATCH;
}

// ======================  data -> interest match ================

// TODO: instead of requiring an InterestMessage, instead require an array
// of attributes... that way, this can be used not only with matching with
// interests in the InterestCache but also the GradientOverride and Filter
// data structures
MATCH_STATUS dataMatch(InterestMessage *interest, DataMessage *data)
// Post: Returns true if data matches an interest as defined in the matching rules

{
  /* The implementation is based on a double loop for one way match.
     First loop select all attributes of att1 interest
     Second loop matches the interest attribute to at least one data att. 
     If all attributes of the interest where matched returns true. 
     Algorithm assumes attributes are not necessary matching in order.
  */

  uint8_t i;          // interest attributes loop counter
  uint8_t d;          // data attributes loop counter
  uint8_t match;      // Boolean indicator for a match
  
  // error checking

  if (data->numAttrs == 0 || data->numAttrs > MAX_ATT)
  {
    dbg(DBG_USR3, "dataMatch: data->source = %d data->numAttrs = %d; "
	"bailing out\n", data->source, data->numAttrs);
    return NO_MATCH;
  }
  if (interest->numAttrs == 0 || interest->numAttrs > MAX_ATT)
  {
    dbg(DBG_USR3, "dataMatch: interest->sink = %d, interest->numAttrs = %d; "
	"bailing out\n", interest->sink, interest->numAttrs);
    return NO_MATCH;
  }

  for (i = 0; i < interest->numAttrs; i++)
  {
    match = 0; // reset indicator
    for (d = 0; d < data->numAttrs; d++)
    {
      // If interest att matches one of data att continue
      // NOTE: the check for != IS is to avoid problems with the CLASS IS
      // INTEREST attribute in the interest by simply ignoring it
      if (interest->attributes[i].op == IS)
      {
	match = 1;
	break;
      }
      else if (attMatch(&interest->attributes[i], &data->attributes[d]) == MATCH)
      {
	//dbg(DBG_USR1, "dataMatch: attribute match!!\n");
	match = 1;
        break;  
      }
    } // end inner for
    // If couldn't find one match return false 
    if (match == 0)
    {
      dbg(DBG_USR3, "dataMatch: no match for key: %d op: %d value %d!\n",
	  interest->attributes[i].key, interest->attributes[i].op, 
	  interest->attributes[i].value);
      return NO_MATCH;
    }

  } // end outer for 

  // All attributes are matching
  dbg(DBG_USR1, "dataMatch: all attributes matching\n");
  return MATCH;

} // end



// This is the function that should be used all over the place.... but I
// did not modify the places where dataMatch was used because those pieces
// of code were very well tested.  When there's time for cleanup,
// oneWayMatch should replace dataMatch due to its generality and
// simplicity (TODO)
MATCH_STATUS oneWayMatch(Attribute *referenceAttrs, uint8_t numRefAttrs,
			 Attribute *candidateAttrs, uint8_t numCandAttrs)

{
  uint8_t ref = 0;           // reference attribute array index
  uint8_t cand = 0;          // candidate attribute array index
  uint8_t match = NO_MATCH;  
  
  if (numCandAttrs == 0 || numCandAttrs > MAX_ATT)
  {
    dbg(DBG_USR3, "oneWayMatch: candidate numAttrs %d out of bounds!\n",
	numCandAttrs);
    return NO_MATCH;
  }

  if (numRefAttrs == 0 || numRefAttrs > MAX_ATT)
  {
    dbg(DBG_USR3, "oneWayMatch: reference numAttrs %d out of bounds!\n",
	numRefAttrs);
    return NO_MATCH;
  }

  for (ref = 0; ref < numRefAttrs; ref++)
  {
    match = 0; // reset indicator
    for (cand = 0; cand < numCandAttrs; cand++)
    {
      // NOTE: the check for != IS is to avoid problems with the CLASS IS
      // INTEREST attribute in the interest by simply ignoring it
      if (referenceAttrs[ref].op == IS)
      {
	match = 1;
	break;
      }
      else if (attMatch(&referenceAttrs[ref], &candidateAttrs[cand]) == MATCH)
      {
	//dbg(DBG_USR1, "oneWayMatch: attribute match!!\n");
	match = 1;
        break;  
      }
    } // end inner for
    // If couldn't find one match return false 
    if (match == 0)
    {
      return NO_MATCH;
    }

  } // end outer for 

  // All attributes are matching
  dbg(DBG_USR1, "oneWayMatch: all attributes matching\n");
  return MATCH;

} // end
