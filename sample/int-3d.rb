# search integers x, y, z from smaller x*y*z where x >= y >= z >= 1.
#
# usage:
#   ruby -Ilib sample/int-3d.rb

require 'depq'

# naive version
def gen1
  q = Depq.new
  q.insert [1, 1,1,1]
  loop {
    ary = q.delete_min
    while q.find_min == ary
      q.delete_min
    end
    yield ary
    w, x,y,z = ary
    x1 = x + 1
    y1 = y + 1
    z1 = z + 1
    q.insert [x1*y*z, x1,y,z] if x1 >= y && y >= z
    q.insert [x*y1*z, x,y1,z] if x >= y1 && y1 >= z
    q.insert [x*y*z1, x,y,z1] if x >= y && y >= z1
  }
end

# sophisticated version
def gen2
  q = Depq.new
  q.insert [1, 1,1,1]
  loop {
    ary = q.delete_min
    yield ary
    w, x,y,z = ary
    x1 = x + 1
    y1 = y + 1
    z1 = z + 1
    q.insert [x1*y*z, x1,y,z]
    q.insert [x*y1*z, x,y1,z] if x == y1
    q.insert [x*y*z1, x,y,z1] if x == y && y == z1
  }
end

gen2 {|w, x,y,z|
  break if 100 <= w
  p [w, x,y,z]
}
