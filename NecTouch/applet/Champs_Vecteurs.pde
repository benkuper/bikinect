import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;
//import Blobscanner.*;
import hypermedia.video.*;
import java.awt.Rectangle;

Grabber gbTL;
Grabber gbTR;
Grabber gbBL;
Grabber gbBR;

Grabber[] grabbers;
Feedback feedback;
TUIOServer tuioServer;

TouchPoint simPoint;
Boolean simActive, simAlreadyActive;

PVector leftHorizon, rightHorizon, upLPoint, upRPoint;

int numLines = 4;
int upFactor = 200;

Boolean showHelpers, showGrid, showInfos, showDrawingLines, showLabels, showFeedback, maskFloor;

Boolean doCalibrate = false, doMask = false;
Boolean miniMode;

SimpleOpenNI  context;
Boolean enableRGB;

int[] planePixels, planeDepthPixels, planeDepthMap;

int imageWidth, imageHeight, pixelsLength, planePixelsLength;

PVector mainOffset;

Boolean invertX, invertY;

PGraphics planeMask;

int minDiff, maxDiff, minBlobWeight, maxBlobWeight;

PImage blobsImage;
//Detector bd;
OpenCV cv;

int goodBlobsNumber, rawBlobsNumber;

TouchPoint[] touchPoints;

static int globalTouchPointIndex;

color[] colors = {
  color(255, 0, 0), color(0, 255, 0), color(20, 100, 255), color(255, 255, 50), color(255, 0, 255), color(0, 255, 255)
};

Boolean criticalStop;


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
  
  
  XMLElement config = new XMLElement(this, "config.xml");
  
  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);
  
  
  frameRate(60);

  XMLElement xmlKinect = config.getChild("kinect");
  context.enableDepth();
  
  if(boolean(xmlKinect.getString("enableRGB")))
  {
    enableRGB = true;
    context.enableRGB();
    context.alternativeViewPointDepthToImage();
  }
  
  if(boolean(xmlKinect.getString("mirror"))) context.setMirror(true);
  
  
  XMLElement xmlStartup = config.getChild("startup");
  showHelpers = boolean(xmlStartup.getString("showHelpers", "true"));
  showGrid = boolean(xmlStartup.getString("showGrid", "true"));
  showInfos = boolean(xmlStartup.getString("showInfos", "true"));
  showDrawingLines = boolean(xmlStartup.getString("showDrawingLines", "true"));
  showFeedback = boolean(xmlStartup.getString("showFeedback", "true"));
  showLabels = boolean(xmlStartup.getString("showLabels", "true"));
  miniMode = boolean(xmlStartup.getString("miniMode","true")); 


  XMLElement xmlWindow = config.getChild("window");
  mainOffset = new PVector(xmlWindow.getInt("offsetX",0),xmlWindow.getInt("offsetY"),0);
  int tw = miniMode?200:(xmlWindow.getInt("width", 640)+(int)mainOffset.x);
  int th = miniMode?40:(xmlWindow.getInt("height", 480)+(int)mainOffset.y);
  size(tw,th);
  frame.setSize(tw,th); 
  frame.setResizable(boolean(xmlWindow.getString("resizable", "true")));
  smooth();



  XMLElement xmlGrabbers = config.getChild("grabbers");
  gbTL = new Grabber(0, xmlGrabbers.getChild(0).getString("label", ""), xmlGrabbers.getChild(0).getInt("x", 50), xmlGrabbers.getChild(0).getInt("y", 50));
  gbTR = new Grabber(1, xmlGrabbers.getChild(1).getString("label", ""), xmlGrabbers.getChild(1).getInt("x", 250), xmlGrabbers.getChild(1).getInt("y", 50));
  gbBR  =new Grabber(2, xmlGrabbers.getChild(2).getString("label", ""), xmlGrabbers.getChild(2).getInt("x", 250), xmlGrabbers.getChild(2).getInt("y", 200));
  gbBL = new Grabber(3, xmlGrabbers.getChild(3).getString("label", ""), xmlGrabbers.getChild(3).getInt("x", 50), xmlGrabbers.getChild(3).getInt("y", 200));

  grabbers = new Grabber[4];
  grabbers[0] = gbTL;
  grabbers[1] = gbTR;
  grabbers[2] = gbBR;
  grabbers[3] = gbBL;
  
  
  maskFloor = false;

  simActive = false;
  simAlreadyActive = false;

  XMLElement xmlFeedback = config.getChild("feedback");
  feedback = new Feedback(xmlFeedback.getInt("width", 100), xmlFeedback.getInt("height", 100));

  XMLElement xmlTuio = config.getChild("tuio");
  tuioServer = new TUIOServer(xmlTuio.getString("host", "127.0.0.1"), xmlTuio.getInt("port", 3333));

  imageWidth = context.depthWidth();
  imageHeight = context.depthHeight();
  pixelsLength = imageWidth * imageHeight;

  planeMask = createGraphics(imageWidth, imageHeight, P2D);
  
  XMLElement xmlDetection = config.getChild("detection");

  minDiff = xmlDetection.getInt("minDistance");
  maxDiff = xmlDetection.getInt("maxDistance");
  minBlobWeight = xmlDetection.getInt("minBlobSize");
  maxBlobWeight = xmlDetection.getInt("maxBlobSize");

  cv = new OpenCV(this);
  cv.allocate(imageWidth,imageHeight);

  invertX =  boolean(xmlDetection.getString("invertX", "false"));
  invertY =  boolean(xmlDetection.getString("invertY", "false"));

  touchPoints = new TouchPoint[0];
}

