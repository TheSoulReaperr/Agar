class Throwable extends Food{
   int count;
   PVector travel;
  Throwable(PVector position, PVector velocity){
     this.position=position;
     this.travel=velocity;
     this.mass=20;
     this.radius = 4*pow(mass,0.72);
     this.colour = player.colour; 
  }
  
  void travel(){
    if(count<30)
    position.sub(travel);
    count++;
  }
}
