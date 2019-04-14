$LOAD_PATH.unshift './lib'

require 'plumo'

def get_load
  out = `uptime`
  /load average: (.+?), (.+?), (.+)/ =~ out
  [$1, $2, $3].map{|x| x.to_f }
end

def get_mem
  out = `free -w -k`
  line = out.split("\n").find{|_line|
    /^Mem: / =~ _line
  }
  cols = line.split(/ +/)
  cols.shift

  cols.map{|x| x.to_f / 1000 }
end

# --------------------------------

$cv_w = 1000
$cv_h = 400
$x = 0
$max_v = 0

$colors = [
  "rgb(100, 100, 100)",
  "rgb(250,   0,   0)",
  "rgb( 20,  80, 255)",
  "rgb( 80, 100,   0)",
  "rgb(220, 180,   0)",
  "rgb(220,   0, 220)",
  "rgb( 40, 200,   0)",
  "rgb(  0, 180, 240)",
  "rgb(180, 180, 180)",
]

$prev_ys = [
  0,
  0,
  0,
  0,
  0,
  0,
  0,
]

$count = 0

$max_v_map = {
  :load => 0,
  :mem => 0
}

$prev_ys_map = {
  :load => [],
  :mem => []
}

def draw_load(plumo, x, offset_y, area_h)
  vs = get_load
  if $max_v_map[:load] < vs.max
    $max_v_map[:load] = vs.max
  end

  ys = []
  prev_ys = $prev_ys_map[:load]
  (0...(vs.size)).to_a.each do |si|
    ys[si] = area_h - ((vs[si].to_f / $max_v_map[:load]) * area_h)

    plumo.line(
      x - 1, (prev_ys[si] || 0),
      x, ys[si],
      color: $colors[si]
    )
  end

  $prev_ys_map[:load] = ys
end

def draw_mem(plumo, x, offset_y, area_h)
  vs = get_mem
  if $max_v_map[:mem] < vs.max
    $max_v_map[:mem] = vs.max
  end

  ys = []
  prev_ys = $prev_ys_map[:mem]
  (0...(vs.size)).to_a.each do |si|
    ys[si] = area_h - ((vs[si].to_f / $max_v_map[:mem]) * area_h)

    plumo.line(
      x - 1, offset_y + (prev_ys[si] || 0),
      x,     offset_y + ys[si],
      color: $colors[si]
    )
  end

  $prev_ys_map[:mem] = ys
end

# --------------------------------

plumo = Plumo.new($cv_w, $cv_h)

plumo.start

plumo.fill_rect(
  0, 0,
  $cv_w, $cv_h,
  color: "#000"
)

loop do
  $count += 1

  $x += 1
  if $x >= $cv_w
    $x = 0
  end

  plumo.fill_rect(
    $x, 0,
    3, $cv_h,
    color: "rgb(0,0,0)"
  )
  plumo.line(
    $x + 2, 0,
    $x + 2, $cv_h,
    color: "rgba(100,100,100, 1)"
  )

  draw_load plumo, $x, 0, 200
  draw_mem plumo, $x, 200, 200

  sleep 5
end
