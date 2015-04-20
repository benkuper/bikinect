# Introduction #

Add your content here.


  * **MAPPING\_SETS :**
> They are sets of mappings with an identifier. This allows to switch between sets at anytime, all the controller and mappings will be updated.
> > _id_ : Id of the mapping set. Required if multiple mapping sets are used. Must be unique.

> _shortcut_ : Keyboard shortcut of the mapping set. Allow to launch the mapping set via the keyboard. Must be only 1 character. Optional.

> _permanent_ : Boolean to choose wether the mapping set is a permanent mapping (i. e. loaded even if the chosen set is not this) or not. Useful for action processors that need to stick in a mapping sequence. Default false.

> _inScope_ : Boolean to choose wether the mappingset is used in the scope for nextSet action and default set loading. If set to false, when loading this set as current Set, the next set in the scope will be loaded. Useful for permanent sets that you don't want to load alone, or for mappings you want to access only via their id. Default true. /!\ At least one mapping set must be inScope, otherwise the processing will get in an infinite loop, search over and over for an inScope set.

  * **MAPPINGS :**
> _id_ : Id of the mapping. Default "". (not used in the current version). Must be unique if mentionned.

> _label_ : Label describing the mapping, for feedback . Default "". (not used in the current version).

> 

&lt;processor&gt;

_> > The main processor to use to calculate the value to send. Others processors can be nested into the main processor. See below available processors and their usage.

>_

&lt;/processor&gt;



> 

&lt;output&gt;

_> > The ouputs that will actually send the values to other software. See below, OUTPUT section.

>_

&lt;/output&gt;




  * **PROCESSORS :**
> _id_ : Processor's id. Not used in the current version, but may be used for linking in future versions.

> _label_ Processor's title, for feedback.

> _type_

> - direct `[`Default`]`: Values are passed directly to the output without using the min/max values. Useful for getting the 3d coordinates of the joints through the network. Be careful with midi output. Can be nested.

> - mapped : Simple value mapping from one element property to a midi value.  Can be nested.

> - distance : Distance between 2 elements. Default min\_value change to 0. Default max\_value is change to 1000. /!\ Can't nest processors inside, must be direct < element > objects
> - rotation : Rotation between 2 elements. Default min\_value is changed to 0. Default max\_value is change to 360. /!\ Can't nest processors inside, must be direct < element > objects.

> - timed : Tween a value from the min\_value to max\_value in the predefined time (NOT IMPLEMENTED YET)

> - filtered : Sends a gradient value (unlike boolean or conditionnal type) depending on the filter and the inactive parameter. Can be nested. See below for available filters for this type.


> _(these types return boolean values)_

> - boolean : Sends either min\_value or max\_value depending on a (boolean) filter. Default min\_value is changed to 0. Default max\_value is change to 1. Can be nested.

> - conditionnal : Allows to have multiple processors nested with a conditionnal token ("and", "or"). Can be nested.


> _(specials)_

> - action : Triggers an action when a positive value is passed. See below available actions.


> _If processor is boolean / conditionnal. Optional_

> _effect_

> - noeffect [Default](Default.md) : Boolean standard effect.

> - trigger  : Makes bang-like effect with a boolean processor. Sends always min\_value until the filter is validated, then throws once max\_value and comes back to sending 0 until the filter is off and validated again.

> - toggle : Makes a toggle-like effect with a boolean processor. When the filter is validated, switches the value between min\_value and max\_value.

> _If processor requires filter. Filters are operators that return either 0 or 1. This value is then used by the processor to send the final value._

> _filter_

> - greater`_`than : If 1st element is bigger than 2nd element (NOT for type "filtered")

> - less`_`than : If 1st element is smaller than 2nd element (NOT for type "filtered")

> //needs 2 child processors
> - between : If 1st element is bigger than 2nd element and less than 3rd element (NOT for type "filtered")

> _(Below are filters for the "filtered" type. All of them need 2 processors)_

