import processing.core.*; 
import processing.xml.*; 

import SimpleOpenNI.*; 
import rwmidi.*; 
import oscP5.*; 
import netP5.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class MappiNect extends PApplet {

/* --------------------------------------------------------------------------
 * SimpleOpenNI User Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  02/16/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 */







SimpleOpenNI  context;

MidiOutputDevice[] devices;
MidiOutput output;

OscP5 oscP5;
NetAddress oscRemoteHost;

Boolean showInfos;
Boolean sendMappings;
Boolean showFeedback;
Boolean showMidiDevices;
Boolean showHandsCoords;


//PARAMS
int midiOutDeviceID;

int oscDefaultInPort;
int oscDefaultOutPort;
String oscDefaultHost;
String oscAddressPrefix;

String defaultMappingFile;


String[] jointsToken = {
  "head", "neck", "left_shoulder", "right_shoulder", "torso", "left_elbow", "right_elbow", "left_hand", "right_hand",
  "left_hip","right_hip","left_knee","right_knee","left_foot","right_foot","profile_all"
};

int[] jointsConstants;
int jointsNum;
int numUsers;
int[] trackedUsers;

MappingManager manager;

public void setup()
{
  background(0, 0, 0);

  stroke(0, 0, 255);
  strokeWeight(3);
  smooth();
  
  devices =  RWMidi.getOutputDevices();
  
  readSettings();

  context = new SimpleOpenNI(this);

  // enable depthMap generation
  //context.enableRGB();
  context.enableScene();
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);

  //ugly hacks because {...} only works for local variables
  int[] tmpjointsConstants = {
    SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_SHOULDER, 
    SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_RIGHT_ELBOW, 
    SimpleOpenNI.SKEL_LEFT_HAND, SimpleOpenNI.SKEL_RIGHT_HAND,
    SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_RIGHT_KNEE,
    SimpleOpenNI.SKEL_LEFT_FOOT, SimpleOpenNI.SKEL_RIGHT_FOOT,SimpleOpenNI.SKEL_PROFILE_ALL
  };
  
  jointsConstants = tmpjointsConstants;

  jointsNum = jointsConstants.length;

  size(context.depthWidth(), context.depthHeight()); 

  
  manager = new MappingManager(this);
  manager.readFile(defaultMappingFile);
  
  textMode(SCREEN);
}

public void readSettings()
{
  XMLElement config = new XMLElement(this,"config.xml");
  
  XMLElement midiConfig = config.getChild("midi");
  setMidiOutDevice(midiConfig.getInt("outDeviceID"));
  
  XMLElement oscConfig = config.getChild("osc");
  oscDefaultInPort = oscConfig.getInt("inPort",4000);
  oscDefaultOutPort = oscConfig.getInt("outPort",4444);
  oscDefaultHost = oscConfig.getString("host","127.0.0.1");
  oscAddressPrefix = oscConfig.getString("addressPrefix","");
  oscP5 = new OscP5(this,oscDefaultInPort);
  oscRemoteHost = new NetAddress(oscDefaultHost,oscDefaultOutPort);
  
   
  
  println("Settings loaded :");
  println(" -> midiOutputDeviceID :"+midiOutDeviceID);
  println(" -> oscDefaultInPort :"+oscDefaultInPort);
  println(" -> oscDefaultOutPort :"+oscDefaultOutPort);
  println(" -> oscDefaultHost :"+oscDefaultHost);
  println(" -> oscAddressPrefix :"+oscAddressPrefix);
  
  XMLElement startupConfig = config.getChild("startup");
  showInfos = PApplet.parseBoolean(startupConfig.getString("showInfos","true"));
  sendMappings = PApplet.parseBoolean(startupConfig.getString("showInfos","true"));
  showFeedback = PApplet.parseBoolean(startupConfig.getString("showFeedback","true"));
  showMidiDevices = PApplet.parseBoolean(startupConfig.getString("showMidiDevices","true"));
  showHandsCoords = PApplet.parseBoolean(startupConfig.getString("showHandsCoords","true"));
  defaultMappingFile = startupConfig.getString("defaultMappingFile","mappings.xml");
  
  XMLElement kinectConfig = config.getChild("kinect");
  XMLElement openNIConfig = config.getChild("openNI");
}

