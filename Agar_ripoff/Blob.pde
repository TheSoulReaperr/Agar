class Blob{
  String name;
  PVector position=new PVector(width/2,height/2);
  int mass=100;
  float radius;
  float speed;
  PVector velocity;
  float direction;
  color colour=color(0,255,120);
  PVector shift= new PVector(position.x,position.y);
  
  Blob(){
    
  }
  
  Blob(String name){
   this.name=name; 
  }
  
  void show(){
    fill(colour);
    radius = 2*pow(mass,0.72);
    speed=13/pow(mass,0.33);
    ellipse(position.x,position.y,radius, radius); 
    textSize(radius/4);
    fill(255);
    text(name+"\n"+mass, position.x, position.y);
  }
  
  void move(){
   PVector heading = new PVector(position.x-mouseX,position.y-mouseY);
   direction = heading.heading();
   float sine = sin(direction);
   float cosine = cos(direction);
   velocity = new PVector(cosine*speed, sine*speed);
   shift.sub(velocity);
  }
  
  PVector getVelocity(){
   return velocity;   
  }
  
  boolean checkDinner(Food food){
    PVector vector = PVector.sub(position,food.position);
    float vectorMag = vector.mag();
    boolean status;
    if(vectorMag<radius/2){
     mass+=food.mass;
     status=true;
    }
    else
    status=false;
     return status;
  }
  
  void checkBoundaryCollision(){
   if(shift.x-radius/2<0){
     float distanceCorrection = (radius/2-shift.x)/2.0;
     PVector d = velocity.copy();
     PVector correctionVector = d.normalize().mult(distanceCorrection);
     velocity.x=correctionVector.x;
   }
   /*if(position.x+radius/2>dimension){
     float distanceCorrection = (radius/2-position.x)/2.0;
     PVector d = velocity.copy();
     PVector correctionVector = d.normalize().mult(distanceCorrection);
     position.x+=correctionVector.x;
   }*/
   
  }
  
  void divide(){
   mass/=2;
  }
  
  void releaseMass(){
   mass-=20; 
  }
}
