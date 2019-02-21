
const {hypot, sqrt, floor, round, min, max, PI, random, abs} = Math

class Cell {
  constructor(owner, x, y, mass) {
    this.owner = owner

    this.x = x
    this.y = y
    this.setMass(mass)
    this.color = rgb(0, 0, 0)

    this.boostX = 0
    this.boostY = 0
    this.boostMaxSpeed = 80

    this.startTime = Date.now()
  }

  setColor(color) {
    this.color = color
  }

  setMass(mass) {
    this.mass = mass
    this.radius = sqrt(mass / PI)
  }

  setBoost(boostX, boostY) {
    this.boostX = boostX
    this.boostY = boostY
    this.boostMaxSpeed = hypot(boostX, boostY)
  }

  addBoost(boostX, boostY) {
    this.setBoost(this.boostX + boostX, this.boostY + boostY)
  }

  addMass(mass) {
    this.setMass(this.mass + mass)
  }
}

class Virus extends Cell {
  constructor(x, y, mass) {
    super(null, x, y, mass)
    this.setColor(rgb(34, 246, 58))
  }
}

class Spawner extends Virus {
  constructor(x, y, mass) {
    super(x, y, mass)
    this.setColor(rgb(255, 71, 71))
  }
}

class Food extends Cell {
  constructor(x, y, mass, color) {
    super(null, x, y, mass)
    this.setColor(color)
  }
}

class EjectedMass extends Cell {
  constructor(x, y, mass, color) {
    super(null, x, y, mass)
    this.setColor(color)
  }
}

class Player {
  constructor(state) {
    this.game = state
    this.cells = new Set
    // cells and food which are visible by the player
    this.viewNodes = new Set

    this.viewWidth = 1920
    this.viewHeight = 1080
    this.viewCenterX = 0
    this.viewCenterY = 0
    this.viewScale = 11
    this.viewBox = {x: 0, y: 0, width: 0, height: 0}

    this.mouseX = 0
    this.mouseY = 0
  }

  setMousePosition(x, y) {
    this.mouseX = x
    this.mouseY = y
  }

  updateScale() {
    let cells = [...this.cells]

    const totalRadius = cells.map(cell => cell.radius).reduce((a, b) => a + b)
    this.viewZoom = (totalRadius / (1 + cells.length / 12) * 4 + 112)
    this.viewScale = max(this.viewHeight, this.viewWidth) / this.viewZoom
  }

  updateCenterPosition() {
    let cells = [...this.cells]

    this.viewCenterX = cells
      .map(cell => cell.x)
      .reduce((a, b) => a + b)
    / cells.length
    this.viewCenterY = cells
      .map(cell => cell.y)
      .reduce((a, b) => a + b)
    / cells.length
  }

  updateViewBox() {
    let scale = this.viewScale
    let width = this.viewWidth / scale
    let height = this.viewHeight / scale
    this.viewBox = {
      x: this.viewCenterX - width / 2,
      y: this.viewCenterY - height / 2,
      width, height
    }
  }

  setViewSize(width, height) {
    this.viewWidth = width
    this.viewHeight = height
    this.viewAspectRatio = this.viewWidth / this.viewHeight
    this.updateViewBox()
  }

  addCell(cell) {
    this.cells.add(cell)
  }

  removeCell(cell) {
    this.cells.delete(cell)
  }

  ejectMass() {
    this.cells.forEach(cell => {
      let {x, y, screenDistance} = getMouseDirection(this, cell.x, cell.y)

      let ejectedMass = new EjectedMass(cell.x + x * (cell.radius + 1),
                                        cell.y + y * (cell.radius + 1), 16, cell.color)

      ejectedMass.setBoost(x * 64, y * 64)

      addNode(this.game, ejectedMass)
      cell.addMass(-16)
    })
  }

  split() {
    let i = 0
    ;[...this.cells].map(cell => {
      if (this.cells.size + i >= 16 || cell.mass / 2 < 16) return

      i += 1

      let {x, y, screenDistance} = getMouseDirection(this, cell.x, cell.y)
      cell.setMass(cell.mass / 2)

      let speed = min(max(screenDistance, 16), 36) * 2

      let newCell = new Cell(this, cell.x, cell.y, cell.mass)
      newCell.setColor(cell.color)
      cell.addBoost(-x * (72 - speed), -y * (72 - speed))
      newCell.setBoost(x * (speed), y * (speed))

      return newCell
    })
      .forEach(cell => cell && addNode(this.game, cell))
  }
}