public void draw()
{

  background(0);
  
  // update the cam
  context.update();
  context.setMirror(true);
  context.alternativeViewPointDepthToImage();
  // draw depthImageMap
  image(context.depthImage(),0,0);
  //image(context.rgbImage(), 0, 0);
  //blend(context.sceneImage(),0,0,width,height,0,0,width,height,ADD);

  // draw the skeleton if it's available
  getValidUsers();
  
  if (numUsers > 0) {
    stroke(12,130,240,130);
    fill(0,100);
    rect(0,0,width,height);
    for(int i=0;i<numUsers;i++){
      //print("track user :"+i);
      drawSkeleton(trackedUsers[i]);
    }
    rect(0,0,width,height);
    if (sendMappings && output != null) manager.processMappings(showFeedback);
    
  }
  
  if (showInfos) showInfos();
  
}

public void getValidUsers()
{
  int totalUsers = 2;//context.getNumberOfUsers();
  
  trackedUsers = new int[0];
  
  for(int i=1;i<=totalUsers;i++){
    if(context.isTrackingSkeleton(i)){
      trackedUsers = append(trackedUsers,i);
    }
  }
  
  numUsers = trackedUsers.length;
}

public void showInfos() {
  pushStyle();
  textMode(MODEL);
  noStroke();
  fill(0, 100);
  rect(0, 0, width, 100);
  fill(255);
  text("sendMappings : "+sendMappings+" (hit spacebar to toggle)", 10, 10, 300, 20);
  text("showFeedback : "+showFeedback+" (hit 'f' to hide feedbacks)", 10, 30, 300, 20);
  
 
  
  if(showHandsCoords)
  {
    PVector leftHand = getJoint(1, SimpleOpenNI.SKEL_LEFT_HAND);
    text("Left Hand => x : "+PApplet.parseInt(leftHand.x)+", y : "+PApplet.parseInt(leftHand.y)+", z : "+PApplet.parseInt(leftHand.z)+" (hit 'h' to hide)",10,60,350,20);
    PVector rightHand = getJoint(1, SimpleOpenNI.SKEL_RIGHT_HAND);
    text("Right Hand => x : "+PApplet.parseInt(rightHand.x)+", y : "+PApplet.parseInt(rightHand.y)+", z : "+PApplet.parseInt(rightHand.z)+" (hit 'h' to hide)",10,80,350,20);
  }
  
  pushStyle();
  textAlign(RIGHT);
  text("Active Mappings : "+manager.numMappings,width-310,10,300,20);
  text("Active Users : "+numUsers,width-310,30,300,20);
  text("Current Set : "+manager.currentFile+" -> "+manager.currentSetId,width-310,50,300,50);

  text("-- hit 'i' to hide all infos --", width-310, 80, 300, 20);
  popStyle();
  
  if(showMidiDevices)
  {
    fill(0,100);
    rect(0,200,200,devices.length*20+30);
    fill(255);
    text("MIDI Devices (hit 'd' to hide) :",10,210,200,20);
    for(int i=0;i<devices.length;i++)
    {
      if(i == midiOutDeviceID)
      {
        pushStyle();
        if(output != null){
          fill(120,255,30);
        }else{
          fill(255,50,30);
        }
      }
      
      text(i+" : "+devices[i],10,230+20*i,200,20);
      
      if(i == midiOutDeviceID)
      {
        popStyle();
      }
    }
    
  }
  try
  {
    popStyle();
  } catch(Error e)
  {
    println("Too fast for processing !");
  }finally
  {
    
  }
}

public void setMidiOutDevice(int deviceID)
{
  midiOutDeviceID = deviceID;
  output = devices[midiOutDeviceID].createOutput();
}

