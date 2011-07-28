# Prim's algorithm
#
# finds a minimum spanning tree for a connected weighted graph
#
# http://en.wikipedia.org/wiki/Prim's_algorithm
#
# usage:
#   ruby -Ilib sample/prim.rb
#

require 'depq'

def prim(edge_set)
  vertex_set1 = {}
  adj = {}
  weight = {}
  edge_set.each {|v1, v2, w|
    vertex_set1[v1] = true
    vertex_set1[v2] = true
    adj[v1] ||= []
    adj[v1] << v2
    adj[v2] ||= []
    adj[v2] << v1
    weight[[v1, v2]] = weight[[v2, v1]] = w
  }
  adj.default = []

  start = vertex_set1.first[0]
  q = Depq.new
  vertex_set2 = {start => true}
  edge_set2 = []
  prev_locators = {}

  adj[start].each {|v2|
    prev_locators[v2] = [start, q.insert(v2, weight[[start, v2]])]
  }

  while vertex_set2.size < vertex_set1.size
    v2 = q.delete_min
    v1, _ = prev_locators[v2]
    prev_locators.delete v2
    vertex_set2[v2] = true
    edge_set2 << [v1, v2]
    adj[v2].each {|v3|
      next if vertex_set2[v3]
      if prev_loc = prev_locators[v3]
        _, loc = prev_loc
        if weight[[v2, v3]] < loc.priority
          prev_loc[0] = v2
          loc.update v3, weight[[v2, v3]]
        end
      else
        prev_locators[v3] = [v2, q.insert(v3, weight[[v2, v3]])]
      end
    }
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

  p prim(E)
  #=> [["A", "D"], ["D", "F"], ["A", "B"], ["B", "E"], ["E", "C"], ["E", "G"]]
end