// The game state (cells, center position, viewport, ...)
class State {
  constructor(player) {
    this.player = player
    this.cells = []
  }

  setBorder(width, height) {
    let hw = width / 2
    let hh = height / 2

    this.border = {
      minx: -hw,
      miny: -hh,
      maxx: hw,
      maxy: hh,
      width: width,
      height: height
    }
  }

  setMousePosition(x, y) {
    this.mouseX = x
    this.mouseY = y
  }
}

/*
    Game Logic
  */

/** Split mass into maximum cell count and return cell masses */
function virusSplitMass(mass, cellCount, maxCells, minMass) {
  if (cellCount > maxCells || mass < minMass) return []

  let masses = virusSplitMass(mass / 2, cellCount + 1, maxCells, minMass)

  return [
    ...masses.length > 0
    ? virusSplitMass(mass / 2, cellCount + masses.length, maxCells, minMass)
    : [mass],
    ...masses
  ]
}

function virusSplitCell(game, player, cell) {
  let masses = virusSplitMass(cell.mass, player.cells.size, 16, 16)

  cell.setMass(masses.splice(0, 1))

  masses
    .sort((a, b) => 0.5 - Math.random())
    .forEach((mass, i, masses) => {
    let a = i / masses.length * Math.PI * 2
    let x = Math.cos(a)
    let y = Math.sin(a)

    let newCell = new Cell(cell.owner, cell.x, cell.y, mass)
    newCell.setColor(cell.color)
    newCell.setBoost(x * 72, y * 72)

    addNode(game, newCell)
  })
}

function boostCell(cell, deltaTime) {
  cell.x += cell.boostX * deltaTime
  cell.y += cell.boostY * deltaTime
  let speed = hypot(cell.boostX, cell.boostY) || 0.0000001
  cell.boostX /= 1 + (16 / speed) * deltaTime + deltaTime
  cell.boostY /= 1 + (16 / speed) * deltaTime + deltaTime
}

function getMouseDirection(player, x, y) {
  let [screenX, screenY] = worldToScreen(player, x, y)

  let vx = (player.mouseX - screenX)
  let vy = (player.mouseY - screenY)
  if (Math.abs(vx) < 2) vx = 0
  if (Math.abs(vy) < 2) vy = 0
  let distance = Math.hypot(vx, vy)

  if (distance == 0) {
    vx = 1
    vy = 0
  } else {
    vx /= distance
    vy /= distance
  }

  return {
    x: vx,
    y: vy,
    screenDistance: distance,
  }
}

function movePlayerCell(cell, player, deltaTime) {
  let {x, y, screenDistance} = getMouseDirection(player, cell.x, cell.y)

  let speed = min(screenDistance, 70) * 0.4 * cell.radius ** -0.4

  let dx = x * speed || 0
  let dy = y * speed || 0

  cell.x += dx * deltaTime
  cell.y += dy * deltaTime
}

function checkAABBCollision(a, b) {
  return a.x < b.x + b.width &&
    a.x + a.width > b.x &&
    a.y < b.y + b.height &&
    a.height + a.y > b.y
}

function checkCellCollision(cell1, cell2) {
  let dx = cell2.x - cell1.x
  let dy = cell2.y - cell1.y
  let distance = hypot(dx, dy)

  if (distance < cell1.radius + cell2.radius) {
    return { dx, dy, distance, cell1, cell2 }
  }
}

function resolveRigidCollision(collision, deltaTime) {
  let {distance, dx, dy, cell1, cell2} = collision

  if (distance == 0) {
    distance = 0.0001
    dx += 0.0001
  }
  const push = (cell1.radius + cell2.radius - distance) / distance
  if (push == 0) return
  const rt = cell1.radius + cell2.radius
  const r1 = push * cell1.radius / rt
  const r2 = push * cell2.radius / rt

  let v = max((1 - max(hypot(cell1.boostX, cell1.boostY), hypot(cell2.boostX, cell2.boostY)) / max(cell1.boostMaxSpeed, cell2.boostMaxSpeed)) * 2 - 0.6, 0)

  cell1.x -= dx * r2 * min(deltaTime * 48, 1) * v
  cell1.y -= dy * r2 * min(deltaTime * 48, 1) * v
  cell2.x += dx * r1 * min(deltaTime * 48, 1) * v
  cell2.y += dy * r1 * min(deltaTime * 48, 1) * v
}

