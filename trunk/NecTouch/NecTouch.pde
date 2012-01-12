import processing.opengl.*;

import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;
//import Blobscanner.*;
import hypermedia.video.*;
import java.awt.Rectangle;
import controlP5.*;


ControlP5 controlP5;
Feedback feedback;
TUIOServer tuioServer;
OpenCV cv;
TouchSurface[] surfaces;

TouchSurface activeSurface;
ControlGroup surfaceControl;

boolean criticalStop;
XMLElement config;

color[] colors = {
  color(255, 0, 0), color(0, 255, 0), color(20, 100, 255), color(255, 255, 50), color(255, 0, 255), color(0, 255, 255)
};

int gridLines = 4;
int upFactor = 20;

boolean showHelpers, showGrid, showInfos, showDrawingLines, showLabels, showFeedback, maskFloor, showIds;

boolean doCalibrate = false, doMask = false, mirrorMode = false;
boolean miniMode;
boolean autoCalibrate;

SimpleOpenNI  context;
boolean enableRGB;

int imageWidth, imageHeight, pixelsLength;
int[] depthMap;
PImage kinectImage;

PVector mainOffset;
boolean offsetting;
PVector tmpMouseOffset, tmpInitOffset;

boolean invertX, invertY,swapXY;

int minDistance, maxDistance, minBlobSize, maxBlobSize;

static int globalTouchPointIndex;

int numSurfaces;

Toggle nLToggle;

