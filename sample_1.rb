$LOAD_PATH.unshift './lib'

require 'plumo'

def rand_color
  "rgba(%f, %f, %f, %f)" % [
    rand * 240,
    rand * 200,
    rand * 120,
    0.5 + rand / 2
   ]
end

def rand_x
  rand * $canvas_w
end

def rand_y
  rand * $canvas_h
end

# --------------------------------

$canvas_w = 400
$canvas_h = 200

plumo = Plumo.new($canvas_w, $canvas_h)
plumo.start

loop do
  plumo.line(
    rand_x, rand_y,
    rand_x, rand_y,
    color: rand_color
  )

  plumo.fill_circle(
    rand_x, rand_y, rand * 50,
    color: rand_color
  )

  width = rand * 50
  plumo.fill_rect(
    rand_x, rand_y,
    width, width,
    color: rand_color
  )

  sleep 0.1
end
