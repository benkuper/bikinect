class Mapping
{
  
  public String label;
  public String id;
  
  public MappingProcessor processor;
  public MappingFeedback feedback;
  
  public IMappingOutput[] outputs;
  public int numOutputs;

  public Mapping(String _id, String _label, MappingProcessor _processor, IMappingOutput[] _outputs) {

    this.id = _id;
    this.label = _label;
   
    this.processor = _processor;
    this.outputs = _outputs;
    numOutputs = outputs.length;
    
    feedback = new MappingFeedback(this);
    feedback.mode = processor.getFeedbackMode();
    feedback.isBoolean = processor.isBoolean;
    feedback.effect = processor.effect;
    
    feedback.label = processor.label;
    feedback.showLabel = processor.labelFeedback;
   
    println("New mapping => "+numOutputs+" outputs, feedbackMode :"+feedback.mode);
  }

  public float[] getNormalizedValues()
  {
    float[] values;
    values = processor.getProcessedValues();
    
    feedback.value = values[0]; 
    return values;
  }
  
  public void drawFeedback()
  {
    if(feedback.mode == Tokens.NO_FEEDBACK) return;
    
    feedback.screenVecs = processor.getFeedbackVectors();
    feedback.draw(processor.isActive);
  }
  
  public void send(float[] values)
  {
    if(!processor.isActive)
    {
      return;
    }
    
    for(int i=0;i<numOutputs;i++){
      outputs[i].send(values);
    }
  }
}

