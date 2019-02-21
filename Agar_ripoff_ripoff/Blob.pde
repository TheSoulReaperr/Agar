class Blob {
  String name;
  PVector position;
  float mass;
  float radius;
  float speed;
  PVector velocity=new PVector(0, 0);
  float direction;
  color colour=color(0, 255, 120);
  boolean check;
  PVector travel;
  int count=0;
  PVector reference;
  float correctionDistance=0;

  Blob() {
  }
  Blob(String name, PVector position, PVector velocity, float mass, boolean check) {
    this.name=name; 
    this.position=position;
    this.travel=velocity;
    this.mass=mass;
    this.check=check;
    this.radius=10*sqrt(mass/PI);
    this.speed=25/pow(radius, 0.439);
  }

  void show() {
    fill(colour);
    this.radius=10*sqrt(mass/PI);
    ellipse(position.x, position.y, radius*2, radius*2); 
    fill(255);
    textSize(radius/3);
    text(name+"\n"+int(mass), position.x, position.y);
  }

  void decay() {
    this.mass=mass*(1-0.000002);
  }

  void move() {
    PVector newvelocity = new PVector(mouseX-(width/2-reference.x+position.x), mouseY-(height/2-reference.y+position.y));
    float speed=22/pow(radius, 0.439);
    newvelocity.setMag(speed);
    this.velocity.lerp(newvelocity, 0.1);
    if (this.check)
      travel();
    this.position.add(velocity);
  }

  boolean checkDinner(Food food) {
    PVector vector = PVector.sub(position, food.position);
    float vectorMag = vector.mag();
    boolean status;
    if (vectorMag<radius) {
      mass+=food.mass;
      status=true;
    } else
      status=false;
    return status;
  }

  void divide() {
    this.mass/=2;
  }

  void releaseMass() {
    this.mass-=16;
  }

  void travel() {
    if (this.count<30) {
      this.position.sub(travel.mult(0.998));
      this.count++;
    }
    else{
     this.count=0;
     this.check=false;
    }
  }
  
  void setReference(PVector reference){
    this.reference= reference;
  }
  
  void checkCollision(Blob other){
    if(!(other.check)&&!(this.check)){
      PVector distanceVect =  PVector.sub(this.position, other.position);
      float distanceVectMag= distanceVect.mag();
      float angle = distanceVect.heading();
      float minDistance = this.radius+other.radius;
      if(distanceVectMag<minDistance){
        float newCorrection = (minDistance - distanceVectMag)/2;
        this.correctionDistance = lerp(correctionDistance, newCorrection, 1);
       PVector correctionVect = new PVector(cos(angle), sin(angle));
       this.position.add(new PVector(correctionVect.x*correctionDistance, correctionVect.y*correctionDistance));
       other.position.sub(new PVector(correctionVect.x*correctionDistance, correctionVect.y*correctionDistance));
      }
    }
  }
  
  void checkBoundaryCollision(){
   if(position.x-radius<-dimension/2){
    float correction = -dimension/2-(position.x-radius);
    position.x+=correction;
   }
   if(position.x+radius>dimension/2){
    float correction = dimension/2-(position.x+radius);
    position.x+=correction;
   }
   if(position.y+radius>dimension/2){
    float correction = dimension/2-(position.y+radius);
    position.y+=correction;
   }
   if(position.y-radius<-dimension/2){
    float correction = -dimension/2-(position.y-radius);
    position.y+=correction;
   }
  }
}
