class MappingProcessor implements IRawValueProvider
{

  //XML Parameters
  public String id;
  public String label;
  public Boolean showFeedback;
  public Boolean labelFeedback;
  
  public int type;
  
  public int filter;
  public int effect;
  public int operator;
  
  
  public int minValue;
  public int maxValue;
  public int overflow;
 
  public int axis;
  
  public int action;
  public String file;
  public String setId;
  
  public int inactive;
  
  // Computed parameters
  public Boolean isBoolean = false;
  public Boolean isGroup = false;
  
  public Boolean isActive = true;
  
  public MappingElement[] elements;
  public MappingProcessor[] processors;
  public IRawValueProvider[] providers;
  public int numProviders;
  
  //Internal, for "filtered", "gate" filter with "keepValue" inactive parameter
  private float previousRawValue = 0;
  
  //Internal, for boolean and trigger types
  private Boolean previousValue = true; //Avoid triggering on load. Really important for action that reload sets.
  private Boolean toggleState = false;

  public MappingProcessor(String _id, String _label, Boolean _showFeedback, Boolean _labelFeedback, String _type, String _filter, String _operator,String _overflow, String _effect, String _axis, String _action, String _inactive)
  {
    this.id = _id;
    this.label = _label;
    this.showFeedback = _showFeedback;
    this.labelFeedback = (label.equals(""))?false:_labelFeedback;
   
    this.axis = Tokens.getIndexForToken(Tokens.axisToken,_axis);
    this.type = Tokens.getIndexForToken(Tokens.processorTypesToken, _type);
    this.inactive = Tokens.getIndexForToken(Tokens.processorInactiveToken, _inactive);
   
    
    this.action = Tokens.getIndexForToken(Tokens.processorActionsToken, _action);
    
    //Set min / max default values, -500 & 500 chosen for simple coordinate mapping
    minValue = -500;
    maxValue = 500;
    
    
    
    this.filter = Tokens.getIndexForToken(Tokens.processorFiltersToken, _filter);
    
   
    if(type == Tokens.ACTION){
       this.effect = Tokens.TRIGGER;
    }else{
       this.effect = Tokens.getIndexForToken(Tokens.processorEffectsToken, _effect);
    }
     
    switch(type){
      case Tokens.BOOLEAN:
      case Tokens.CONDITIONNAL:
      case Tokens.ACTION:
        this.operator = Tokens.getIndexForToken(Tokens.processorOperatorsToken, _operator);
        isBoolean = true;
        minValue = 0;
        maxValue = 1;
        break;
        
      case Tokens.ROTATION:
        minValue = 0;
        maxValue = 360;
        break;
        
      case Tokens.DISTANCE:
        minValue = 0;
        maxValue = 1000;
        break;
    }
    
    
    this.overflow = Tokens.getIndexForToken(Tokens.processorOverflowsToken, _overflow);
    
    
    println(" * New MappingProcessor : type: "+type+", filter: "+filter+", isBoolean :"+isBoolean+", effect :"+effect+", showFeedback :"+showFeedback+",labelFeedback:"+labelFeedback+", inactive ="+inactive);
  }
  
  
  
  public float[] getProcessedValues()
  {
    float[] processedValues = null;
    
    switch(type)
    {
      case Tokens.MULTI:
        processedValues = getMultiValues();
        isActive = false;
        if(isGroup){
          for(int i=0;i<numProviders;i++)
          {
            if(processors[i].isActive){
              isActive = true;
              break;
            }
          }
        }
        break;
        
      default:
        processedValues = new float[1];
        processedValues[0] = getProcessedValue();
        break;
    }
    
    
    return processedValues;
  }
  
  public float getProcessedValue()
  {
    float rawValue = getRawValue();
    previousRawValue = rawValue;
    
    switch(type){
      case Tokens.DIRECT:
      case Tokens.BOOLEAN:
      case Tokens.CONDITIONNAL:
        return rawValue;
        
      case Tokens.FILTERED:
         println("Tokens Filtered, rawValue = "+rawValue+", inactive "+inactive);
         if(rawValue == 0 && (inactive == Tokens.ZERO || inactive == Tokens.STANDBY)) return 0;
        break;
      
     
      default:
        break;
    }
    
    
    
    float processedValue = map(rawValue,minValue,maxValue,0,1);
    
    return processedValue;
    
  }
  
  public float[] getMultiValues()
  {
    float[] values = new float[numProviders];
    for(int i=0;i<numProviders;i++){
      if(isGroup){
        values[i] = processors[i].getProcessedValue();
      }else{
        values[i] = providers[i].getRawValue();
      }
    }
    
    return values;
  }
  
