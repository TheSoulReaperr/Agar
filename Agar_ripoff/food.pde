class Food {
  PVector position = new PVector(random(0, dimension), random(0, dimension)); 
  color colour= color(random(0, 255), random(0, 255), random(0, 255));
  PVector velocity=new PVector(0, 0);
  int mass=1;
  float radius=sqrt(mass)*20;;

  void show() {
    fill(colour);
    ellipse(position.x, position.y, radius, radius);
  }

  void update(){
   position.add(velocity); 
  }
  
  void setVelocity(PVector velocity) {
    this.velocity=velocity;
  }
}
