Gem::Specification.new do |s|
  s.name = 'depq'
  s.version = '0.7'
  s.date = '2014-06-29'
  s.author = 'Tanaka Akira'
  s.email = 'akr@fsij.org'
  s.files = %w[
    README
    lib/depq.rb
    sample/dhondt.rb
    sample/dijkstra.rb
    sample/exqsort.rb
    sample/huffman.rb
    sample/int-3d.rb
    sample/kruskal.rb
    sample/maze.rb
    sample/prim.rb
    sample/sched.rb
  ]
  s.test_files = %w[test/test-depq.rb]
  s.has_rdoc = true
  s.homepage = 'https://github.com/akr/depq'
  s.rubyforge_project = 'depq'
  s.require_path = 'lib'
  s.license = 'BSD-3-Clause'
  s.summary = 'Stable Double-Ended Priority Queue.'
  s.description = <<'End'
depq is a Double-Ended Priority Queue library.
It is a data structure which can insert elements and delete elements with minimum and maximum priority.
If there are elements which has same priority, the element inserted first is chosen.
The priority can be changed after the element is inserted.
End
end