  public float getRawValue()
  {
    float rawValue = 0;  
    
    switch(type){
      case Tokens.DIRECT:
        return providers[0].getRawValue();
        
      case Tokens.MAPPED:
        rawValue = providers[0].getRawValue();
        break;
        
      case Tokens.DISTANCE:
        rawValue = getRawDistance();
        break;
        
      case Tokens.ROTATION:
        rawValue = getRawRotation();
        break;
        
      case Tokens.BOOLEAN:
        rawValue = getBooleanFilterValue()?maxValue:minValue;
        break;
      
      case Tokens.CONDITIONNAL:
        rawValue = getConditionnalFilterValue()?maxValue:minValue;
        break;
      
      case Tokens.FILTERED:
        rawValue = getFilteredFilterValue();
        break;
      
      case Tokens.ACTION:
        rawValue = getActionValue()?maxValue:minValue;
        break;
      
      default:
        print("## MappingProcessor => type not handled : "+type);
        break;
    }
    
    
    //Overflow Handling
    switch(overflow) {
      case Tokens.CLIP:
        if (rawValue < minValue) rawValue = minValue;
        if (rawValue > maxValue) rawValue = maxValue;
        break;
  
      case Tokens.LOOP:
        rawValue = (((rawValue-minValue) % (maxValue-minValue))+(maxValue-minValue))%(maxValue-minValue) + minValue;
        break;
  
      case Tokens.ZERO:
        if (rawValue < minValue || rawValue > maxValue) {
          rawValue = minValue;
        }
        break;
        
      case Tokens.NONE:
        //no overflow handling
        println("no Overflow");
        break;
        
      default:
        println("## MappingProcessor => overflow not handled : "+overflow);
        break;
    }
    
    return rawValue;
  }

