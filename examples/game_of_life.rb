load File.join(__dir__, "helper.rb")

require 'plumo'

$w = 200
$h = 200
$grid = []

$cell_width_px = 2
$cv_w = $w * $cell_width_px
$cv_h = $h * $cell_width_px

def each_cell
  (0...$h).each do |y|
    (0...$w).each do |x|
      yield(x, y)
    end
  end
end

def generate_blank_grid
  Array.new($h){ [] }
end

def generate_cmds(grid)
  cmds = []

  cmds << [:fillStyle, "rgb(0, 0, 0)"]
  cmds << [:fillRect, 0, 0, $cv_w, $cv_h]

  cmds << [:fillStyle, "#88aa00"]

  each_cell do |x ,y|
    if grid[y][x] == 1
      cmds << [
        :fillRect,
        x * $cell_width_px,
        y * $cell_width_px,
        $cell_width_px,
        $cell_width_px,
      ]
    end
  end

  cmds
end

def reset_random
  each_cell do |x, y|
    $grid[y][x] = (rand < 0.5) ? 0 : 1
  end
end

# --------------------------------

plumo = Plumo.new(
  $cv_w, $cv_h,
  num_deq_max: 1
)
plumo.start

$grid = generate_blank_grid

reset_random

i = 0

loop do
  i += 1
  if i > 1000
    i = 0
    reset_random
  end

  buf = generate_blank_grid

  each_cell do |x, y|
    xl = (x == 0     ) ? $w - 1 : x - 1
    xr = (x == $w - 1) ? 0      : x + 1
    yt = (y == 0     ) ? $h - 1 : y - 1
    yb = (y == $h - 1) ? 0      : y + 1

    n = 0
    n += $grid[yt][xl]
    n += $grid[y ][xl]
    n += $grid[yb][xl]
    n += $grid[yt][x ]
    n += $grid[yb][x ]
    n += $grid[yt][xr]
    n += $grid[y ][xr]
    n += $grid[yb][xr]

    buf[y][x] =
      if $grid[y][x] == 0
        (n == 3) ? 1 : 0
      else
        (n == 2 or n == 3) ? 1 : 0
      end
  end

  $grid = buf

  cmds = generate_cmds($grid)
  plumo.draw(*cmds)

  sleep 0.001
end