public void keyPressed(KeyEvent e)
{
  switch(e.getKeyChar()) {
  case ' ':
    sendMappings = !sendMappings;
    break;
    
  case 'f':
    showFeedback = !showFeedback;
    break;
    
  case 'i':
    showInfos = !showInfos;
    break;
  
  case 'h':
    showHandsCoords = !showHandsCoords;
    break;
    
  case 'd':
    showMidiDevices = !showMidiDevices;
    break;
  
  case 'r':
    manager.readSet(manager.currentSetIndex);
    break;

    
  case 'n':
    manager.readNextSet();
    break;
  
  case '+':
    setMidiOutDevice((midiOutDeviceID + 1) % devices.length);
    break;
  
  case '-':
    setMidiOutDevice(+(midiOutDeviceID - 1 + devices.length) % devices.length);
    break;
  
  default:
    println("keyChar :"+e.getKeyChar());
    manager.keyPressed(e.getKeyChar());
    break;
  }
  
  if(e.getKeyCode() >= 96 && e.getKeyCode() <= 105){
    output.sendController(0,e.getKeyCode()-96,50);
  }
}






public interface IMappingOutput
{
 public void send(float[] values);
}
public interface IRawValueProvider
{
  public float getRawValue();
  public PVector getRawVector();
  public int getAxis();
}
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

class MappingDMXOutput implements IMappingOutput
{
  public MappingDMXOutput()
  {
   println("New DMX Output : not implemented yet");
  }
  
  public void send(float[] values)
  {
    //print("dmx not implemented yet");
  }
  
}
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

class MappingFeedback{

  Mapping mapping;
  
  float value;
  PVector[] screenVecs;
  
  int mode;
  String label;
  Boolean showLabel;
  int labelNumLines;
  
  Boolean isActive = true;
  
  Boolean isBoolean = false;
  int effect;
  
  int triggerFade;
  
  int bgColor;
  int baseColor  = color(12,133,217);
  int activeBGColor = color(30,30,30);
  int inactiveBGColor = color(220,17,50);
  int triggerColor = color(180,220,17);
  
  public MappingFeedback(Mapping _mapping)
  {
    this.mapping = _mapping;
    screenVecs = new PVector[2];
    triggerFade = 255;
  }
  
  public void draw(Boolean _isActive)
  {
    this.isActive = _isActive;
    bgColor = isActive?activeBGColor:inactiveBGColor;
    if(value > 0) triggerFade = 255;
     
    pushMatrix();
    pushStyle();
     switch(mode){
      case Tokens.CIRCLE_X:
      case Tokens.CIRCLE_Y:
      case Tokens.CIRCLE_Z:
        if(isBoolean){
          drawBooleanFeedback(screenVecs[0]);
          break;
        }
        drawSingleFeedback(screenVecs[0]);
        break;
        
      case Tokens.LINE_DISTANCE:
      case Tokens.CIRCLE_ROTATION:
        draw2VecsFeedback(screenVecs[0],screenVecs[1]);
        break;
        
      default:
        println("Feedback draw, mode not handled :"+mode);
        break;
    }
    popStyle();
    popMatrix();
    
    if(effect == Tokens.TRIGGER){
      if(triggerFade > 0)triggerFade -= 40;
      if(triggerFade < 0) triggerFade = 0;
    }
  }

  public void draw2VecsFeedback(PVector v1, PVector v2)
  {
    strokeWeight(3);
    
    stroke(map(value,0,1,30,12),map(value,0,1,30,133),map(value,0,1,30,217));
    PVector centerVec = new PVector((v1.x + v2.x) / 2,(v1.y + v2.y) / 2);
    
    line(v1.x,v1.y,v2.x,v2.y);

    float angle = -atan2(v2.x - v1.x, v2.y - v1.y) + PI/2;
    translate(centerVec.x,centerVec.y);
    
    float distance = dist(v1.x,v1.y,v2.x,v2.y);
    
    switch(mode){
      case Tokens.LINE_DISTANCE:
        rotate(angle);
        drawRectValueFeedback(80,20);
        
        createOffsetLabel(30);
        break;
        
      case Tokens.CIRCLE_ROTATION:
        strokeWeight(6);
        strokeCap(SQUARE); 
        stroke(bgColor);
        fill(bgColor,50);
        drawValueFullArc(1,distance/2);
        fill(baseColor,50);
        stroke(baseColor);
        drawValueFullArc(value,distance/2);
        print("rotation :"+value);
        createOffsetLabel(10);
        break;
        
    }
    
    
  }
  
