public class MappingManager
{
  PApplet parent;
  Mapping[] mappings;
  public int numMappings;
  
  public String currentFile;
  public int currentSetIndex;
  String currentSetId; //For feedback only
  int totalSets;
  char[] shortcuts;
  
  XMLElement xml;
  
  public MappingManager(PApplet _parent)
  {
    this.parent = _parent;
    currentFile = "mappings.xml";
  }
  
  public void readFile(String file)
  {
    readSet(file, 0);
  }
  
  public void readSet(String setId)
  {
    readSet(currentFile,setId);
  }
  
  public void readSet(int setIndex)
  {
    readSet(currentFile,setIndex);
  }
  
  public void readSet(String file, String setId)
  {
     if(file.equals("")) file = currentFile;
     println("MappingManager, readSet (setId) : "+file+"/"+setId);
     xml = new XMLElement(parent, file);
     totalSets = xml.getChildCount();
     
     int targetSet = 0;
     for(int i=0;i<totalSets;i++){
       XMLElement xmlSet = xml.getChild(i);
       if(xmlSet.getString("id","none").equals(setId)){
         targetSet = i;
         break;
       }
     }
     
     readSet(targetSet);
  }
  
  public void readSet(String file, int setIndex)
  {
    println("Read set "+setIndex+" in file "+file);
    this.currentSetIndex = setIndex;
    
    if(file.equals("")){
      file = currentFile;
    }else if (!file.equals(currentFile) || xml == null){
      this.currentFile = file;
    }
    
    File f = new File(dataPath(file));
    if (!f.exists()) {
      text("mapping file  not found : "+file,10,10,400,20);
      criticalStop = true;
      return;
   } 
  
    xml = new XMLElement(parent, file);
    
    
    XMLElement xmlSet = xml.getChild(setIndex);
    
    totalSets = xml.getChildCount();
    
    shortcuts = getSetsShortcuts(xml);
    
    if(!boolean(xmlSet.getString("inScope","true")))
    {
      println("Loaded set is not inScope, loading next set");
      readNextSet();
      return;
    }
    
    mappings = new Mapping[0];
    
    readPermanentSets();
    currentSetId = xmlSet.getString("id","no id");
    if(!boolean(xmlSet.getString("permanent","false"))) processSet(xmlSet);
  }
  
  public void processSet(XMLElement setXML)
  {
    int numSetMappings = setXML.getChildCount();
    Mapping[] setMappings = new Mapping[numSetMappings];
    

    for (int i = 0; i < numSetMappings; i++) {
      
      XMLElement xmlMapping = setXML.getChild(i);
      
      String id = xmlMapping.getString("id", "");
      String label = xmlMapping.getString("label", "");
      
      MappingProcessor mProcessor = readXMLProcessor(xmlMapping.getChild("processor"),null);
      IMappingOutput[] mOutputs = readXMLOutputs(xmlMapping.getChild("output"));
      
      Mapping m = new Mapping(id, label, mProcessor, mOutputs);
      
      setMappings[i] = m;
    }
    
    mappings = (Mapping[])concat(mappings,setMappings);
    numMappings = mappings.length;
    println("----------- MappingManager, processSet on "+setXML.getName()+": found "+numMappings+" mappings ---------------");
  }
  
  public void readPermanentSets()
  {
    println("---- Begin Read Permanent Sets --------");
    int permanents = 0;
    for(int i=0;i<totalSets;i++){
      XMLElement xmlSet = xml.getChild(i);
      if(boolean(xmlSet.getString("permanent","false"))){
        processSet(xmlSet);
        permanents++;
      }
    
    }
    println("---- End Read Permenent Sets, total Permanent Sets : "+permanents+"----------");
  }
  
  public void readNextSet()
  {
   
    readSet((currentSetIndex+1)%totalSets);
  }
  
   public void readPrevSet()
  {
     print("readNextSet "+(currentSetIndex-1)%totalSets);
    readSet((currentSetIndex-1+totalSets)%totalSets);
  }
  
  public char[] getSetsShortcuts(XMLElement xml)
  {
    int numShortcuts = 0;
    char[] sc = new char[totalSets];
    for(int i=0;i<totalSets;i++){
      XMLElement xmlSet = xml.getChild(i);
      sc[i] = xmlSet.getString("shortcut"," ").charAt(0);
      if(sc[i] != ' '){
        numShortcuts++;
      }
    }
    
    println(" * getShortcuts on "+xml.getName()+", found "+numShortcuts+" shortcuts in "+totalSets+" sets");
    
    return sc;
  }