void setup()
{
  criticalStop = false;
  textMode(MODEL);
  
  File f = new File(dataPath("config.xml"));
  if (!f.exists())
  {
    criticalStop = true;
    size(300, 100);
    background(0);
    println("config.xml does not exists in the data folder !"); 
    text("config.xml not found in the data folder !", 10, 10, 300, 20);
    return;
  }
  
  
  config = new XMLElement(this, "config.xml");
  
  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);
  
  
  frameRate(60);

  XMLElement xmlKinect = config.getChild("kinect");
  context.enableDepth();
  context.enableRGB();
  context.alternativeViewPointDepthToImage();
 
  
  
  mirrorMode = boolean(xmlKinect.getString("mirror"));
  context.setMirror(mirrorMode);
  
  
  XMLElement xmlStartup = config.getChild("startup");
  //showHelpers = boolean(xmlStartup.getString("showHelpers", "true"));
  showGrid = boolean(xmlStartup.getString("showGrid", "true"));
  //showInfos = boolean(xmlStartup.getString("showInfos", "true"));
  //showDrawingLines = boolean(xmlStartup.getString("showDrawingLines", "true"));
  showIds = boolean(xmlStartup.getString("showIds", "true"));
  showFeedback = boolean(xmlStartup.getString("showFeedback", "true"));
  showLabels = boolean(xmlStartup.getString("showLabels", "true"));
  miniMode = boolean(xmlStartup.getString("miniMode","true")); 
  autoCalibrate = boolean(xmlStartup.getString("autoCalibrate","false"));
  
  
  

  XMLElement xmlWindow = config.getChild("window");
  mainOffset = new PVector(xmlWindow.getInt("offsetX",0),xmlWindow.getInt("offsetY"),0);
  int tw = miniMode?200:(xmlWindow.getInt("width", 640)+(int)mainOffset.x);
  int th = miniMode?40:(xmlWindow.getInt("height", 480)+(int)mainOffset.y);
  size(tw,th);
  frame.setSize(tw,th); 
  frame.setResizable(boolean(xmlWindow.getString("resizable", "true")));
  smooth();


  imageWidth = context.depthWidth();
  imageHeight = context.depthHeight();
  pixelsLength = imageWidth * imageHeight;

  XMLElement[] xmlSurfaces = config.getChild("surfaces").getChildren();
  //To change
  numSurfaces = xmlSurfaces.length;
  surfaces = new TouchSurface[numSurfaces];
  for(int i=0;i<numSurfaces;i++)
  {
    TouchSurface ts = null;
    if(xmlSurfaces[i].getString("type","plane").equals("plane"))
    {
      ts = new TouchPlane();
    }else if(xmlSurfaces[i].getString("type","plane").equals("button"))
    {
      ts = new TouchButton();
    }
    
    ts.setupSurface(xmlSurfaces[i]);
    surfaces[i] = ts;
  }
  
  
  XMLElement xmlFeedback = config.getChild("feedback");
  feedback = new Feedback(xmlFeedback.getInt("width", 100), xmlFeedback.getInt("height", 100));

  XMLElement xmlTuio = config.getChild("tuio");
  tuioServer = new TUIOServer(xmlTuio.getString("host", "127.0.0.1"), xmlTuio.getInt("port", 3333));

  
  
  
  XMLElement xmlDetection = config.getChild("detection");

  minDistance = xmlDetection.getInt("minDistance");
  maxDistance = xmlDetection.getInt("maxDistance");
  minBlobSize = xmlDetection.getInt("minBlobSize");
  maxBlobSize = xmlDetection.getInt("maxBlobSize");
 
  
  cv = new OpenCV(this);
  cv.allocate(imageWidth,imageHeight);

  invertX =  boolean(xmlDetection.getString("invertX", "false"));
  invertY =  boolean(xmlDetection.getString("invertY", "false"));
  swapXY =  boolean(xmlDetection.getString("swapXY", "false"));
  
  controlP5 = new ControlP5(this);
  controlP5.tab("miniMode");
  controlP5.tab("default").activateEvent(true);
  controlP5.tab("miniMode").activateEvent(true);
  //controlP5.addToggle("showHelpers",showGrid,10,10,20,20);
  //controlP5.addToggle("showDrawingLines",showGrid,10,10,20,20);
  
  controlP5.addToggle("showGrid",showGrid,10,30,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("showFeedback",showFeedback,10,45,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("showLabels",showLabels,10,60,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("showIds",showIds,10,75,10,10).captionLabel().style().margin(-12,0,0,15);
  
  
  Radio r = controlP5.addRadio("enableRGB",130,60);
  r.deactivateAll(); // use deactiveAll to not make the first radio button active.
  
  r.add("RGB",1);
  r.add("Depth",0);
  
  enableRGB = boolean(xmlKinect.getString("enableRGB"));
  if(enableRGB) 
  {
    r.activate("RGB");
  }else
  {
    r.activate("Depth");
  }
  
  Slider s1 = controlP5.addSlider("gridLines",0,20,10,90,60,10);
  s1.setNumberOfTickMarks(20);
  
  Bang b = controlP5.addBang("calibrateSurfaces",130,30,20,20);
  b.captionLabel().style().margin(-17,0,0,25);
  b.setLabel("Calibrate");
  
  controlP5.addToggle("mirrorMode",mirrorMode,220,10,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("doMask",doMask,220,25,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("invertX",invertX,220,40,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("invertY",invertY,220,55,10,10).captionLabel().style().margin(-12,0,0,15);
  controlP5.addToggle("swapXY",swapXY,220,70,10,10).captionLabel().style().margin(-12,0,0,15);
  
  controlP5.addNumberbox("minDistance",minDistance,330,10,50,14).captionLabel().style().margin(-12,0,0,62);
  controlP5.addNumberbox("maxDistance",maxDistance,330,30,50,14).captionLabel().style().margin(-12,0,0,62);
  controlP5.addNumberbox("minBlobSize",minBlobSize,330,50,50,14).captionLabel().style().margin(-12,0,0,62);
  controlP5.addNumberbox("maxBlobSize",maxBlobSize,330,70,50,14).captionLabel().style().margin(-12,0,0,62);
  
  surfaceControl = controlP5.addGroup("surfaceControl",470,10);
  surfaceControl.hideBar();
  nLToggle = controlP5.addToggle("nonLinear",false,10,10,10,10);
  nLToggle.captionLabel().style().margin(-12,0,0,15);
  nLToggle.setGroup("surfaceControl");
  
}


void draw()
{
  if (criticalStop) return;

  background(0);
  context.update();
  // draw 
  
  if(offsetting)
  {
    mainOffset.x = tmpInitOffset.x + mouseX - tmpMouseOffset.x;
    mainOffset.y = tmpInitOffset.y + mouseY - tmpMouseOffset.y;
    tmpMouseOffset.x = mouseX;
    tmpMouseOffset.y = mouseY;
  }
  
  pushMatrix(); //mainOffset push
    translate(mainOffset.x,mainOffset.y);
    
    kinectImage = null;
    int i;
    depthMap = context.depthMap();
    
    
    if(autoCalibrate && !surfaces[0].calibrated)
    {
      println("AutoCalibrate !");
      calibrateSurfaces();
    }
    
    
    if (doCalibrate)
    {
      calibrateSurfaces();
      
    }
    
    if(!miniMode)
    {
      if(enableRGB)
      {
        kinectImage = context.rgbImage();
        
      }else
      {
        kinectImage = context.depthImage();
      }
      
      /*if (doMask && planePixels != null )
      {
        kinectImage.mask(planePixels);
      }*/
      
      image(kinectImage,0,0);
    }
    
    for(i=0;i<numSurfaces;i++)
    {
      surfaces[i].draw();
    }
  
  popMatrix(); //mainOffset pop

   
  if(!miniMode)
  {
    //Additionnal infos
  }
  
  fill(20,200);
  noStroke();
  rect(0, 0, width, 130);
  
  if (showFeedback && !miniMode)
  {
    feedback.draw();
    
    //change for touchplanes touchpoints
    /*for(i=0;i<goodBlobsNumber;i++)
    {
      
      color c = getColorForIndex(touchPoints[i].id);
      feedback.drawPoint(touchPoints[i],touchPoints[i].id, c);
      pushMatrix();
      translate(mainOffset.x, mainOffset.y);
        touchPoints[i].drawPointReel(c);
      popMatrix();
    }**/
  }
  
  
  pushStyle();
  textAlign(RIGHT);
  noStroke();
  fill(0, 160);
  rect(width-200, height-40, 100, 40);
  fill(255);
  text("Framerate "+(int)frameRate, width-100, height-35, 90, 15);
  //text("Raw blobs "+rawBlobsNumber, width-100, height-35, 90, 15);
  
  //change for surface blobs
  //text("Active blobs "+goodBlobsNumber, width-100, height-15, 90, 15);
  popStyle();
}


color getColorForIndex(int i)
{
  return colors[i%colors.length];
}


void setMiniMode()
{
  if(miniMode)
  {
    size(200,40);
    frame.setSize(200,80); 
  }else
  {
    size(imageWidth+(int)mainOffset.x,imageHeight+(int)mainOffset.y);
    frame.setSize(width+80,height+80); 
  }
}
      
void calibrateSurfaces()
{
  for(int i=0;i<numSurfaces;i++)
  {
    surfaces[i].calibrate();
  }
}

void saveConfig()
{
  /*for(int i=0;i<grabbers.length;i++)
  {
    config.getChild("grabbers").getChild(i).setInt("x",(int)grabbers[i].x);
    config.getChild("grabbers").getChild(i).setInt("y",(int)grabbers[i].y);
  }*/
  
  
  
  config.getChild("detection").setInt("minDistance",minDistance);
  config.getChild("detection").setInt("maxDistance",maxDistance);
  config.getChild("detection").setInt("minBlobSize",minBlobSize);
  config.getChild("detection").setInt("maxBlobSize",maxBlobSize);
  
  config.getChild("startup").setString("miniMode",str(miniMode));
  config.getChild("startup").setString("showHelpers", str(showHelpers));
  config.getChild("startup").setString("showGrid", str(showGrid));
  config.getChild("startup").setString("showInfos", str(showInfos));
  config.getChild("startup").setString("showIds", str(showIds));
  config.getChild("startup").setString("showFeedback", str(showFeedback));
  config.getChild("startup").setString("showLabels", str(showLabels));
  config.getChild("startup").setString("autoCalibrate",str(autoCalibrate));
  
  config.getChild("kinect").setString("mirror",str(mirrorMode));
  config.getChild("kinect").setString("enableRGB",str(enableRGB));
   
  config.getChild("detection").setString("invertX",str(invertX));
  config.getChild("detection").setString("invertY",str(invertY));
  config.getChild("detection").setString("swapXY",str(swapXY));
  
  for(int i=0;i<numSurfaces;i++)
  {
    if(surfaces[i].type == TouchSurface.TOUCH_PLANE)
    {
      for(int j=0;j<((TouchPlane)surfaces[i]).grabbers.length;j++)
      {
        config.getChild("surfaces").getChildren()[i].getChild(j).setInt("x",(int)((TouchPlane)surfaces[i]).grabbers[j].x);
        config.getChild("surfaces").getChildren()[i].getChild(j).setInt("y",(int)((TouchPlane)surfaces[i]).grabbers[j].y);
      }
    }
  }
  
  
  println(config.toString());
  config.save("data/config.xml");
  println("config saved !");
}

void mousePressed(MouseEvent e)
{
  super.mousePressed(e);
  
  if (criticalStop) return;
  
  TouchSurface tmpSurface = null;
  boolean sPressed = false;
  
  for(int i=0;i<numSurfaces;i++)
  {
    if(surfaces[i].mousePressed())
    {
      doCalibrate = true;
      sPressed = true;
      tmpSurface = surfaces[i];
      if(!e.isShiftDown()) break;
    }
  }
  
  
  if(mouseY > 110)
  {
    activeSurface = tmpSurface;
    if(activeSurface != null)
    {
      surfaceControl.show();
      if(activeSurface.type == TouchSurface.TOUCH_PLANE)
      {
        nLToggle.setColorBackground(activeSurface.col);
        nLToggle.setColorActive(color(255,255,255));
        nLToggle.setState(((TouchPlane)activeSurface).nonLinearMode);
      }
    }else
    {
      surfaceControl.hide();
    }
    
    if(sPressed) return;
    
    println("mouseY :"+mouseY);
    tmpMouseOffset = new PVector(mouseX,mouseY);
    tmpInitOffset = mainOffset;
    offsetting = true;
  }
}

void mouseReleased()
{
  super.mouseReleased();
  
  if (criticalStop) return;
  
  for(int i=0;i<numSurfaces;i++)
  {
    surfaces[i].mouseReleased();
  }
  
  doCalibrate=false;
}


void controlEvent(ControlEvent e)
{
  
 if(e.isTab())
 {
  miniMode = e.tab().name().equals("miniMode");
  setMiniMode();
 }else{
   String n = e.controller().name(); 
   println(n);
   if(n.equals("mirrorMode"))
   {
     context.setMirror(mirrorMode);
   }else if(n.equals("nonLinear"))
   {
     if(activeSurface != null)
     {
       ((TouchPlane)activeSurface).nonLinearMode = e.controller().value() == 1;
     }
   }
 }
}


void keyPressed(KeyEvent e)
{

  if (criticalStop) return;

  switch(e.getKeyChar())
  {

  case 'h':
    showHelpers = !showHelpers;
    break;

  case 'g':
    showGrid = !showGrid;
    break;

  case 'd':
    showDrawingLines  = !showDrawingLines;
    break;

  case 'i':
    showInfos = !showInfos;
    break;

  case '8':
    gridLines++;
    break;

  case '2':
    gridLines--;
    break;

  case 'l':
    showLabels = !showLabels;
    break;

  case 'f':
    showFeedback= !showFeedback;
    break;

  case 'p':
    doCalibrate = !doCalibrate;
    break;

  case 'c':
    calibrateSurfaces();
    break;
    
  case 'k':
    enableRGB = !enableRGB;
    break;
    
  case 'r':
    mirrorMode = !mirrorMode;
    context.setMirror(mirrorMode);
    break;
    
  case 'w':
    swapXY = !swapXY;
    break;
    
  case 'x':
    invertX = !invertX;
    break;
    
  case 'y':
    invertY = !invertY;
    break;
    
  case 's':
    saveConfig();
    break;

  case 'm':
    
    doMask = !doMask;
    /*maskFloor = doMask;
    println("doMask & maskFloor "+doMask);
    if (doMask && planePixels == null)
    {
      calibrateSurfaces();
    }*/

    break;
    
    case ' ':
      miniMode = !miniMode;
      controlP5.getTab("miniMode").setActive(miniMode);
      controlP5.getTab("default").setActive(!miniMode);
      setMiniMode();
  }
  
  println(e.getKeyCode());
  switch(e.getKeyCode())
  {

    case 107:
    case 47:
      if (e.isShiftDown())
      {
        maxDistance++;
      }
      else if (e.isControlDown())
      {
        minDistance++;
      }
      else if (e.isAltDown())
      {
        maxBlobSize++;
      }
      else
      {
        minBlobSize++;
      }
      break;
  
    case 109:
    case 61:
      if (e.isShiftDown())
      {
        maxDistance--;
      }
      else if (e.isControlDown())
      {
        minDistance--;
      }
      else if (e.isAltDown())
      {
        if (maxBlobSize > 0) maxBlobSize-- ;
      }
      else
      {
        if (minBlobSize > 0) minBlobSize--;
      }
    break;
  
  
  case 37:
    mainOffset.x -=2;
    break;
  case 38:
    mainOffset.y -=2;
    break;
  case 39:
    mainOffset.x +=2;
    break;
  case 40:
    mainOffset.y +=2;
    break;
  }
}

