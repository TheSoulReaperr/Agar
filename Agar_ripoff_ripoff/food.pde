class Food {
  PVector position = new PVector(random(-dimension/2, dimension/2), random(-dimension/2, dimension/2)); 
  color colour= color(random(0, 255), random(0, 255), random(0, 255));
  PVector velocity=new PVector(0, 0);
  float mass=1;
  float radius=mass*10;

  void show() {
    fill(colour);
    ellipse(position.x, position.y, radius*2, radius*2);
  }
}
