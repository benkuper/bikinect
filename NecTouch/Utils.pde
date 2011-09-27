PVector lineIntersection(PVector v1, PVector v2, PVector u1, PVector u2)
{
  return lineIntersection(v1.x, v1.y, v2.x, v2.y, u1.x, u1.y, u2.x, u2.y);
}

PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4)
{
 
  float bx = x2 - x1;
 
  float by = y2 - y1;
 
  float dx = x4 - x3;
 
  float dy = y4 - y3;
 
 
 
  float b_dot_d_perp = bx*dy - by*dx;
 
 
 
  if(b_dot_d_perp == 0) return null;
 
 
 
  float cx = x3-x1;
 
  float cy = y3-y1;
 
 
 
  float t = (cx*dy - cy*dx) / b_dot_d_perp;
 
 
 
  return new PVector(x1+t*bx, y1+t*by);
 
}


boolean pixelInPoly(PVector[] verts, PVector pos) {
  int i, j;
  boolean c=false;
  int sides = verts.length;
  
  for (i=0,j=sides-1;i<sides;j=i++) {
    if (( ((verts[i].y <= pos.y) && (pos.y < verts[j].y)) || ((verts[j].y <= pos.y) && (pos.y < verts[i].y))) &&
          (pos.x < (verts[j].x - verts[i].x) * (pos.y - verts[i].y) / (verts[j].y - verts[i].y) + verts[i].x)) {
      c = !c;
    }
  }
  return c;
}

PVector pixelIndexToVector(int pixelIndex,int w, int h)
{
  
  return new PVector(pixelIndex%w,floor(pixelIndex/w));
}