> - greatest : returns the biggest value from all the nested processors / elements. (Only for type "filtered")

> - lowest : returns the lowest value from all the nested processors / elements. (Only for type "filtered")

> - average : returns the average value of all the nested processors / elements.( Only for type "filtered")

> - gate : returns the value of the 1st child only if the 2nd child is greater than 0 (preferrably use a boolean/conditionnal processor for the 2nd child)(Only for type "filtered")



> _If processor is "conditionnal"._

> _operator_

> - and [Default ](.md) : AND operator. The processor will return 1 if all the nested processors returns 1.

> - or : OR operator. The processor will return 1 if at least one processor returns 1.

> _If processor is anything but "direct"_

> _minVvalue / maxValue_

> - minValue : Value sent when boolean (or trigger) filter does not pass. Default -500 (for direct joint x/y position easy mapping)

> - maxValue: Value sent boolean (or trigger) filter passes. Default 500 (for direct joint x/y position easy mapping)

> _If processor is anything but "direct" and boolean type_

> _overflow_

> - none : No filtering applied. If a value is outside it's limit, it will continue to change proportionnally to the mapping range set up. Be careful with midi output.

> - clip [Default](Default.md) : If a value is outside it's limit, it will be constraint at the value's limit (0 | 0 -> 127 || 127).|
|:---------|

> - loop : If a value is outside it's limit, it will continue to change but starting from it's opposite limit, like a loop effect (0 -> 127 | 0 -> 127 || 0 -> 127).|
|:---------|

> - zero : If a value is outside the limit, it will be considered as 0 (0 | 0 -> 127 || 0).|
|:---------|

> _Only used for children elements and feedback. Sets a default value for all childrens._

> _[axis](axis.md)_

> - "x", "y", "z","xy","xz","yz": 1D or 2D axis. If not set, parent's processor's axis will be used (or "x" if no parent processor).

> _If processor is "filtered"_

> _inactive_

> zero [Default](Default.md) : If the condition processor (the 2nd child processor) returns false, the value passed will be 0.

> keepValue : If the condition processor (the 2nd child processor) returns false, the value passed will be the last value computed when the condition processor was active.

> standby : If the condition processor (the 2nd child processor) returns false, the whole mapping won't send anything. If a "multi" processor is used, any inactive processor will return 0 and  the mapping will stop sending when all the child processors are inactive.

> _If processor is timed (Not implemented yet)_

> _time_
> - 0 to ... : time in milliseconds that will be used to tween the value to min\_value to max\_value

> _If processor is action_

> _action_

> - changeSet : Changes the mapping set to the specified file and setId (see below)

> - prevSet : Change the set to the previous child in scope. If last child is reached, nextSet load the 1st child in scope.

> - nextSet : Change the set to the next child in scope. If last child is reached, nextSet load the 1st child in scope.

> _file_ The name of the file to be loaded. The file must be in the /data folder.

> - < filename >.xml : if not specified, the current file will be used. "mappings.xml" is the default loaded file.

> _set_

> - the set ID to load. if not set, the first mapping set in the scope will be used.

> _(Below is for feedback only)_

> _showFeedback_ Boolean to choose wether to display the processor's feedback or not. Default true.

> _labelFeedback_ Boolean to choose wether to display the processor's label feedback. Only use when showFeedback is set to true and label is set. Default true.

> 

&lt;elements&gt;

_> > [...] A series of elements, depending on the processor type. If more elements than needed are declared, only elements starting from the first one will be used.

>_

&lt;/elements&gt;





  * **ELEMENTS :**

> _type_

> - joint : A Skeleton Joint retrieved from OpenNI. See below for available properties

> - value : A predefined custom value, see below.

> - point : A predefined 3D Point that will be used as a Vector (need to precise x, y and z coordinates);

> _If type is joint_

