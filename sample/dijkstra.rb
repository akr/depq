# Dijkstra's single source shortest path finding algorithm
#
# usage:
#   ruby -I. sample/dijkstra.rb

require 'depq'

def dijkstra_shortest_path(start, edges)
  h = {}
  edges.each {|v1, v2, w|
    (h[v1] ||= []) << [v2, w]
  }
  h.default = []
  q = Depq.new
  visited = {start => q.insert([start], 0)}
  until q.empty?
    path, w1 = q.delete_min_priority
    v1 = path.last
    h[v1].each {|v2, w2|
      if !visited[v2]
        visited[v2] = q.insert(path+[v2], w1 + w2)
      elsif w1 + w2 < visited[v2].priority
        visited[v2].update(path+[v2], w1 + w2)     # update val/prio
      end
    }
  end
  result = []
  visited.each_value {|loc|
    result << [loc.value, loc.priority]
  }
  result
end

E = [
  ['A', 'B', 2],
  ['A', 'C', 4],
  ['B', 'C', 1],
  ['C', 'B', 2],
  ['B', 'D', 3],
  ['C', 'D', 1],
]
p dijkstra_shortest_path('A', E)

