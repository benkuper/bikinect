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
  
  color bgColor;
  color baseColor  = color(12,133,217);
  color activeBGColor = color(30,30,30);
  color inactiveBGColor = color(220,17,50);
  color triggerColor = color(180,220,17);
  
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

  void draw2VecsFeedback(PVector v1, PVector v2)
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
  
  void drawBooleanFeedback(PVector vec)
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
  
  
  void drawValueAxisArc(float val, float radius){
    drawValueArc(val, radius,TWO_PI / 3,TWO_PI / 10);
  }
  
  void drawValueFullArc(float val, float radius){
    drawValueArc(val, radius,TWO_PI,0);
  }
  
  void drawValueArc(float val, float diameter,float arcLength, float gap)
  {
    arc(0,0, diameter, diameter, 0,val * arcLength-gap);
  }
  
  void drawRectValueFeedback(int w,int h)
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
  
  void drawSingleFeedback(PVector vec)
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
  
  
  void rotateForIndex(int index)
  {
    rotate(-PI+PI/4);
    rotate(index*TWO_PI/3);
  }
  
  void createArcLabel(int offset)
  {
    pushMatrix();
      rotate(PI-PI/3+PI/10);
      createOffsetLabel(offset);
    popMatrix();
  }
  
  void createOffsetLabel(int offset)
  {
    pushMatrix();
      translate(0,-offset);
      createLabel();
    popMatrix();
  }
  
  void createLabel()
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
