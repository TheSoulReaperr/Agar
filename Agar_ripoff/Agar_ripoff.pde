
Blob player;
ArrayList<Clone> clone = new ArrayList<Clone>();
ArrayList<Food> food = new ArrayList<Food>();
ArrayList<Throwable> part = new ArrayList<Throwable>();
PVector velocity;
boolean status;
int dimension = 5000;

void setup() {
  fullScreen();
  textAlign(CENTER, CENTER);
  //player = new Blob("Soul");
  for (int i=0; i<2000; i++) {
    food.add(new Food());
  }
  player = new Blob("Soul");
  noStroke();
}

void draw() {
  background(255);
    player.move();
    velocity = player.getVelocity();
    for (int i =0; i<food.size(); i++) {
      food.get(i).setVelocity(velocity);
      food.get(i).update();
      if (food.get(i).position.x <= width + food.get(i).radius/2 && food.get(i).position.x >= - food.get(i).radius/2 && food.get(i).position.y <= height + food.get(i).radius/2 && food.get(i).position.y >= -food.get(i).radius/2)
      {
        food.get(i).show();
        status = player.checkDinner(food.get(i));
        if (status) {
          food.remove(i);
          food.add(new Food());
        }
      }
    }
    for (int i =0; i<part.size(); i++) {
    part.get(i).setVelocity(velocity);
      part.get(i).update();
      part.get(i).travel();
      if (part.get(i).position.x <= width + part.get(i).radius/2 && part.get(i).position.x >= - part.get(i).radius/2 && part.get(i).position.y <= height + part.get(i).radius/2 && part.get(i).position.y >= -part.get(i).radius/2)
      {
        part.get(i).show();
        status = player.checkDinner(part.get(i));
        if (status) {
          part.remove(i);
        }
      }
    
    }
    player.show();
    player.checkBoundaryCollision();
}

void keyReleased() {
  if ((key=='W'||key=='w')&&player.mass>48) {
    part.add(new Throwable(new PVector(player.position.x-cos(player.direction)*player.radius/2, player.position.y-sin(player.direction)*player.radius/2),new PVector(cos(player.direction)*10, sin(player.direction)*10)));
    player.releaseMass();
  }
}