function checkCellCollisions(game, deltaTime) {
  for (let i = 0; i < game.cells.length; i++) {
    for (let j = i + 1; j < game.cells.length; j++) {
      let cell1 = game.cells[i]
      let cell2 = game.cells[j]

      if (cell1.constructor == Cell && cell2.constructor == Cell) {
        let collision = checkCellCollision(cell1, cell2)

        if (collision) {
          resolveRigidCollision(collision, deltaTime)
        }
      }
    }
  }
}

function update(game, deltaTime) {
  // boostCell([...state.player.viewNodes][1], deltaTime)
  // movePlayerCell([...state.player.viewNodes][0], state.player, deltaTime)

  const {player} = game

  game.cells.forEach(cell => {
    boostCell(cell, deltaTime)
    if (cell.owner) {
      movePlayerCell(cell, cell.owner, deltaTime)
    }
  })

  checkCellCollisions(game, deltaTime)

  player.updateCenterPosition()
  player.updateViewBox()
  player.updateScale()

  player.viewNodes = game.cells.filter(cell => checkAABBCollision(
    player.viewBox,
    {x: cell.x - cell.radius, y: cell.y - cell.radius, width: cell.radius * 2, height: cell.radius * 2}
  ))
}

function addNode(state, cell) {
  state.cells.push(cell)
  if (cell.owner) {
    cell.owner.addCell(cell)
  }
}

function removeNode(state, cell) {
  state.cells.splice(state.cells.indexOf(cell), 1)
  if (cell.owner) {
    cell.owner.removeCell(cell)
  }
}

function setup(state, canvas, onReset) {
  let player = new Player(state)

  {
    let cell = new Cell(player, 0, 0, 1000)
    cell.setColor(getRandomColor())
    addNode(state, cell)

    // setTimeout(() => {
    //   virusSplitCell(state, player, cell)
    // }, 10000)
  }

  {
    let cell = new Cell(null, 0, 0, 1000)
    cell.setColor(getRandomColor())
    addNode(state, cell)
  }

  {
    let cell = new Cell(null, 0, 30, 60)
    cell.setColor(getRandomColor())
    addNode(state, cell)
  }

  for (var i = 0; i < 20; i++) {
    let food = new Food(-80 + i * 8, 8, min(6, 1 + i / 4), getRandomColor())
    addNode(state, food)
  }

  addNode(state, new Virus(40, -3, 100))
  addNode(state, new Spawner(-40, -10, 200))
  addNode(state, new Virus(30, 26, 185))

  const onResize = (width, height) => {
    canvas.width = width
    canvas.height = height
  }

  setupEventHandlers(player, onResize, onReset)

  state.player = player

  return {player}
}

/*
    Rendering
  */

/** Get screen position from world coordinates for the player's view */
function worldToScreen(player, x, y) {
  return [
    player.viewWidth / 2 + (x - player.viewCenterX) * player.viewScale,
    player.viewHeight / 2 + (y - player.viewCenterY) * player.viewScale
  ]
}

function drawFood(player, ctx, food) {
  // prevent useless recalculations for every frame
  if (!food._vertices || food._lastRadius != food.radius) {
    const vertexCount = floor(food.radius * 2.5) + 5

    food._vertices = []
    food._lastRadius = food.radius
    let rotation = random() * Math.PI

    for (let i = 0; i <= vertexCount; i += 1) {
      let a = i / (vertexCount / 2) * Math.PI + rotation

      food._vertices.push({
        x: food.x + food.radius * Math.cos(a),
        y: food.y + food.radius * Math.sin(a)
      })
    }
  }

  ctx.beginPath()
  for (let {x, y} of food._vertices) {
    ctx.lineTo(...worldToScreen(player, x, y))
  }
  ctx.closePath()

  ctx.fillStyle = colorToString(food.color)
  ctx.fill()
}

const brightness = ([r, g, b]) => (r * 0.3 + g * 0.57 + b * 0.13) / 256

