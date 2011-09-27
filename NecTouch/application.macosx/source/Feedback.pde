public class Feedback
{
  
  float x;
  float y;
  int w;
  int h;
  
  public Feedback(int w, int h)
  {
    this.w = w;
    this.h = h;
  }
  
  void draw()
  {
    
    x = width - w - 10;
    y = 10;
    
    pushMatrix();
      translate(x,y);
      
      pushStyle();
        stroke(200);
        fill(200,100);
        rect(0,0,w,h);      
      popStyle();
    popMatrix();
  }
  
  void drawPoint(PVector p,int id, color col)
  {
    pushMatrix();
      translate(x,y);
    pushStyle();
     noStroke();
     fill(col);
     ellipse(p.x*w,p.y*h,5,5);
     text("id "+id, p.x*w -10,p.y*h-15,60,15);
     popStyle();
    popMatrix();
  }
}