void draw()
{
  if (criticalStop) return;

  background(0);
  context.update();
  // draw 
  
  pushMatrix();
  translate(mainOffset.x,mainOffset.y);
  
  PImage kinectImage = null;
  int i;
  int[] depthMap = context.depthMap();

  if (doCalibrate)
  {
    calibratePlane();
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
    
    if (doMask && planePixels != null )
    {
      kinectImage.mask(planePixels);
    }
    
    image(kinectImage,0,0);
  }
  

  for (i=0;i<4;i++)
  {
    grabbers[i].draw();
    stroke(255);
    line(grabbers[i].x, grabbers[i].y, grabbers[(i+1)%4].x, grabbers[(i+1)%4].y);
  }

  leftHorizon = lineIntersection(gbTL.x, gbTL.y, gbBL.x, gbBL.y, gbTR.x, gbTR.y, gbBR.x, gbBR.y);
  rightHorizon = lineIntersection(gbTL.x, gbTL.y, gbTR.x, gbTR.y, gbBL.x, gbBL.y, gbBR.x, gbBR.y);

  if (showDrawingLines)
  {
    ellipse(leftHorizon.x, leftHorizon.y, 10, 10);
    ellipse(rightHorizon.x, rightHorizon.y, 10, 10);

    stroke(200, 150);
    line(leftHorizon.x, leftHorizon.y, gbBL.x, gbBL.y);
    line(rightHorizon.x, rightHorizon.y, gbTL.x, gbTL.y);
    line(leftHorizon.x, leftHorizon.y, gbBR.x, gbBR.y);
    line(rightHorizon.x, rightHorizon.y, gbBR.x, gbBR.y);

    line(leftHorizon.x, leftHorizon.y, rightHorizon.x, rightHorizon.y);
    line(leftHorizon.x, leftHorizon.y, rightHorizon.x, rightHorizon.y);
  }

  PVector upPoint = new PVector(gbBL.x, gbBL.y - upFactor);

  if (rightHorizon != null && leftHorizon != null)
  {
    upLPoint = lineIntersection(gbTL.x, gbTL.y, gbTL.x, gbTL.y-1, leftHorizon.x, leftHorizon.y, upPoint.x, upPoint.y);
    upRPoint = lineIntersection(gbBR.x, gbBR.y, gbBR.x, gbBR.y-1, rightHorizon.x, rightHorizon.y, upPoint.x, upPoint.y);


    if (showHelpers)
    {
      drawRepere(leftHorizon, gbBL, gbTL, upPoint, upLPoint);
      drawRepere(rightHorizon, gbBL, gbBR, upPoint, upRPoint);
    }

    if (showGrid)
    {
      drawGrid(leftHorizon, rightHorizon, gbBL, gbTL, gbTR, gbBR);
      drawGrid(rightHorizon, leftHorizon, gbBL, gbBR, gbTL, gbTR);
    }

    if (simActive)
    {
      

      PVector targetPoint = getProjectedPoint(new PVector(mouseX-mainOffset.x, mouseY-mainOffset.y));

      //force same point at first time to avoid non-sense with speed and acc computed values
      if (!simAlreadyActive)
      {
        simPoint = new TouchPoint(targetPoint.x,  targetPoint.y , null, false);
        simPoint.setState("new");
        
      }else
      {
        simPoint.lastPoint = new TouchPoint(simPoint.x, simPoint.y, null, true);
        simPoint.x = targetPoint.x;
        simPoint.y = targetPoint.y;
        simPoint.setState("update");
      }
      
      if (!simAlreadyActive)
      {
        //New point
        tuioServer.send("update", simPoint);
        simAlreadyActive = true;
      }
      else
      {
        //Already there
        tuioServer.send("update", simPoint);
      }

      if (showFeedback)
      {
        feedback.drawPoint(targetPoint, -1, color(255, 255, 255));
      }
    }
    else {
      if (simAlreadyActive) {
        //Point destroy

        simAlreadyActive = false;
        simPoint.setState("destroy");
        tuioServer.send("destroy", simPoint);
      }
    }
  }

  if (planePixelsLength > 0)
  {

    blobsImage = createImage(imageWidth, imageHeight, ARGB); 
    blobsImage.loadPixels();

    int[] floorMaskPixels = new int[pixelsLength];

    PVector topLeft = new PVector(imageWidth, imageHeight);
    PVector bottomRight = new PVector(0, 0);
    
    
    
    
    for (i=0;i<planePixelsLength;i++)
    {
      int targetPixelIndex = planeDepthPixels[i];
      int refDepth = planeDepthMap[i];
      int curDepth = depthMap[targetPixelIndex];
      //filterImage.pixels[targetPixelIndex] = color(255,0,0,50);
      int diffDepth = refDepth-curDepth;



      if (diffDepth > minDiff)
      {
        if (maskFloor)
        {
          floorMaskPixels[targetPixelIndex] = 255;
        }

        if (diffDepth < maxDiff)
        {
          int reelX = targetPixelIndex%imageWidth;
          int reelY = floor(targetPixelIndex/imageWidth);

          topLeft.x = min(topLeft.x, reelX);
          topLeft.y = min(topLeft.y, reelY);
          bottomRight.x = max(bottomRight.x, reelX);
          bottomRight.y = max(bottomRight.y, reelY);

          //println(curDepth+"-"+refDepth+" = "+(curDepth-refDepth));
          blobsImage.pixels[targetPixelIndex] = color(255,0,0,150);
        }
      }
    }
    blobsImage.updatePixels();
    
    
    
    
    if (topLeft.x < bottomRight.x)
    {
      topLeft.x -=10;
      topLeft.y -= 10;
      bottomRight.x += 10;
      bottomRight.y +=10;
      
      int rectW = (int)(bottomRight.x-topLeft.x);
      int rectH = (int)(bottomRight.y-topLeft.y);
      
      pushStyle();
      stroke(40, 120, 230,100);
      strokeWeight(2);
      noFill();
      rect(topLeft.x, topLeft.y, rectW, rectH);
      popStyle();

      //blobsImage = blobsImage.get((int)topLeft.x, (int)topLeft.y, rectW, rectH);*/
      processBlobs(blobsImage,topLeft,rectW,rectH);
      
      if(!miniMode)
      {
        if (maskFloor)
        {
          kinectImage.mask(floorMaskPixels);
          image(kinectImage, 0, 0);
        }
        
        image(blobsImage,0,0);
      }
    }else
    {
      processBlobs(blobsImage,null,0,0);
    }

  }
  
  popMatrix(); //mainOffset popMatrix

  if (showFeedback && !miniMode)
  {
    feedback.draw();
    for(i=0;i<goodBlobsNumber;i++)
    {
      color c = getColorForIndex(touchPoints[i].id);
      feedback.drawPoint(touchPoints[i],touchPoints[i].id, c);
      touchPoints[i].drawPointReel(c);
    }
  }
  
 

  
  if(!miniMode)
  {
    if (showInfos)
    {
      fill(0, 160);
      noStroke();
      rect(0, 0, 250, 210);
  
  
      fill(255);
      pushStyle();
      if (showGrid) fill(100, 200, 20);
      text("g : Show / Hide Grid", 10, 30, 200, 20);
      popStyle();
  
      text("8 / 2 : Increase / Decrease grid density", 10, 50, 250, 20);
  
      pushStyle();
      if (showDrawingLines) fill(100, 200, 20);
      text("d : Show / Hide Drawing Lines", 10, 70, 200, 20);
      popStyle();
  
  
      pushStyle();
      if (showHelpers) fill(100, 200, 20);
      text("r : Show / Hide Helpers", 10, 90, 200, 20);
      popStyle();
  
  
      pushStyle();
      if (showLabels) fill(100, 200, 20);
      text("l : Show / Hide Labels", 10, 110, 200, 20);
      popStyle();
  
      pushStyle();
      if (showFeedback) fill(100, 200, 20);
      text("f : Show / Hide Feedback", 10, 130, 200, 20);
      popStyle();
  
      text("c : Calibrate plane", 10, 150, 200, 20);
  
      pushStyle();
      if (doCalibrate) fill(100, 200, 20);
      text("p : Toggle permanent calibration", 10, 170, 250, 20);
      popStyle();
  
      pushStyle();
      if (doMask) fill(100, 200, 20);
      text("m : Toggle plane mask mode", 10, 190, 250, 20);
      popStyle();
  
  
  
      pushStyle();
      fill(0, 160);
      rect(0, height-40, 300, 40);
  
  
      fill(255);
      text("Min / Max diff ((Ctrl or Shift) & '+' / '-') : "+minDiff+" -> "+maxDiff, 10, height-35, 300, 20);
      text("Min / Max blob size ((Alt or Nothing) & '+' / '-') : "+minBlobWeight+" -> "+maxBlobWeight, 10, height-15, 390, 20);
      popStyle() ;
    }
    text("'i' - Show / Hide infos", 10, 10, 200, 20);
  }
  
  
  pushStyle();
  textAlign(RIGHT);
  noStroke();
  fill(0, 160);
  rect(width-200, height-40, 100, 40);
  fill(255);
  text("Framerate "+(int)frameRate, width-100, height-35, 90, 15);
  //text("Raw blobs "+rawBlobsNumber, width-100, height-35, 90, 15);
  text("Active blobs "+goodBlobsNumber, width-100, height-15, 90, 15);
  popStyle();

  
}


