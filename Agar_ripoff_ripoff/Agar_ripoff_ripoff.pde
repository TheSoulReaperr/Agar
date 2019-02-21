
ArrayList<Blob> player = new ArrayList<Blob>();
ArrayList<Food> food = new ArrayList<Food>();
ArrayList<Throwable> part = new ArrayList<Throwable>();
PVector velocity;
boolean status;
int dimension = 5000;
float zoom=1;
float newzoom;
float speed = 3;
PVector test=new PVector(0, 0);
float angle;
float time;
int count=0;
String name = "Soul";
float initialMass=1000;

void setup() {
  fullScreen();
  textAlign(CENTER, CENTER);
  for (int i=0; i<2000; i++) {
    food.add(new Food());
  }
  player.add(new Blob(name, new PVector(random(-dimension/2, dimension/2), random(-dimension/2, dimension/2)), new PVector(0, 0), initialMass, false));
  noStroke();
}

void draw() {
  background(255);
  translate(width/2, height/2);
  float totalRadius = addRadius();
  newzoom=pow(min(64/(totalRadius), 1), 0.4);
  zoom=lerp(zoom, newzoom, 0.1);
  scale(zoom);
  translate(-player.get(0).position.x, -player.get(0).position.y);
  for (int i =food.size()-1; i>=0; i--) {
    if ((food.get(i).position.x + width/2 - player.get(0).position.x) <= width+ food.get(i).radius+(width+ food.get(i).radius/2)*((1/zoom)-1) &&
      (food.get(i).position.x + width/2 - player.get(0).position.x) >= (-food.get(i).radius)-(width+ food.get(i).radius/2)*((1/zoom)-1)&&
      (food.get(i).position.y + height/2 - player.get(0).position.y) <= (height + food.get(i).radius)+(height+ food.get(i).radius/2)*((1/zoom)-1) &&
      (food.get(i).position.y + height/2 - player.get(0).position.y) >= (-food.get(i).radius)-(height+ food.get(i).radius/2)*((1/zoom)-1)) {
      food.get(i).show();
      for (int j=player.size()-1; j>=0; j--) {
        status = player.get(j).checkDinner(food.get(i));
        if (status) {
          food.remove(i);
          food.add(new Food());
          break;
        }
      }
    }
  }
  for (int i =part.size()-1; i>=0; i--) {
    if ((part.get(i).position.x + width/2 - player.get(0).position.x) <= width+ part.get(i).radius+(width+ part.get(i).radius/2)*((1/zoom)-1) &&
      (part.get(i).position.x + width/2 - player.get(0).position.x) >= (-part.get(i).radius)-(width+ part.get(i).radius/2)*((1/zoom)-1)&&
      (part.get(i).position.y + height/2 - player.get(0).position.y) <= (height + part.get(i).radius)+(height+ part.get(i).radius/2)*((1/zoom)-1) &&
      (part.get(i).position.y + height/2 - player.get(0).position.y) >= (-part.get(i).radius)-(height+ part.get(i).radius/2)*((1/zoom)-1)) {
      part.get(i).show();
      part.get(i).travel();
      for (int j=i-1; j>=0; j--) {
        part.get(i).checkCollision(part.get(j));
      }
      for (int j=player.size()-1; j>=0; j--) {
        status = player.get(j).checkDinner(part.get(i));
        if (status) {
          part.remove(i);
          break;
        }
      }
    }
  }
  for (int i=player.size()-1; i>=0; i--) {
    player.get(i).setReference(player.get(0).position);
    player.get(i).move();
    player.get(i).checkBoundaryCollision();
    for (int j=i-1; j>=0; j--)
      player.get(i).checkCollision(player.get(j));
    player.get(i).show();
    player.get(i).decay();
  }

  //textSize(20);
  //fill(0);
  //text(player.get(0).position.x,player.get(0).position.x, player.get(0).position.y);
}

void keyPressed() {
  if (key == 'W' || key == 'w') {
    for (int i=0; i<player.size(); i++) {
      if (player.get(i).mass>=32) {

        PVector position = player.get(i).position.copy();
        PVector velocity = new PVector((width/2-player.get(0).position.x+player.get(i).position.x)-mouseX, (height/2-player.get(0).position.y+player.get(i).position.y)-mouseY);
        float angle=velocity.heading();
        position.x=position.x-cos(angle)*player.get(i).radius;
        position.y=position.y-sin(angle)*player.get(i).radius;
        velocity.setMag(10);
        part.add(new Throwable(position, velocity, player.get(i).colour));
        player.get(i).releaseMass();
      }
    }
  }
}

void keyReleased() {
  if (key == ' ') {
    for (int i=player.size()-1; i>=0; i--) {
      if (player.get(i).mass>=50) {
        PVector position = player.get(i).position.copy();
        PVector velocity = new PVector(width/2-mouseX, height/2-mouseY);
        float angle=velocity.heading();
        position.x=position.x-cos(angle)*player.get(i).radius/2;
        position.y=position.y-sin(angle)*player.get(i).radius/2;
        velocity.setMag(15);
        player.add(new Blob(player.get(i).name, position, velocity, player.get(i).mass/2, true));
        player.get(i).divide();
      }
    }
  }
}


float addRadius() {
  float radius=0;
  for (int i=0; i<player.size(); i++)
    radius+=player.get(i).radius;
  return radius;
}
