// Public interface API

includes attribute;
includes publish;

interface Publish {

    // Pre: numAttrs - number of attributes contained in array
    //      attributes - an array  containing the attribute list
    command PublicationHandle publish(Attribute *attributes, 
				      uint8_t numAttrs);

    // Pre: numAttrs - number of attributes contained in array
    //      attributes - an array  containing the attribute list
    //      handle - PublicationHandle returned by publish...
    //Post: Sends data pocket down stream from source to sink.
    //NOTE: the maximum number of attributes that can be sent down is 
    //(MAX_ATT - 1) and not MAX_ATT because sendData internally adds the
    //"CLASS IS DATA" attribute in addition to the data sent down...
    //TODO: perhaps this semantics needs revisiting...
    command result_t sendData(PublicationHandle handle, 
			      AttributePtr  attributes, uint8_t numAttrs);

    command result_t unPublish(PublicationHandle handle);
}