void drawGrid(PVector firstHorizon, PVector secondHorizon, PVector longPoint, PVector midPoint, PVector sideFirstPoint, PVector sideSecondPoint)
{
  pushStyle();
  stroke(130, 250);
  PVector upPoint = new PVector(midPoint.x, midPoint.y-numLines);
  for (int i=0;i<numLines;i++)
  {
    PVector diagIntersect = lineIntersection(longPoint.x, longPoint.y, upPoint.x, upPoint.y, firstHorizon.x, firstHorizon.y, midPoint.x, midPoint.y + (upPoint.y-midPoint.y)*i/numLines);
    if (diagIntersect == null) break;
    PVector targetEnd = lineIntersection(diagIntersect.x, diagIntersect.y, diagIntersect.x, diagIntersect.y+1, firstHorizon.x, firstHorizon.y, longPoint.x, longPoint.y);
    PVector targetBegin = lineIntersection(targetEnd.x, targetEnd.y, secondHorizon.x, secondHorizon.y, sideFirstPoint.x, sideFirstPoint.y, sideSecondPoint.x, sideSecondPoint.y);

    line(targetEnd.x, targetEnd.y, targetBegin.x, targetBegin.y);
  }
  popStyle();
}

void drawRepere(PVector horizon, PVector longPoint, PVector midPoint, PVector upPoint, PVector upMPoint)
{
  if (upMPoint == null) return;

  ellipse(upPoint.x, upPoint.y, 5, 5);
  pushStyle(); 
  stroke(200, 100);
  line(longPoint.x, longPoint.y, upPoint.x, upPoint.y);
  line(horizon.x, horizon.y, upPoint.x, upPoint.y);

  ellipse(upMPoint.x, upMPoint.y, 5, 5);
  line(midPoint.x, midPoint.y, upMPoint.x, upMPoint.y);
  stroke(250, 250, 20, 100);
  line(longPoint.x, longPoint.y, upMPoint.x, upMPoint.y);
  popStyle();
}