  public void drawBooleanFeedback(PVector vec)
  {
    
    int radius = (effect == Tokens.TRIGGER)?80:120;
    translate(vec.x,vec.y);
    rotateForIndex(mode);
    
    createArcLabel(radius-20);
    
    noFill();
    strokeCap(SQUARE); 
    
    strokeWeight(8);
    
    stroke(bgColor);
    drawValueAxisArc(1, radius);
    
    if(value > 0 || effect == Tokens.TRIGGER){
      stroke(triggerColor,triggerFade);
      drawValueAxisArc(1, radius);
    }
    
  }
  
  
  public void drawValueAxisArc(float val, float radius){
    drawValueArc(val, radius,TWO_PI / 3,TWO_PI / 10);
  }
  
  public void drawValueFullArc(float val, float radius){
    drawValueArc(val, radius,TWO_PI,0);
  }
  
  public void drawValueArc(float val, float diameter,float arcLength, float gap)
  {
    arc(0,0, diameter, diameter, 0,val * arcLength-gap);
  }
  
  public void drawRectValueFeedback(int w,int h)
  {  
    pushStyle();
    noStroke();
    fill(bgColor);
    rect(-w/2 ,-h/2, w,h);
    
    float rectValue = value;
    if(isBoolean){
      fill(triggerColor,triggerFade);
      if(effect == Tokens.TRIGGER){
        rectValue = 1;
      }
    }else{
      fill(12,133,217);
    }
    
    rect(-w/2,-h/2,w*rectValue,h);
    
    popStyle();
  }
  
  public void drawSingleFeedback(PVector vec)
  { 
    translate(vec.x,vec.y);
    rotateForIndex(mode);
    
    createArcLabel(40);
    
    noFill();
    strokeCap(SQUARE);
    
    strokeWeight(8);
    stroke(bgColor);
    drawValueAxisArc(1, 30);
    stroke(baseColor);
    drawValueAxisArc(value, 30);    
    
  }
  
  
  public void rotateForIndex(int index)
  {
    rotate(-PI+PI/4);
    rotate(index*TWO_PI/3);
  }
  
  public void createArcLabel(int offset)
  {
    pushMatrix();
      rotate(PI-PI/3+PI/10);
      createOffsetLabel(offset);
    popMatrix();
  }
  
  public void createOffsetLabel(int offset)
  {
    pushMatrix();
      translate(0,-offset);
      createLabel();
    popMatrix();
  }
  