  public float getRawDistance()
  {
    PVector v1 = providers[0].getRawVector();
    PVector v2 = providers[1].getRawVector();
    return dist(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
  }
  
  

  public float getRawRotation()
  {
    PVector v1 = providers[0].getRawVector();
    PVector v2 = providers[1].getRawVector();
    float v1c1 = 0;
    float v1c2 = 0;
    float v2c1 = 0;
    float v2c2 = 0;
    switch(providers[0].getAxis()){
      case Tokens.XY:
        v1c1 = v1.x;
        v1c2 = v1.y;
        break;
      case Tokens.YZ:
        v1c1 = v1.y;
        v1c2 = v1.z;
        break;
      case Tokens.XZ:
        v1c1 = v1.x;
        v1c2 = v1.z;
        break;
    }
    
    switch(providers[1].getAxis()){
      case Tokens.XY:
        v2c1 = v2.x;
        v2c2 = v2.y;
        break;
      case Tokens.YZ:
        v2c1 = v2.y;
        v2c2 = v2.z;
        break;
      case Tokens.XZ:
        v2c1 = v2.x;
        v2c2 = v2.z;
        break;
    }
    
    float result = degrees(atan2(v2c1 - v1c1,v2c2 - v1c2)+PI);
    //print("rotation degrees :"+result);
    return result;
  }
  
 

  public Boolean getBooleanFilterValue()
  {
    float rawValue = providers[0].getRawValue();
    float refValue = providers[1].getRawValue();
    
    Boolean result = false;
    switch(filter){
      case Tokens.GREATER_THAN:
        result = (rawValue > refValue);
        break;
      case Tokens.LESS_THAN:
        result = (rawValue < refValue);
      break;
      case Tokens.BETWEEN:
        float ref2Value = providers[2].getRawValue();
        result = (rawValue > refValue && rawValue < ref2Value);
        break;
      default:
        println("## MappingProcessor => filter not handled : "+filter);
        break;
    }
    
    result = processEffect(result);
    
    return result;
  }
 
  public Boolean getConditionnalFilterValue()
  {
    Boolean result = (operator == Tokens.AND);
    for(int i=0;i<numProviders;i++){
      if(providers[i].getRawValue() > 0 && operator == Tokens.OR){
        result = true;
        break;
      }
      if(providers[i].getRawValue() == 0 && operator == Tokens.AND){
        result = false;
        break;
      }
    }
    
    result = processEffect(result);
    
    return result;
  }
  
  protected Boolean getActionValue()
  { 
    Boolean result = providers[0].getRawValue() > 0;
    result = processEffect(result);
    
    return result;
    
  }
  
  protected Boolean processEffect(Boolean value)
  {
    
    Boolean result = value;

    switch(effect){
      case Tokens.TRIGGER:
        if (!previousValue && value) {
          result = true;
        }else{
          result = false;
        }
        break;
        
      case Tokens.TOGGLE:
        if (!previousValue && value) {
          toggleState = !toggleState;
        }
        result = toggleState;
        break;
        
      default:
        break;
    }
    previousValue = value;
    return result;
  }
  
  public float getFilteredFilterValue()
  {
    int numProviders = providers.length;
    float filteredValue = providers[0].getRawValue();
    float newValue = 0;
    
    switch(filter)
    {
      case Tokens.LOWEST:
        for(int i=1;i<numProviders;i++){
          newValue = providers[i].getRawValue();
          if(newValue < filteredValue) filteredValue = newValue;
        }
        break;
        
      case Tokens.GREATEST:
        for(int i=1;i<numProviders;i++){
          newValue = providers[i].getRawValue();
          if(newValue > filteredValue) filteredValue = newValue;
        }
        break;
        
      case Tokens.GATE:
        if(providers[1].getRawValue() == 0)
        {
          switch(inactive)
          {
            case Tokens.ZERO:
              println("Zero Inactive");
              filteredValue = 0;
              break;
            
            case Tokens.KEEP_VALUE:
              println("keepValue");
              filteredValue = previousRawValue;
              break;
              
            case Tokens.STANDBY:
              println("standby, inactive");
              filteredValue = 0;
              isActive = false;
              break;
          }
        }else{
          isActive = true;
        }
        break;
        
      case Tokens.AVERAGE:
        for(int i=1;i<numProviders;i++){
          filteredValue += providers[i].getRawValue();
        }
        filteredValue /= numProviders;
        break;
        
      default:
        print("MappingProcessor => getFilteredFilterValue, filter not handled "+filter);
        return 0;
    }
    
   
    return filteredValue;
  }
  
  public PVector getRawVector()
  {
    //May be needed to change to avoid hardcoding of the 1st <element> in the scope to be taken.
    if(isGroup || (!isGroup && elements[0].isVector)) return providers[0].getRawVector(); 
    return null;
  }
  
  public int getAxis()
  {
    return providers[0].getAxis(); //May be needed to change to avoid hardcoding of the 1st <element> in the scope to be taken.
  }
  
  public PVector[] getFeedbackVectors()
  {
    if(isGroup && type != Tokens.DISTANCE && type != Tokens.ROTATION) return processors[0].getFeedbackVectors();
    PVector[] vectors = new PVector[providers.length];
    for(int i =0;i<vectors.length;i++){
      PVector rawVector = (isGroup || (!isGroup && elements[i].isVector))?providers[i].getRawVector():null;
      if(rawVector != null){
        vectors[i] = new PVector();
       
        context.convertRealWorldToProjective(rawVector,vectors[i]);
         //println("*** Feedback vector "+vectors[i]);
      }
    }
    
    return vectors;
  }
  
  public int getFeedbackMode()
  {
    if(!showFeedback) return Tokens.NO_FEEDBACK;
    
    switch(type){
      case Tokens.DIRECT:
      case Tokens.MAPPED:
      case Tokens.BOOLEAN:
      case Tokens.CONDITIONNAL:
      case Tokens.FILTERED:
      case Tokens.MULTI:
      case Tokens.ACTION:
        if(isGroup) return processors[0].getFeedbackMode();
        
        switch(elements[0].type){ 
          case Tokens.JOINT:  // If the element targets a vector
          case Tokens.POINT:
            if(elements[0].axis < 3){ //If axis is either x, y or z
              int token = elements[0].axis;
              return token;
            }
            return Tokens.NO_FEEDBACK;
            
          default:
            return Tokens.NO_FEEDBACK;
        }
        
      case Tokens.DISTANCE:
        if((elements[0].type == Tokens.JOINT || elements[0].type == Tokens.POINT)
           && (elements[1].type == Tokens.JOINT || elements[1].type == Tokens.POINT)){
          return Tokens.LINE_DISTANCE;
        }else{
          return Tokens.NO_FEEDBACK;
        }
        
      case Tokens.ROTATION:
        if((elements[0].type == Tokens.JOINT || elements[0].type == Tokens.POINT)
           && (elements[1].type == Tokens.JOINT || elements[1].type == Tokens.POINT)){
          return Tokens.CIRCLE_ROTATION;
        }else{
          return Tokens.NO_FEEDBACK;
        }
   
      default:
        return Tokens.NO_FEEDBACK;
    }
  }

  public void setGroup(Boolean value)
  {
    isGroup = value;
    providers = isGroup?processors:elements;
    numProviders = providers.length;
    
    //Hack for default Min/Max values
    if(getAxis() == Tokens.Z && minValue < 0)
    {
      minValue = 1000;
      maxValue = 2000;
    }
  }
 
}