float calculatePerspCoord(PVector firstHorizon, PVector secondHorizon, PVector simPoint, PVector firstPoint, PVector secondPoint, PVector upPoint, PVector sideFirstPoint, PVector sideSecondPoint)
{

  PVector bIntersect = lineIntersection(firstHorizon.x, firstHorizon.y, simPoint.x, simPoint.y, firstPoint.x, firstPoint.y, secondPoint.x, secondPoint.y);

  if (PVector.dist(secondHorizon, bIntersect) > PVector.dist(secondHorizon, firstPoint)) {
    //todo stop sending here if clip stops
    bIntersect = firstPoint;
  }
  else if (PVector.dist(secondHorizon, bIntersect) < PVector.dist(secondHorizon, secondPoint)) {
    bIntersect = secondPoint;
  }

  PVector upBIntersect = lineIntersection(bIntersect.x, bIntersect.y, bIntersect.x, bIntersect.y-1, secondHorizon.x, secondHorizon.y, upPoint.x, upPoint.y);
  PVector diagIntersect = lineIntersection(firstPoint.x, firstPoint.y, upPoint.x, upPoint.y, bIntersect.x, bIntersect.y, upBIntersect.x, upBIntersect.y);
  PVector targetIntersect = lineIntersection(secondHorizon.x, secondHorizon.y, diagIntersect.x, diagIntersect.y, secondPoint.x, secondPoint.y, upPoint.x, upPoint.y);

  float targetY = PVector.dist(secondPoint, targetIntersect) / PVector.dist(secondPoint, upPoint);

  pushStyle();
  stroke(255, 20, 20, 150);
  fill(255, 20, 20, 150);

  if (showDrawingLines)
  {
    line(firstHorizon.x, firstHorizon.y, bIntersect.x, bIntersect.y);


    //ellipse(upBIntersect.x,upBIntersect.y,5,5);
    line(bIntersect.x, bIntersect.y, diagIntersect.x, diagIntersect.y);

    fill(50, 120, 230, 200);
    stroke(50, 120, 230);
    ellipse(diagIntersect.x, diagIntersect.y, 5, 5);
    line(secondHorizon.x, secondHorizon.y, diagIntersect.x, diagIntersect.y);
  }
  else
  {
    PVector closerIntersect = lineIntersection(firstHorizon, simPoint, sideFirstPoint, sideSecondPoint);
    line(closerIntersect.x, closerIntersect.y, bIntersect.x, bIntersect.y);
  }

  popStyle();

  return targetY;
}


