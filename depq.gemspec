Gem::Specification.new do |s|
  s.name = 'depq'
  s.version = '0.5'
  s.date = '2011-10-27'
  s.author = 'Tanaka Akira'
  s.email = 'akr@fsij.org'
  s.files = %w[README lib/depq.rb]
  s.test_files = %w[test/test-depq.rb]
  s.has_rdoc = true
  s.homepage = 'http://depq.rubyforge.org/'
  s.rubyforge_project = 'depq'
  s.require_path = 'lib'
  s.summary = 'Stable Double-Ended Priority Queue.'
  s.description = <<'End'
depq is a Double-Ended Priority Queue library.
It is a data structure which can insert elements and delete elements with minimum and maximum priority.
If there are elements which has same priority, the element inserted first is chosen.
The priority can be changed after the element is inserted.
End
end
