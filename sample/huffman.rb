# Huffman coding
#
# usage:
#   ruby -Ilib sample/huffman.rb input-file

require 'depq'

h = Hash.new(0)
ARGF.each {|line|
  line.scan(/\S+/).each {|word|
    h[word] += 1
  }
}

if h.empty?
  exit
end

q = Depq.new

h.each {|word, count|
  q.insert({word => ""}, count)
}

while 1 < q.size 
  h0, count0 = q.delete_min_priority
  h1, count1 = q.delete_min_priority
  hh = {}
  h0.each {|w, c| hh[w] = "0" + c }
  h1.each {|w, c| hh[w] = "1" + c }
  q.insert hh, count0+count1
end

hh = q.delete_min
hh.keys.sort_by {|w| h[w] }.each {|w| puts "#{hh[w]} #{h[w]} #{w.inspect}" }