public void calibratePlane()
{
  int[] depthMap = context.depthMap();
  int i;



  planeMask.colorMode(ALPHA);
  planeMask.beginDraw();
  planeMask.background(100);
  planeMask.fill(255);
  planeMask.noStroke();
  planeMask.beginShape();
  for (i=0;i<grabbers.length;i++)
  {
    planeMask.vertex(grabbers[i].x, grabbers[i].y);
  }
  planeMask.endShape(CLOSE);
  planeMask.endDraw();


  /*PImage planeMask = new PImage(imageWidth,imageHeight,ALPhA);
   planeMask.loadPixels();*/
  planePixels = planeMask.pixels;
  /*planeMask.updatePixels();*/

  boolean[] planeBuffer = new boolean[pixelsLength];

  planePixelsLength = 0;

  //Get the length of the plane pixels array
  for (i=0;i<pixelsLength;i++)
  {
    if (planePixels[i] == -1)
    {
      planeBuffer[i] = true;
      planePixelsLength++;
    }
  }

  //fill the planeDepthPixels array with pixels indexes and planeDepthMap with depthMap data


  planeDepthPixels = new int[planePixelsLength];
  planeDepthMap = new int[planePixelsLength];

  int planeDepthPixelsIndex = 0;
  for (i=0;i<pixelsLength;i++)
  {
    if (planeBuffer[i])
    {
      planeDepthPixels[planeDepthPixelsIndex] = i;
      planeDepthMap[planeDepthPixelsIndex] = depthMap[i];
      planeDepthPixelsIndex++;
    }
  }
}


