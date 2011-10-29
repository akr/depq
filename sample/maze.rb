# solve a maze using A* search algorithm
#
# usage:
#   ruby -Isample -Ilib sample/maze.rb

require_relative 'astar'

Pos = Struct.new(:x, :y)

MAZE_MAP = <<'End'
OOOOOOOOOOOOOOOOOOOOOOOOO
O         OSO   O       O
O OOOOOOOOO O O OOO OOO O
O         O   O   O O   O
O OOOOOOO OOOOOOO OOO O O
O     O   O     O     O O
OOOOO O O OOO OOOOOOOOO O
OG  O O O   O     O O   O
O O O O OOO OOO O O O OOO
O O O O O       O   O   O
O OOO O OOOOOOOOOOOOOOO O
O     O                 O
OOOOOOOOOOOOOOOOOOOOOOOOO
End

MAZE = MAZE_MAP.lines.map {|line| line.chomp.split(//) }

H = HEIGHT = MAZE.length
W = WIDTH = MAZE[0].length

MAZE.each_with_index {|line,y|
  line.each_with_index {|cell,x|
    if cell == 'S'
      START = Pos[x,y]
      MAZE[y][x] = ' '
    elsif cell == 'G'
      GOAL = Pos[x,y]
      MAZE[y][x] = ' '
    end
  }
}

find_nexts4 = proc {|pos|
  x, y = pos.x, pos.y
  r = []
  r << [Pos[x-1,y],1] if 0 < x && MAZE[y][x-1] == ' '
  r << [Pos[x,y-1],1] if 0 < y && MAZE[y-1][x] == ' '
  r << [Pos[x+1,y],1] if x < W-1 && MAZE[y][x+1] == ' '
  r << [Pos[x,y+1],1] if y < H-1 && MAZE[y+1][x] == ' '
  r
}

heuristics4 = proc {|pos|
  x, y = pos.x, pos.y
  (x-GOAL.x).abs + (y-GOAL.y).abs
}

find_nexts8 = proc {|pos|
  x, y = pos.x, pos.y
  r = []
  r << [[x-1,y],1] if 0 < x && MAZE[y][x-1] == ' '
  r << [[x,y-1],1] if 0 < y && MAZE[y-1][x] == ' '
  r << [[x+1,y],1] if x < W-1 && MAZE[y][x+1] == ' '
  r << [[x,y+1],1] if y < H-1 && MAZE[y+1][x] == ' '
  r << [[x-1,y-1],2] if 0 < x && 0 < y && MAZE[y-1][x-1] == ' '
  r << [[x-1,y+1],2] if 0 < x && y < H-1 && MAZE[y+1][x-1] == ' '
  r << [[x+1,y-1],2] if x < W-1 && 0 < y && MAZE[y-1][x+1] == ' '
  r << [[x+1,y+1],2] if x < W-1 && y < H-1 && MAZE[y+1][x+1] == ' '
  r
}

heuristics8 = proc {|pos|
  x, y = pos.x, pos.y
  (x-GOAL.x).abs + (y-GOAL.y).abs
}

t1 = Time.now
searched = {}
path = astar(START, heuristics4, &find_nexts4).each {|prev, cur, w|
  searched[cur] = [searched[prev], cur]
  if cur == GOAL
    break searched[cur].flatten.compact
  end
}
t2 = Time.now
p t2-t1

searched.each_key {|pos|
  x, y = pos.x, pos.y
  MAZE[y][x] = '.'
}

path.each {|pos|
  x, y = pos.x, pos.y
  MAZE[y][x] = '*'
}

MAZE[START.y][START.x] = 'S'
MAZE[GOAL.y][GOAL.x] = 'G'

MAZE.each {|line|
  puts line.join('')
}