  MappingProcessor readXMLProcessor(XMLElement xmlProc, MappingProcessor parentProcessor) {
    
    String id = xmlProc.getString("id","");
    String label = xmlProc.getString("label","");
    Boolean showFeedback = boolean(xmlProc.getString("showFeedback","true"));
    Boolean labelFeedback = boolean(xmlProc.getString("labelFeedback","true"));
    
    String type = xmlProc.getString("type");
    String filter = xmlProc.getString("filter", "none");
    String effect = xmlProc.getString("effect","none");
    String operator = xmlProc.getString("operator","and");
    int minValue = xmlProc.getInt("minValue",-5555);
    int maxValue = xmlProc.getInt("maxValue",-5555);
    String overflow = xmlProc.getString("overflow", "clip");
    
    String action = xmlProc.getString("action", "none");
    String file = xmlProc.getString("file", "");
    String setId = xmlProc.getString("setId", "");
    
    String inactive = xmlProc.getString("inactive","null");
    
    
    String parentAxis = (parentProcessor != null)?Tokens.axisToken[parentProcessor.axis]:"x";
    String axis = xmlProc.getString("axis",parentAxis);
    
    MappingProcessor p = new MappingProcessor(id, label,showFeedback, labelFeedback, type, filter, operator, overflow,effect, axis, action, inactive);
    
    if(minValue != -5555){
      p.minValue = minValue;
    }
    if(maxValue != -5555){
      p.maxValue = maxValue;
    }
    
    if(p.action != Tokens.NONE){
      p.file = file;
      p.setId = setId;
    }

    int numChildren = xmlProc.getChildCount();
    println("Processor numChildren :"+numChildren);
    if(xmlProc.getChild(0).getName().equals("element")){
      MappingElement[] elems = new MappingElement[numChildren];
    
      for (int i = 0; i < numChildren; i++) {
        elems[i] = readXMLElement(xmlProc.getChild(i), p);
      }
      p.elements = elems;
      p.setGroup(false); // Set to false to ensure processor take the elements[] for reference in the providers[]
    }else if(xmlProc.getChild(0).getName().equals("processor")){
      println(" * -> Processor is Group");
      MappingProcessor[] procs = new MappingProcessor[numChildren];
   
      for (int i = 0; i < numChildren; i++) {
        procs[i] = readXMLProcessor(xmlProc.getChild(i), p);
      }
      p.processors = procs;
      p.setGroup(true);
      
      
    }
   
    return p;
  }

  MappingElement readXMLElement(XMLElement xmlElem, MappingProcessor parentProcessor) {
    String elemType = xmlElem.getString("type");
    int elemUserId = xmlElem.getInt("userId",0);
    String elemTarget = xmlElem.getString("target");
    String elemProperty = xmlElem.getString("property", "position");
    
    String parentAxis = Tokens.axisToken[parentProcessor.axis];
    String elemAxis = xmlElem.getString("axis", ((parentProcessor != null)?parentAxis:"x"));
    
    int elemValue = xmlElem.getInt("value", 0);
    PVector position = new PVector(xmlElem.getInt("x", 0),xmlElem.getInt("y", 0),xmlElem.getInt("z", 0));
    return new MappingElement(elemType, elemUserId, elemTarget, elemProperty, elemAxis, elemValue,position);
  }
  
  
  IMappingOutput[] readXMLOutputs(XMLElement xmlOutputs)
  {
    int numOutputs = xmlOutputs.getChildCount();
    IMappingOutput[] outputs = new IMappingOutput[numOutputs];
    for(int i=0;i<numOutputs;i++){
      XMLElement xmlOutput = xmlOutputs.getChild(i); 
      String outputType = xmlOutput.getName();
      IMappingOutput output;
      if(outputType.equals("midi")){
        String midiType = xmlOutput.getString("type","controller");
        int midiDevice = xmlOutput.getInt("device",0);
        int midiChannel = xmlOutput.getInt("channel",1);
        int midiVelocity = xmlOutput.getInt("velocity",0);
        int midiDeviceMap = xmlOutput.getInt("deviceMap",0);
        int midiChannelMap = xmlOutput.getInt("channelMap",0);
        int midiVelocityMap = xmlOutput.getInt("velocityMap",1);
        int midiMinChannel = xmlOutput.getInt("minChannel",0);
        int midiMaxChannel = xmlOutput.getInt("maxChannel",127);
        int midiMinVelocity = xmlOutput.getInt("minVelocity",0);
        int midiMaxVelocity = xmlOutput.getInt("maxVelocity",127);
        
        Boolean midiDistinctNotes = boolean(xmlOutput.getString("distinctNotes","true"));
        
        output = new MappingMIDIOutput(midiType, midiDevice,midiChannel,midiVelocity,midiDeviceMap,midiChannelMap,midiVelocityMap,
                                        midiMinChannel,midiMaxChannel,midiMinVelocity,midiMaxVelocity,midiDistinctNotes);
        
      }else if(outputType.equals("osc")){
        String oscHost = xmlOutput.getString("host",oscDefaultHost);
        String oscAddress = xmlOutput.getString("address","");
        int oscPort = xmlOutput.getInt("port",oscDefaultOutPort);
        output = new MappingOSCOutput(oscHost,oscPort,oscAddressPrefix+oscAddress);
        
      }else if(outputType.equals("dmx")){
        int startChannel = xmlOutput.getInt("startChannel",1);
        int minOut = xmlOutput.getInt("minOut",0);
        int maxOut = xmlOutput.getInt("maxOut",255);
        output = new MappingDMXOutput(startChannel, minOut, maxOut);
        
      }else{
        output = null;
      }
      
      outputs[i] = output;
    }
    
    return outputs;
  }

  public void processMappings(Boolean drawFeedback)
  {
    float[] values;;
    numMappings = mappings.length;
    for (int i = 0; i < numMappings; i++) {
      
       values = mappings[i].getNormalizedValues();
       
       MappingProcessor processor = mappings[i].processor;
       
       if(processor.type == Tokens.ACTION){
         if(values[0] == 1){
           //println("ACTION TRIGGER, action : "+processor.action+", file :"+processor.file+", setId :"+processor.setId);
           
           switch(processor.action)
           {
             case Tokens.CHANGE_SET:
               readSet(processor.file,processor.setId);
               return;
             
             case Tokens.NEXT_SET:
               readNextSet();
               return;
               
             case Tokens.PREV_SET:
               readPrevSet();
               return;
           }
         }
       }else{
         mappings[i].send(values);
         if(drawFeedback) mappings[i].drawFeedback();
       }
    } 
  }
  
  public void keyPressed(char keyChar)
  {
    if(keyChar == ' ') return;
    int numShortcuts = shortcuts.length;
    for(int i=0;i<numShortcuts;i++){
      if(shortcuts[i] == keyChar){
        println("found shortcut : "+keyChar+" -> setIndex to "+i);
        readSet(i);
        break;
      }
      
    }
  }
}

