// Subscribe interface API

includes attribute;
includes subscribe;
interface Subscribe {


  // subscribe for a certain data type: 
  // attributes: array of attributes
  // numAttrs: number of attributes contained therein
  command SubscriptionHandle subscribe(AttributePtr attributes, uint8_t numAttrs);
  
  // unsubscribe a subscription specified by handle...
  command result_t unsubscribe(SubscriptionHandle handle);

  // Serve up data that matched the subscription...
  // handle: subscription handle previously returned...
  // attributes: attributes in matching data message
  // numAttrs: number of attributes in the above array of attributes
  // NOTE: the app is expected to release back attributes array after
  // copying it...  so there's no two way hand-shake here...
  event result_t receiveMatchingData(SubscriptionHandle handle, 
				     AttributePtr attributes,
				     uint8_t numAttrs);
}