  public void createLabel()
  {
    if(!showLabel) return;
    textMode(MODEL);
    rectMode(CENTER);
    textAlign(CENTER,BOTTOM);
    
    fill(255,255,255);
    text(label,0,0,80,40);
    
    textAlign(LEFT,TOP);
    rectMode(CORNER);
    textMode(SCREEN);
  }
}
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
    
    int targetDevice = (deviceMap > 0 && deviceMap <= numValues)?PApplet.parseInt(map(values[deviceMap-1],0,1,0,127)):device;
    int targetChannel = (channelMap > 0 && channelMap <= numValues)?PApplet.parseInt(map(values[channelMap-1],0,1,minChannel,maxChannel)):channel;
    int targetVelocity = (velocityMap > 0 && velocityMap <= numValues)?PApplet.parseInt(map(values[velocityMap-1],0,1,minVelocity,maxVelocity)):velocity;
    
   
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
    
    xml = new XMLElement(parent, file);
    
    
    XMLElement xmlSet = xml.getChild(setIndex);
    
    totalSets = xml.getChildCount();
    
    shortcuts = getSetsShortcuts(xml);
    
    if(!PApplet.parseBoolean(xmlSet.getString("inScope","true")))
    {
      println("Loaded set is not inScope, loading next set");
      readNextSet();
      return;
    }
    
    mappings = new Mapping[0];
    
    readPermanentSets();
    currentSetId = xmlSet.getString("id","no id");
    if(!PApplet.parseBoolean(xmlSet.getString("permanent","false"))) processSet(xmlSet);
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
      if(PApplet.parseBoolean(xmlSet.getString("permanent","false"))){
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

  public MappingProcessor readXMLProcessor(XMLElement xmlProc, MappingProcessor parentProcessor) {
    
    String id = xmlProc.getString("id","");
    String label = xmlProc.getString("label","");
    Boolean showFeedback = PApplet.parseBoolean(xmlProc.getString("showFeedback","true"));
    Boolean labelFeedback = PApplet.parseBoolean(xmlProc.getString("labelFeedback","true"));
    
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

  public MappingElement readXMLElement(XMLElement xmlElem, MappingProcessor parentProcessor) {
    String elemType = xmlElem.getString("type");
    String elemTarget = xmlElem.getString("target");
    String elemProperty = xmlElem.getString("property", "position");
    
    String parentAxis = Tokens.axisToken[parentProcessor.axis];
    String elemAxis = xmlElem.getString("axis", ((parentProcessor != null)?parentAxis:"x"));
    
    int elemValue = xmlElem.getInt("value", 0);
    PVector position = new PVector(xmlElem.getInt("x", 0),xmlElem.getInt("y", 0),xmlElem.getInt("z", 0));
    return new MappingElement(elemType, elemTarget, elemProperty, elemAxis, elemValue,position);
  }
  
  
  public IMappingOutput[] readXMLOutputs(XMLElement xmlOutputs)
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
        
        Boolean midiDistinctNotes = PApplet.parseBoolean(xmlOutput.getString("distinctNotes","true"));
        
        output = new MappingMIDIOutput(midiType, midiDevice,midiChannel,midiVelocity,midiDeviceMap,midiChannelMap,midiVelocityMap,
                                        midiMinChannel,midiMaxChannel,midiMinVelocity,midiMaxVelocity,midiDistinctNotes);
        
      }else if(outputType.equals("osc")){
        String oscHost = xmlOutput.getString("host",oscDefaultHost);
        String oscAddress = xmlOutput.getString("address","");
        int oscPort = xmlOutput.getInt("port",oscDefaultOutPort);
        output = new MappingOSCOutput(oscHost,oscPort,oscAddressPrefix+oscAddress);
      }else if(outputType.equals("dmx")){
        output = new MappingDMXOutput();
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

class MappingOSCOutput implements IMappingOutput
{
  public String address;
  
  public MappingOSCOutput(String _host, int _port, String _address)
  {
    this.address = _address;
    println(" > New OSC Output : address :"+address);
  }
  
  public void send(float[] values)
  {
    //println("OSC Output not sending anything yet");
    OscMessage msg = new OscMessage(address);
    int numValues = values.length;
    for(int i=0;i<numValues;i++){
      msg.add(values[i]); /* add an int to the osc message */
    }
  
    /* send the message */
    oscP5.send(msg, oscRemoteHost); 
  }
  
}
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
        break;
        
      default:
        print("## MappingProcessor => overflow not handled : "+overflow);
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
         println("*** Feedback vector "+vectors[i]);
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
  }
 
}

public int getJointIdForToken(String tokenId)
{
  for (int i=0;i<jointsNum;i++)
  {
    if (jointsToken[i].equals(tokenId )) {
      return jointsConstants[i];
    }
  }

  println("Token "+tokenId+" doesn't exists in OpenNI Skeleton");
  return 0;
}

public PVector getJoint(int userId, int jointId)
{
  PVector joint = new PVector();
  context.getJointPositionSkeleton(userId, jointId, joint);
  return joint;
}

public float getJointValue(int userId, int jointId, int axis)
{
  PVector joint = getJoint(userId, jointId);
  switch(axis){
    case Tokens.X:
      return joint.x;
      
    case Tokens.Y:
      return joint.y;
      
    case Tokens.Z:
      return joint.z;
  }

  print("## Skeleton => Coord not handled : "+axis);

  return 0;
}


//OPENNI Process & Feedback

// draw the skeleton with the selected joints
public void drawSkeleton(int userId)
{
  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
   context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
   println(jointPos);
   */

  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
}

