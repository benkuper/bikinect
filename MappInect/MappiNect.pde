

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

import SimpleOpenNI.*;
import rwmidi.*;
import dmxP512.*;
import processing.serial.*;

import oscP5.*;
import netP5.*;

SimpleOpenNI  context;

MidiOutputDevice[] devices;
MidiOutput output;

OscP5 oscP5;
NetAddress oscRemoteHost;

DmxP512 dmxOutput;

Boolean criticalStop;

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

void setup()
{
  background(0, 0, 0);
  
  stroke(0, 0, 255);
  strokeWeight(3);
  smooth();
  
  
  
  readSettings();
  
  context = new SimpleOpenNI(this);
  if(context.enableDepth() == false)
  {
     text("Can't open the depthMap, maybe the camera is not connected!",10,10,200,100);
     size(220,120); 
     criticalStop = true;
  }
  
   if(context.enableScene() == false)
  {
     text("Can't open the sceneMap, maybe the camera is not connected!"); 
     criticalStop = true;
  }
  
  if(criticalStop)
  {
    return;
  }
  
  

  // enable depthMap generation
  //context.enableRGB();
<<<<<<< .mine
 
  
 
=======
  if(context.enableDepth() == false)
  {
    size(300,60);
    text("Can't open the depthMap, maybe the camera is not connected!",10,10,280,40);
    println("Can't open the depthMap, maybe the camera is not connected!");
    criticalStop = true;
    return;
  }
  
  context.enableScene();
>>>>>>> .r41

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
 
  if(context.depthWidth() == 0)
  {
    size(300,40);
    text("Can't get the camera width / height, please make sure it's connected and working",10,10,300,20);
    println("Can't get the camera width / height, please make sure it's connected and working");
    criticalStop = true;
    return;
  }
  
  size(context.depthWidth(), context.depthHeight()); 

  
  manager = new MappingManager(this);
  manager.readFile(defaultMappingFile);
  
  textMode(SCREEN);
}

void readSettings()
{
  criticalStop = false;
  
  File f = new File(dataPath("config.xml"));
  
  if (!f.exists()) {
    size(300,40);
    text("config.xml not found in data folder.",10,10,300,20);
    criticalStop = true;
    return;
  } 

  XMLElement config = new XMLElement(this,"config.xml");
  
  XMLElement midiConfig = config.getChild("midi");
  if(boolean(midiConfig.getString("active")))
  {
    devices =  RWMidi.getOutputDevices();
    setMidiOutDevice(midiConfig.getInt("outDeviceID"));
  }
  
  
  XMLElement oscConfig = config.getChild("osc");
  if(boolean(oscConfig.getString("active")))
  {
    oscDefaultInPort = oscConfig.getInt("inPort",4000);
    oscDefaultOutPort = oscConfig.getInt("outPort",4444);
    oscDefaultHost = oscConfig.getString("host","127.0.0.1");
    oscAddressPrefix = oscConfig.getString("addressPrefix","");
    oscP5 = new OscP5(this,oscDefaultInPort);
    oscRemoteHost = new NetAddress(oscDefaultHost,oscDefaultOutPort);
  }
  
  XMLElement dmxConfig = config.getChild("dmx");
  if(boolean(dmxConfig.getString("active")))
  {
    dmxOutput = new DmxP512(this,dmxConfig.getInt("numChannels",512),false);
    String dmxHardware = dmxConfig.getString("hardware");
    if(dmxHardware.equals("dmxpro"))
    {
      String dmxPort = dmxConfig.getString("port");
      int dmxBaudrate = dmxConfig.getInt("baudrate");
      dmxOutput.setupDmxPro(dmxPort, dmxBaudrate);
    }
  }
  
  println("Settings loaded :");
  println(" -> midiOutputDeviceID :"+midiOutDeviceID);
  println(" -> oscDefaultInPort :"+oscDefaultInPort);
  println(" -> oscDefaultOutPort :"+oscDefaultOutPort);
  println(" -> oscDefaultHost :"+oscDefaultHost);
  println(" -> oscAddressPrefix :"+oscAddressPrefix);
  
  XMLElement startupConfig = config.getChild("startup");
  showInfos = boolean(startupConfig.getString("showInfos","true"));
  sendMappings = boolean(startupConfig.getString("showInfos","true"));
  showFeedback = boolean(startupConfig.getString("showFeedback","true"));
  showMidiDevices = boolean(startupConfig.getString("showMidiDevices","true"));
  showHandsCoords = boolean(startupConfig.getString("showHandsCoords","true"));
  defaultMappingFile = startupConfig.getString("defaultMappingFile","mappings.xml");
  
  XMLElement kinectConfig = config.getChild("kinect");
  XMLElement openNIConfig = config.getChild("openNI");
}

void draw()
{
  if(criticalStop) return;
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

void getValidUsers()
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

void showInfos() {
  pushStyle();
  textMode(MODEL);
  noStroke();
  fill(0, 100);
  rect(0, 0, width, 100);
  fill(255);
  text("sendMappings : "+sendMappings+" (hit spacebar to toggle)", 10, 10, 300, 20);
  text("showFeedback : "+showFeedback+" (hit 'f' to hide feedbacks)", 10, 30, 300, 20);
  
 
  
  if(showHandsCoords && trackedUsers.length > 0)
  {
    PVector leftHand = getJoint(trackedUsers[trackedUsers.length-1], SimpleOpenNI.SKEL_LEFT_HAND);
    text("Left Hand => x : "+int(leftHand.x)+", y : "+int(leftHand.y)+", z : "+int(leftHand.z)+" (hit 'h' to hide)",10,60,350,20);
    PVector rightHand = getJoint(trackedUsers[trackedUsers.length-1], SimpleOpenNI.SKEL_RIGHT_HAND);
    text("Right Hand => x : "+int(rightHand.x)+", y : "+int(rightHand.y)+", z : "+int(rightHand.z)+" (hit 'h' to hide)",10,80,350,20);
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

void setMidiOutDevice(int deviceID)
{
  midiOutDeviceID = deviceID;
  output = devices[midiOutDeviceID].createOutput();
}

void keyPressed(KeyEvent e)
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






