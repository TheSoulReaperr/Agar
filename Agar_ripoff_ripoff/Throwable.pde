class Throwable extends Food{
   int count;
   PVector travel;
  Throwable(PVector position, PVector velocity, color colour){
     this.position=position;
     this.travel=velocity;
     this.mass=16;
     this.radius = 10*sqrt(mass/PI);
     this.colour = colour; 
  }
  
  void travel(){
    if(count<30)
    position.sub(travel);
    count++;
  }
  
  void checkCollision(Throwable other){
      PVector distanceVect =  PVector.sub(this.position, other.position);
      float distanceVectMag= distanceVect.mag();
      float angle = distanceVect.heading();
      float minDistance = this.radius+other.radius;
      if(distanceVectMag<minDistance){
       float correctionDistance = (minDistance - distanceVectMag)/2;
       PVector correctionVect = new PVector(cos(angle), sin(angle));
       this.position.add(new PVector(correctionVect.x*correctionDistance, correctionVect.y*correctionDistance));
       other.position.sub(new PVector(correctionVect.x*correctionDistance, correctionVect.y*correctionDistance));
       
      }
  }
}
