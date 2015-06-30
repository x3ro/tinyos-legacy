                    Attributes in the PS Middleware

In the PS middleware message content is structured as a set of
attribute/value pairs. This requires a clear definition of what the
exact semantics of an attribute and its value are (1), how attributes
are uniquely identified on a global scale (2), and what the supported
operations on a given attribute are (3). In short, the chosen solution
is to keep all necessary information in a single XML file located at
http://cvs.sourceforge.net/viewcvs.py/tinyos/tinyos-1.x/
contrib/eyes/tos/lib/PublishSubscribe/attributes/attributes.xml.

For each attribute there is an XML section <ps_attribute> ...
</ps_attribute> in the attributes.xml file. Within the section the
attribute is defined by the following XML tags (subsections are
indented):

  attribute_name: Short textual label (not necessarily unique)
  attribute_description: Textual description of the attribute (or e.g. hyperlink)
  attribute_type: Data type of the value {String, int8, uint8, int16, uint16, int32, uint32}, all integral types may be arrays {int8[], uint8[], int16[], uint16[], int32[], uint32[]}
  attribute_min: Minimum value (for String/array = minimum length)
  attribute_max: Maximum value (for String/array = maximum length)
  ps_metric: A subsection per metric of the value (e.g. degree celsius)
    metric_conversion: Conversion formula, in which "X" represents the value {X,+,-,*,/,FLOAT,(,)}* 
  attribute_endianness: Endianness of the value {big, little}
  attribute_component: NesC component implementing the attribute
  attribute_preferred_visualization: Preferred graphical representation {number, graph, text, none}
  ps_operation: A subsection per allowed operation on the attribute
    operation_name: Short textual representation (e.g. "<", ">")
    operation_description: Textual description of the operation

In order to uniquely identify attributes on a global scale in the
PS middleware each attribute is assigned a globally unique integral
identifier (attribute ID). This identifier is expressend as an XML
attribute "id" as part of the <ps_attribute> tag, e.g. <ps_attribute
id="17">. Operation IDs are unique only within the context of an
attribute definition, i.e.  different attributes may assign different
operations to the same operation ID.  An operation ID is expressend as
an XML attribute "id" as part of the <ps_operation> tag.  All IDs are
a non-negative integral number, the exact range is defined in PS.h
(ps_attr_ID_t and ps_opr_ID_t). 

As a value might need addional postprocessing in order to be converted 
to a certain metric there can be an arbitrary number of ps_metric subsections 
(if only the raw data is relevant then there is no such subsection).  
Each metric subsection is defined by the <ps_metric> tag which has an 
XML attribute "name" that is a short textual description of the metric.  
There is one tag <metric_conversion> inside the subsection which includes the
conversion formula to convert the raw value to the desired metric.
Inside the formula the raw value is represented by "X". The formula
may also consist of:
 - the charaters plus "+", minus "-", times "*",over "/", 
 - brackets "(" and ")" 
 - float constants  E.g.: "10.25"
 - functions "sin()", "cos()", "exp()", "ln()", "log()"
 - predefined constants "pi", "e"
For a complete list of functions see
http://www.singularsys.com/jep/doc/html/op_and_func.html

For each attribute it is required to define at least the following
three elements: attribute_name, attribute_description and
attribute_type.

CHECK: To ensure that the attributes.xml is valid and compatible to
the above requirements run the shell command "xmllint --valid --noout
attributes.xml". It must not create any error messages.

Example attribute (excerpt of attributes.xml file):

  <ps_attribute id='0'>
    <attribute_name>ExtTemp</attribute_name>
    <attribute_description>The onboard (external) temperature sensor on the eyesIFX/eyesIFXv2 node.</attribute_description>
    <attribute_type>uint16</attribute_type>
    <attribute_min>0</attribute_min>
    <attribute_max>4095</attribute_max>
    <ps_metric name="degree celsius">
    <!-- With VREF at 1.5V a raw value of 1638 equals 0 degree celsius.
         The output is linear with 27.3 equal to a 1 degree celsius offset. -->
      <metric_conversion>(X -1638) / 27.3</metric_conversion> 
    </ps_metric>
    <attribute_endianness>big</attribute_endianness>
    <attribute_component>EyesIFXSensorC.nc</attribute_component>
    <attribute_preferred_visualization>number</attribute_preferred_visualization>
    <ps_operation id="0">
      <operation_name>=</operation_name>
      <operation_description>equals</operation_description>
    </ps_operation>
    <ps_operation id="1">
      <operation_name>&lt;</operation_name>
      <operation_description>smaller than</operation_description>
    </ps_operation>
    <ps_operation id="2">
      <operation_name>&lt;=</operation_name>
      <operation_description>smaller or equal</operation_description>
    </ps_operation>
    <ps_operation id="3">
      <operation_name>&gt;</operation_name>
      <operation_description>greater than</operation_description>
    </ps_operation>
    <ps_operation id="4">
      <operation_name>&gt;=</operation_name>
      <operation_description>greater or equal</operation_description>
    </ps_operation>
    <ps_operation id="5">
      <operation_name>ANY</operation_name>
      <operation_description>true</operation_description>
    </ps_operation>
  </ps_attribute>