// -----------------------------------------------------------------
// SimpleOpenNI events

public void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  println("  start pose detection");

  context.startPoseDetection("Psi", userId);
}

public void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

public void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

public void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);

  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId);
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi", userId);
  }
}

public void onStartPose(String pose, int userId)
{
  println("onStartPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");

  context.stopPoseDetection(userId); 
  context.requestCalibrationSkeleton(userId, true);
}

public void onEndPose(String pose, int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}

static public class Tokens
{
  
  //MAPPING
  public final static int NOTE = 0;
  public final static int CONTROLLER = 1;
  
  static final String[] midiTypesToken = {"note","controller"};
  //PROCESSOR
  
  static final int NONE = 0; //For multiple use
  
  static final int DIRECT = 0;
  static final int MAPPED= 1;
  static final int DISTANCE = 2;
  static final int ROTATION = 3;
  static final int BOOLEAN = 4;
  static final int CONDITIONNAL = 5;
  static final int FILTERED = 6;
  static final int ACTION = 7;
  static final int MULTI = 8;
  
  static final int LESS_THAN = 1;
  static final int GREATER_THAN = 2;
  static final int BETWEEN = 3;
  static final int LOWEST = 4;
  static final int GREATEST = 5;
  static final int AVERAGE = 6;
  static final int GATE = 7;
  
  static final int AND = 0;
  static final int OR = 1;
  
  
  static final int ZERO = 1; //Also used in InactiveTokens.
  static final int CLIP = 2;
  static final int LOOP = 3;
  
  
  
  static final int TRIGGER = 1;
  static final int TOGGLE = 2;
  
  static final int CHANGE_SET = 1;
  static final int NEXT_SET = 2;
  static final int PREV_SET = 3;
  
  static final int KEEP_VALUE = 0;
  static final int STANDBY = 2;
  
  static final String[] processorTypesToken = {"direct","mapped","distance","rotation","boolean","conditionnal","filtered","action","multi"};
  static final String[] processorFiltersToken = {"none","less_than","greater_than","between","lowest","greatest","average","gate"};
  static final String[] processorOperatorsToken = {"and","or"};
  static final String[] processorOverflowsToken = {"none","zero","clip","loop"};
  static final String[] processorEffectsToken = {"none","trigger","toggle"}; 
  static final String[] processorActionsToken = {"none","changeSet","nextSet", "prevSet"};
  static final String[] processorInactiveToken = {"keepValue","zero","standby"};
  
  //ELEMENT
  
  static final int JOINT = 0;
  static final int POINT = 1;
  static final int VALUE = 2;
  
  static final int POSITION = 0;
  static final int VELOCITY = 1;
  static final int ACCELERATION=  2;
  
  static final int X = 0;
  static final int Y = 1;
  static final int Z = 2;
  static final int XY = 3;
  static final int XZ = 4;
  static final int YZ = 5;
  static final int VECTOR3D = 6;
  
  static final String[] mappingElementTypesToken = {"joint","point","value"};
  static final String[] propertiesToken = {"position","velocity","acceleration"};
  static final String[] axisToken = {"x","y","z","xy","xz","yz","3d"};
  
  
  // FEEDBACK
  static final int NO_FEEDBACK = -1;
  static final int CIRCLE_X = 0; //SAME AS X for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_Y = 1; //SAME AS Y for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_Z = 2; //SAME AS Z for direct mapping in MappingProcessor:getFeedbackMode();
  static final int CIRCLE_ROTATION = 3;
  static final int LINE_DISTANCE = 4;
  
  
  //MIDI OUTPUT
  public final static int SINGLE = 0;
  public final static int DOUBLE = 1;
  public final static int TRIPLE = 2;
  
  
  
  public static int getIndexForToken(String[] tokenArray, String token)
  {
    for (int i=0;i<tokenArray.length;i++)
    {
      if (tokenArray[i].equals(token)) {
        return i;
      }
    }
    
     println("### token "+token +" not found");
     return 0;
     
  }

}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#F0F0F0", "MappiNect" });
  }
}