function drawCell(player, ctx, cell, isEjectedMass, settings) {
  let [x, y] = worldToScreen(player, cell.x, cell.y)
  ctx.beginPath()
  ctx.arc(x, y, (cell.radius - 0.25) * player.viewScale, 0, Math.PI * 2)
  ctx.fillStyle = colorToString(cell.color)
  ctx.fill()
  ctx.lineWidth = 0.5 * (1 + cell.radius * 0.012) * player.viewScale * (isEjectedMass ? 1.5 : 1)
  ctx.strokeStyle = colorToString(blacken(cell.color, isEjectedMass ? 0.08 : 0.12))
  ctx.stroke()

  let showNickname = cell.owner && cell.owner.nickname
  if (settings.showMass || showNickname) {
    ctx.font = "14px Roboto"
    ctx.textAlign = "center"
    ctx.fillStyle = brightness(cell.color) < 0.6 ? "#fff" : "#333"

    if (settings.showMass) {
      ctx.fillText(round(cell.mass), x, y + 8 + (showNickname ? 12 : 0))
    }

    if (showNickname) {
      ctx.font = "16px Roboto"
      ctx.fillText(cell.owner.nickname, x, y + (settings.showMass ? 0 : 4))
    }
  }
}

function drawVirus(player, ctx, virus) {
  const spikeCount = Math.round(virus.radius * 1.2) * 6

  // prevent useless recalculations for every frame
  if (!virus._spikes || virus._lastRadius != virus.radius) {
    virus._spikes = []

    for (let i = 0; i <= spikeCount * 2; i += 1) {
      let a = i / spikeCount * Math.PI
      let extra = i % 2 === 0 ? -.5 : -.1

      virus._spikes.push({
        x: virus.x + (virus.radius + extra) * Math.cos(a),
        y: virus.y + (virus.radius + extra) * Math.sin(a)
      })
    }

    virus._lastRadius = virus.radius
  }

  ctx.beginPath()
  for (let {x, y} of virus._spikes) {
    ctx.lineTo(...worldToScreen(player, x, y))
  }
  ctx.closePath()

  ctx.fillStyle = colorToString(virus.color)
  ctx.fill()

  ctx.lineWidth = 0.5 * player.viewScale
  ctx.strokeStyle = colorToString(blacken(virus.color, 0.11))
  ctx.stroke()
}

function drawNode(player, ctx, cell, settings) {
  switch (cell.constructor) {
    case Food:
      drawFood(player, ctx, cell)
      break
    case Virus:
    case Spawner:
      drawVirus(player, ctx, cell)
      break
    case Cell:
    case EjectedMass:
      drawCell(player, ctx, cell, cell instanceof EjectedMass, settings)
      break
  }
}

function drawGrid(player, ctx, settings) {
  let gridSize = player.viewScale * 4
  ctx.beginPath()
  let xOff = (player.viewWidth / 2 - player.viewCenterX * player.viewScale) % gridSize
  let yOff = (player.viewHeight / 2 - player.viewCenterY * player.viewScale) % gridSize
  for (let i = 0; i < player.viewWidth / gridSize + 1; i++) {
    let x = i * gridSize + xOff
    ctx.moveTo(x, 0)
    ctx.lineTo(x, player.viewHeight)
  }
  for (let i = 0; i < player.viewHeight / gridSize + 1; i++) {
    let y = i * gridSize + yOff
    ctx.moveTo(0, y)
    ctx.lineTo(player.viewWidth, y)
  }
  ctx.lineWidth = 1

  const getGridColor = settings.darkTheme
  ? opacity => `rgba(255, 255, 255, ${opacity * 0.65})`
  : opacity => `rgba(0, 0, 0, ${opacity})`


  ctx.strokeStyle = getGridColor(min(max(player.viewScale * 0.02 - .04, 0), 0.12))
  ctx.stroke()
}

/**
    Render everthing from player's view
  */
function draw(player, ctx, deltaTime, settings) {
  ctx.fillStyle = settings.darkTheme ? "rgb(28, 28, 34)" : "rgb(255, 255, 255)"
  ctx.fillRect(0, 0, player.viewWidth, player.viewHeight)

  drawGrid(player, ctx, settings)
  player.viewNodes.forEach(cell => drawNode(player, ctx, cell, settings))
}