void processBlobs(PImage img, PVector offset, int w, int h)
{
  goodBlobsNumber = 0;
  rawBlobsNumber = 0;
  TouchPoint[] blobPoints;
  int i;
  
  if(w == 0 || h == 0)
  {
    blobPoints = new TouchPoint[0];
  }else
  {
    
    /*bd = new Detector(this,0,0, blobsImage.width, blobsImage.height, 255 );
    bd.findBlobs(blobsImage.pixels, blobsImage.width, blobsImage.height);
    bd.loadBlobsFeatures();// to call always before to use a method returning or processing a blob feature
    bd.weightBlobs(true);
    
    rawBlobsNumber = bd.getBlobsNumber();*/
    
    cv.copy(blobsImage);
    cv.ROI((int)offset.x,(int)offset.y,w,h);
    
    Blob[] blobs = cv.blobs(minBlobWeight,maxBlobWeight,20,false,4);
    rawBlobsNumber = blobs.length;
    
    blobPoints = new TouchPoint[rawBlobsNumber];
    
    for (i = 0; i < rawBlobsNumber; i++)
    {
      Rectangle r = blobs[i].rectangle;
      
      PVector reelCoordVec = new PVector(r.x + r.width/2, r.y+r.height);
      PVector tmpVec = getProjectedPoint(reelCoordVec);
      blobPoints[goodBlobsNumber] = new TouchPoint(tmpVec.x, tmpVec.y, reelCoordVec, false);
      println(reelCoordVec+" /" +tmpVec);
      goodBlobsNumber++;
    }
  
    while (blobPoints.length > goodBlobsNumber) blobPoints = (TouchPoint[]) shorten(blobPoints);
  }
  

  int pLen = touchPoints.length;
  
  float minDist = 0;
  int minIndex = -1;
  float curDist = 0;

  if (goodBlobsNumber >= pLen)
  {

    //println("");
    //println("*** more or equal");
    for (i = 0;i<pLen;i++)
    {
      //println("touchPoint " + i +", id :"+touchPoints[i].id);

      minIndex = -1;
      curDist = 0;
      minDist = 0;

      for (int j=0;j<goodBlobsNumber;j++)
      {
        if (blobPoints[j].linked) {
          //println(" -> blob "+j+" is already linked");
          //println(" -> test distance with blob "+j+" :"+curDist);
        }
        else {
          curDist = PVector.dist(touchPoints[i], blobPoints[j]);
          //println(" -> test distance with blob "+j+" :"+curDist);

          if (minIndex == -1 || curDist < minDist)
          {
            minDist = curDist;
            minIndex = j;
          }
        }
      }

      //println(" -> linked with index :"+minIndex+", distance "+round(minDist)+", tmpId = "+blobPoints[minIndex].id+", touchId = "+touchPoints[i].id);
      blobPoints[minIndex].id = touchPoints[i].id;
      blobPoints[minIndex].lastPoint = touchPoints[i];
      blobPoints[minIndex].linked = true;
      
      /*if(PVector.dist(blobPoints[minIndex], blobPoints[minIndex].lastPoint) < .005)
      {
        blobPoints[minIndex] = blobPoints[minIndex].lastPoint;
      }*/
      
      blobPoints[minIndex].x = blobPoints[minIndex].lastPoint.x + (blobPoints[minIndex].x - blobPoints[minIndex].lastPoint.x) * .5;
      blobPoints[minIndex].y = blobPoints[minIndex].lastPoint.y + (blobPoints[minIndex].y - blobPoints[minIndex].lastPoint.y) * .5;
      
    }
    
    
    
    for (i = 0; i< goodBlobsNumber ;i++)
    {

      if (!blobPoints[i].linked)
      {
        //New point
        //println("new Point");
        blobPoints[i].setState("new");
        //tuioServer.send("new",blobPoints[i]);
      }
      else
      {
        //blobPoints[i].setState("update");
      }
    }
    
    
  }
  else
  {
    //println("************************ LESS ***");

    for (i = 0;i<pLen;i++)
    {
      touchPoints[i].linked = false;
    }


    for (i = 0;i<goodBlobsNumber;i++)
    {
      //println("blobPoint" + i +", id :"+blobPoints[i].id);

      minIndex = -1;
      curDist = 0;
      minDist = 0;
      
      TouchPoint[] alivePoints = new TouchPoint[0];
      
      for (int j=0;j<pLen;j++)
      {
        if (touchPoints[j].linked) {
         // println(" -> touchpoint "+j+" is already linked");
        }
        else {

          curDist = PVector.dist(blobPoints[i], touchPoints[j]);
          //println(" -> test distance with touchpoint "+j+" :"+curDist);

          if (minIndex == -1 || curDist < minDist)
          {
            minDist = curDist;
            minIndex = j;
          }
        }
      }

      if (minIndex != -1)
      {
        //println(" -> linked with index :"+minIndex+", distance "+minDist+", touchId :"+touchPoints[minIndex].id);
        blobPoints[i].id = touchPoints[minIndex].id;
        blobPoints[i].lastPoint = touchPoints[minIndex];
        touchPoints[minIndex].linked = true;
      }
    }
    
    
    /*for (i = 0;i<pLen;i++)
    {
      if (!touchPoints[i].linked)
      {
        //Point destroy
        println("Point destroy, id="+touchPoints[i].id);
        //tuioServer.send("destroy", touchPoints[i]);
      }else
      {
        
      }
    }*/
  }


  touchPoints = blobPoints;
  tuioServer.send("update",touchPoints);
}



