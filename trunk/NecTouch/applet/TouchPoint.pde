class TouchPoint extends PVector
{
  public int id;
  TouchPoint lastPoint;
  float speedX, speedY;
  float speed;
  float acc;
  Boolean linked;
  
  String currentState;
  
  PVector reelCoord;
  
  public TouchPoint(float tx, float ty, PVector reelCoordVec, boolean isLast)
  {

    x = tx;
    y = ty;
    linked = false;
    reelCoord = reelCoordVec;
    
    if(!isLast)
    {
      setLastPoint(new TouchPoint(tx, ty, null, true));
    }
  }
  
  public void setLastPoint(TouchPoint lp)
  {
    lastPoint = lp;
    speedX = x - lastPoint.x;
    speedY = y - lastPoint.y;
    
    float lastSpeed = lastPoint.speed;
    speed = PVector.dist(this, lastPoint);
    acc = speed - lastSpeed;
  }
  
  public void setState(String state)
  {
    currentState = state;
    
    if(state.equals("new"))
    {
      globalTouchPointIndex++;
      this.id = globalTouchPointIndex;
    }
  }
  
  public void drawPointReel(color c)
  {
    pushStyle();
     noFill();
     stroke(c);
     ellipse(reelCoord.x, reelCoord.y,10,10);
    popStyle();
  }
}