function setupEventHandlers(player, onResize, onReset) {
  // Mouse events
  const onMouseUpdate = e => {
    player.setMousePosition(e.clientX, e.clientY)
  }
  window.addEventListener("mousemove", onMouseUpdate)

  // Key events
  window.addEventListener("keydown", e => {
    switch (e.key) {
      case " ": player.split(); break
      case "t": for (let i = 0; i < 4; i++) {
        player.split()
      }
      case "w": player.ejectMass(); break
      case "r": onReset(); break
      case "q": player.toggleBotMode(); break
    }
  })

  const updateViewSize = player => {
    const {innerWidth: width, innerHeight: height} = window
    player.setViewSize(width, height)
    onResize(width, height)
  }

  // Set initial window size
  updateViewSize(player)
  player.mouseX = player.viewWidth / 2
  player.mouseY = player.viewHeight / 2

  window.addEventListener("resize", e => updateViewSize(player))
}

function runGameLoop(frameCallback) {
  let lastTime = Date.now()

  let fps = 0
  let lastFpsResetTime = Date.now()
  let frames = 0
  let seconds = 0

  const frame = () => {
    const elapsedSeconds = (Date.now() - lastTime) / 1000
    lastTime = Date.now()

    frames += 1
    seconds += elapsedSeconds
    if (Date.now() - lastFpsResetTime > 150) {
      fps = round(frames / seconds)
      frames = 0
      seconds = 0
      lastFpsResetTime = Date.now()
    }

    // process logic and render
    frameCallback(elapsedSeconds, fps)

    requestAnimationFrame(frame)
  }

  frame()
}

// Color functions

const getRandomColor = () => {
  let rgb = [242, 45, floor(random() * 120 + 40)]

  rgb.sort(function () {
    return 0.5 - random()
  })

  return rgb
}
const blacken = (color, amount) => color.map(c => floor(c - c * amount))
const colorToString = rgb => `rgb(${rgb.join(",")})`
const rgb = (r, g, b) => [r, g, b]

function getDebugText(state, fps) {
  return [
    ["FPS", fps],
    ["Visible cells", state.player.viewNodes.length]
  ]
    .map(line => `${line[0]}: ${line[1]}`)
    .join("\n")
}

function main() {
  let canvas = document.getElementById("canvas")
  let ctx = canvas.getContext("2d")

  let overlayVisible = false
  let overlay = document.getElementById("overlay")
  let debugText = document.getElementById("debugText")
  let showMass = document.getElementById("showMass")
  let darkTheme = document.getElementById("darkTheme")
  let nicknameInput = document.getElementById("nickname")
  let playButton = document.getElementById("play")

  let settingsJson = window.localStorage.getItem("settings")

  let settings = settingsJson ? JSON.parse(settingsJson) : {
    showMass: false,
    darkTheme: false
  }

  const setOverlayVisible = visible => {
    if (overlayVisible == visible) return
    overlay.classList.toggle("visible", visible)
    overlayVisible = visible
  }

  document.addEventListener("keydown", e => {
    if (e.key == "Escape") {
      setOverlayVisible(!overlayVisible)
    }
  })

  setOverlayVisible(true)

  const backupSettings = () => {
    window.localStorage.setItem("settings", JSON.stringify(settings))
  }

  showMass.addEventListener("change", e => {settings.showMass = showMass.checked; backupSettings()})
  showMass.checked = settings.showMass

  darkTheme.addEventListener("change", e => {settings.darkTheme = darkTheme.checked; backupSettings()})
  darkTheme.checked = settings.darkTheme

  nicknameInput.addEventListener("input", e => {
    let value = nicknameInput.value
    player.nickname = value
    window.localStorage.setItem("nickname", value)
  })
  nicknameInput.value = window.localStorage.getItem("nickname") || ""

  playButton.addEventListener("click", e => {
    setOverlayVisible(false);
  })

  let state = new State()

  let {player} = setup(state, canvas, () => {
    state = new State()
    player = setup(state, canvas).player;
  })

  player.nickname = nicknameInput.value

  let lastDebugUpdateTime = Date.now() - 200

  runGameLoop((deltaTime, fps) => {
    let currentTime = Date.now()

    if (currentTime - lastDebugUpdateTime > 200) {
      debugText.innerText = getDebugText(state, fps)
      lastDebugUpdateTime = currentTime
    }

    update(state, deltaTime)
    draw(player, ctx, deltaTime, settings)
  })
}

main()
