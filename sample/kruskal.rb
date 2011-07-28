# Kruskal's algorithm
#
# finds a minimum spanning tree for a connected weighted graph
#
# http://en.wikipedia.org/wiki/Kruskal's_algorithm
#
# usage:
#   ruby -Ilib sample/kruskal.rb

require 'depq'

def kruskal(edge_set)
  q = Depq.new
  parent = {}
  edge_set.each {|v1, v2, w|
    parent[v1] = nil
    parent[v2] = nil
    q.insert [v1, v2], w
  }

  edge_set2 = []

  until q.empty?
    v1, v2 = q.delete_min
    r1 = v1
    r1 = parent[r1] while parent[r1]
    r2 = v2
    r2 = parent[r2] while parent[r2]
    if r1 != r2
      edge_set2 << [v1, v2]
      parent[r2] = r1
    end
  end

  edge_set2
end

if $0 == __FILE__
  E = [
    ['A', 'B', 7],
    ['A', 'D', 5],
    ['B', 'C', 8],
    ['B', 'D', 9],
    ['B', 'E', 7],
    ['C', 'E', 5],
    ['D', 'E', 15],
    ['D', 'F', 6],
    ['E', 'F', 8],
    ['E', 'G', 9],
    ['F', 'G', 11],
  ]

  p kruskal(E)
  #=> [["A", "D"], ["C", "E"], ["D", "F"], ["A", "B"], ["B", "E"], ["E", "G"]]
end
