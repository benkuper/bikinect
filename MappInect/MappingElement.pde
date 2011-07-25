class MappingElement implements IRawValueProvider
{
  public int type;
  public int target;
  public int property;
  public int axis;
  public int value;
  public PVector position;
  
  //Internal
  public Boolean isVector;
  
  public MappingElement(String _type, String _target, String _property, String _axis, int _value, PVector _position)
  {
    this.type = Tokens.getIndexForToken(Tokens.mappingElementTypesToken,_type);
    
    switch(type){
      case Tokens.JOINT:
        this.target = getJointIdForToken(_target);
      case Tokens.POINT:
        this.isVector = true;
        break;
        
      default:
        this.isVector = false;
        break;
    }
    
    this.property = Tokens.getIndexForToken(Tokens.propertiesToken,_property);
    
    this.axis = Tokens.getIndexForToken(Tokens.axisToken,_axis);
    this.value = _value;
    this.position = _position;
    
    
    println(" * New MappingElement : type: "+type+", target: "+target+", property: "+property+", axis :"+axis+", value:"+value+", position : "+position+", isVector :"+isVector);
  }
  
  public int getAxis()
  {
    return axis;
  }
  
  public float getRawValue()
  {
    switch(type){
      case Tokens.POINT:
        return 0;

      case Tokens.VALUE:
        return value;
      
      case Tokens.JOINT:
        return getJointValue(trackedUsers[numUsers-1], target, axis);
    }
    
    println("## MappingElement => getDirectValue : type not handled -> "+type);
    return 0;
  }
   

  public PVector getRawVector()
  {
    switch(type){
      case Tokens.POINT:
        return position;
      
      case Tokens.VALUE:
        println("Element Value (value "+value+") can't be of type value when vector is needed. Is the processor of type distance / rotation ?");
        return null;
      
      case Tokens.JOINT:
        return getJoint(trackedUsers[numUsers-1], target);

    }
    
    println("## MappingElement => getDirectValue : type not handled -> "+type);
    return null;
  }
}

