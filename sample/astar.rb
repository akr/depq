# A* search algorithm
#
# http://en.wikipedia.org/wiki/A*_search_algorithm

require 'depq'

def astar(start, heuristics=nil, &find_nexts)
  Enumerator.new {|y|
    heuristics ||= proc { 0 }
    h = Hash.new {|_, k| h[k] = heuristics.call(k) }
    q = Depq.new
    visited = {start => q.insert([start], h[start])}
    until q.empty?
      path, w1 = q.delete_min_priority
      v1 = path.last
      w1 -= h[v1]
      y.yield path, w1
      find_nexts.call(v1).each {|v2, w2|
        w3 = w1 + w2 + h[v2]
        if !visited[v2]
          visited[v2] = q.insert(path+[v2], w3)
        elsif w3 < visited[v2].priority
          visited[v2].update(path+[v2], w3)
        end
      }
    end
    nil
  }
end