> _target_ : All the skeleton's joint as tokens.
> Tokens available : head, neck, torso, left\_shoulder, right\_shoudler, left\_elbow, right\_elbow, left\_hand_, right\_hand, left\_hip, right\_hip, left\_knee, right\_knee, left\_foot, right\_foot_

> _If type is of type vector (joint or point) and 1 axis is needed_

> _axis_

> - "x", "y", "z","xy","xz","yz": The 1D or 2D axis of the joints. If not set, processor's axis will be used.


> _If type is value_

> _value_ The constant value to process.

> _If type is point_

> _x, y ,z_

> - "x","y","z" : the 3 coordinates to define for the 3D Point (e.g. x="10" y="-300" z="1500"). Units relative to the Kinect's environment (in centimeters). Default 0,0,0.

> - "vector3d" : the PVector representation of the joint. Should not be necessary as the processor takes automatically the vector3d if needed.

> _If type is joint or custom\_point (or more generally a 3D Point)_
> _property_

> - position [Default](Default.md) : The 3d Position of the point.

> _------- Not implemented yet --------_

> - velocity : Velocity of a joint, filtered by coordinates (1D, 2D or 3D).

> - acceleration : Acceleration of the joint (same filtering system as velocity).



  * **MAPPING OUTPUTS**

  * MIDI Output

> _type_

> - "note" : value passed as a noteOn event.
> - "controller" [Default](Default.md) : value passed as a controllerChange event.

> _device_
> The MIDI device number to send. Default 0. Not used if deviceMap is > 0.

> _channel_
> The MIDI channel number to send. Default 1. Not used if channelMap is > 0.

> _value_
> The MIDI value number to send. Default 1. Not used if channelMap is > 0.

> _deviceMap_
> The index of the processor that will be used to send the device Number. If higher than 0, [device](device.md) parameter will be overriden. For example, if [deviceMap](deviceMap.md) set to 1, the first processor will be taken. If set to 2, the top processor must be of type "multi", and its 2nd child processor will be taken to send the device number. If [deviceMap](deviceMap.md) is higher than available processors, [device](device.md) value will be user.

> _channelMap_
> The index of the processor that will be used to send the channel Number. If  higher than 0, _channel_ parameter will be overriden. For example, if _channelMap_ set to 1, the first processor will be taken. If set to 2, the top processor must be of type "multi", and its 2nd child processor will be taken to send the channel number. If [channelMap](channelMap.md) is higher than available processors,b\_channel_value will be user._

> _velocityMap_
> The index of the processor that will be used to send the velocity Number. If higher than 0, [velocity](velocity.md) parameter will be overriden. For example, if _velocityMap_ set to 1, the first processor will be taken. If set to 2, the top processor must be of type "multi", and its 2nd child processor will be taken to send the velocity number. If [velocityMap](velocityMap.md) is higher than available processors, [velocity](velocity.md) value will be user.

> _minChannel_
> The mininum channel number that will be sent (i.e. if the returned value is 0, what channel will be sent).

> _maxChannel_

> The maximum channel number that will be sent (i.e. if the returned value is 1, what channel will be sent).

> _minVelocity_
> The mininum velocity number that will be sent (i.e. if the returned value is 0, what velocity will be sent).

> _maxVelocity_
> The maximum velocity number that will be sent (i.e. if the returned value is 1, what velocity will be sent).

> _distinctNotes_

> true or false : If the _type_ is "note" and the channel is the same as the previous sent channel, the output won't send anything until the channel has changed. Useful to avoid repetition notes when the mapping is used as a standard midi keyboard.


  * OSC Output

> _host_
> The host to which send the OSC messages. Default set in config.xml. (NOT IMPLEMENTED YET, only host from config.xml will be sent).

> _port_
> The port to which send the OSC messages. Default set in config.xml. (NOT IMPLEMENTED YET, only port from config.xml will be sent).

> _address_
> The address to which send the OSC messages. Final address will be the concatenation of addressPrefix set in config.xml and this value. Default "".