class Grabber extends PVector
{
  color col;
  float radius;
  int index;
  String label;
  
  Boolean pressed;
  
  public Grabber (int index, String label, float tx, float ty)
  {
    if(index == 0 ){
     this.col = color(250,80,120);
    }else{
      this.col = color(random(150)+100,random(150)+100,random(150)+100);
    }
  
    this.label = label;
    this.index = index;
    this.x = tx;
    this.y = ty;
    println("new grabber");
    radius = 10;
    pressed = false;
  }
  
  Boolean mousePressed()
  {
    if(dist(new PVector(mouseX,mouseY),this) < radius)
    {
      pressed = true;
      return true;
    }
    return false;
  }
  
  void draw()
  {
    pushStyle();
    noStroke();
    
    if(pressed)
    {
      fill(255,255,0);
      x = mouseX - mainOffset.x;
      y = mouseY - mainOffset.y;
    }else{
      fill(col);
    }
      
    pushMatrix();
    
      ellipse(x,y,radius,radius);
      if(showLabels){
        text(label+"("+x+","+y+")",x-30,y-radius-10,160,20);
      }
    popMatrix();
    
    popStyle();
  }
}

