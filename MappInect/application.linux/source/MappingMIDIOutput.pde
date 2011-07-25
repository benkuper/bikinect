class MappingMIDIOutput implements IMappingOutput
{
  
  public int type;
  public int device;
  public int channel;
  public int velocity;
  public int deviceMap;
  public int channelMap;
  public int velocityMap;
  
  public int minChannel;
  public int maxChannel;
  public int minVelocity;
  public int maxVelocity;
  public Boolean distinctNotes;
  
  public int previousChannel;
  
  public MappingMIDIOutput(String _type,int _device,int _channel,int _velocity,int _deviceMap,int _channelMap,int _velocityMap,
                           int _minChannel, int _maxChannel, int _minVelocity, int _maxVelocity, Boolean _distinctNotes)
  {
    this.type = Tokens.getIndexForToken(Tokens.midiTypesToken, _type);
    this.device = _device;
    this.channel = _channel;
    this.velocity = _velocity;
    this.deviceMap = _deviceMap;
    this.channelMap = _channelMap;
    this.velocityMap = _velocityMap;
    this.minChannel = _minChannel;
    this.maxChannel = _maxChannel;
    this.minVelocity = _minVelocity;
    this.maxVelocity = _maxVelocity;
    this.distinctNotes = _distinctNotes;
    
    previousChannel = channel;
    
    println(" > New MIDI Output : device :"+device+", channel :"+channel+", value :"+velocity+", deviceMap :"+deviceMap+", channelMap :"+channelMap+", valueMap:"+velocityMap);
  }
  
  public void send(float[] values)
  {
    int numValues = values.length;
    
   /* print("** MIDI send : ");
    for(int i=0;i<numValues;i++){
      print(values[i]);
      if(i < numValues -1){
        print(" / ");
      }
    }
    println(" -- ");*/
    
    int targetDevice = (deviceMap > 0 && deviceMap <= numValues)?int(map(values[deviceMap-1],0,1,0,127)):device;
    int targetChannel = (channelMap > 0 && channelMap <= numValues)?int(map(values[channelMap-1],0,1,minChannel,maxChannel)):channel;
    int targetVelocity = (velocityMap > 0 && velocityMap <= numValues)?int(map(values[velocityMap-1],0,1,minVelocity,maxVelocity)):velocity;
    
   
    Boolean sent = false;
    switch(type){
      case Tokens.CONTROLLER:
        sent = output.sendController(targetDevice, targetChannel, targetVelocity) == 1;
      break;
      
      case Tokens.NOTE:
         //println(targetChannel+" / "+previousChannel+" /" +distinctNotes);
         if(targetChannel == previousChannel && distinctNotes){
           sent = true;
           break;
         }
         sent = output.sendNoteOn(targetDevice, targetChannel, targetVelocity) == 1;
        //output.sendNoteOff(targetDevice, targetChannel, targetValue) == 1;
      break;
      
      default:
        println("### MIDI type not handled :"+type);
        break;
    }
    
    if(sent){
      //println("MidiOutput send midi on device "+targetDevice+", ch. "+targetChannel+", value :"+targetVelocity);
    }else{
      println("## error sending midi to output "+devices[midiOutDeviceID]+", device "+targetDevice+", ch. "+targetChannel+", value :"+targetVelocity);
    }
    
    previousChannel = targetChannel;
  }
  
}
  