PVector getProjectedPoint(PVector touchPoint)
{


  pushStyle();
    noStroke();
    pushMatrix();
    translate(touchPoint.x, touchPoint.y);
    noFill();
    stroke(200,150);
    ellipse(0, 0, 10, 10);
    popMatrix();
  popStyle();



  float targetX = calculatePerspCoord(leftHorizon, rightHorizon, touchPoint, gbBL, gbBR, upRPoint, gbTL, gbTR);
  float targetY = 1 - calculatePerspCoord(rightHorizon, leftHorizon, touchPoint, gbBL, gbTL, upLPoint, gbBR, gbTR);

  targetX = constrain(targetX, 0, 1);
  targetY = constrain(targetY, 0, 1);

  if (invertX) targetX = 1-targetX;
  if (invertY) targetY = 1-targetY;
  
  println("targetX / Y ="+targetX+", "+targetY);

  return new PVector(targetX, targetY);
}

color getColorForIndex(int i)
{
  return colors[i%colors.length];
}

void mousePressed()
{
  if (criticalStop) return;

  Boolean grabberPressed = false;
  for (int i=0;i<4;i++)
  {
    if (grabbers[i].mousePressed())
    {
      grabberPressed = true;
      break;
    }
  }

  if (!grabberPressed)
  {
    simActive = true;
    simAlreadyActive = false;
  }
}

void mouseReleased()
{
  if (criticalStop) return;

  for (int i=0;i<4;i++)
  {
    grabbers[i].pressed = false;
  }

  simActive = false;
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
    numLines++;
    break;

  case '2':
    numLines--;
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
    calibratePlane();
    break;
    
  case 'r':
    enableRGB = !enableRGB;
    break;

  case 'm':

    doMask = !doMask;
    maskFloor = doMask;
    println("doMask & maskFloor "+doMask);
    if (doMask && planePixels == null)
    {
      calibratePlane();
    }

    break;
    
    case ' ':
      miniMode = !miniMode;
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
  
  println(e.getKeyCode());
  switch(e.getKeyCode())
  {

    case 107:
    case 47:
      if (e.isShiftDown())
      {
        maxDiff++;
      }
      else if (e.isControlDown())
      {
        minDiff++;
      }
      else if (e.isAltDown())
      {
        maxBlobWeight++;
      }
      else
      {
        minBlobWeight++;
      }
      break;
  
    case 109:
    case 61:
      if (e.isShiftDown())
      {
        maxDiff--;
      }
      else if (e.isControlDown())
      {
        minDiff--;
      }
      else if (e.isAltDown())
      {
        if (maxBlobWeight > 0) maxBlobWeight-- ;
      }
      else
      {
        if (minBlobWeight > 0) minBlobWeight--;
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

