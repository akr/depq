# external quick sort
#
# usage:
#   ruby -I. sample/exqsort.rb input-file

require 'tmpdir'
require 'depq'

NUM_PIVOTS = 1024
$tmpdir = nil
$filecount = 0

def partition(input)
  q = Depq.new
  fn1 = "#{$tmpdir}/#{$filecount += 1}"
  fn2 = "#{$tmpdir}/#{$filecount += 1}"
  fn3 = "#{$tmpdir}/#{$filecount += 1}"
  open(fn1, "w") {|f1|
    open(fn3, "w") {|f3|
      n1 = n2 = n3 = 0
      input.each_line {|line|
        line = line.chomp
        if q.size < NUM_PIVOTS
          q.insert line
        else
          min, max = q.minmax
          if line <= min
            f1.puts line
            n1 += 1
          elsif line < max
            q.insert line
            if n1 < n2
              f1.puts q.delete_min
              n1 += 1
            else
              f3.puts q.delete_max
              n3 += 1
            end
          else
            f3.puts line
            n3 += 1
          end
        end
      }
    }
  }
  open(fn2, "w") {|f2|
    while !q.empty?
      f2.puts q.delete_min
    end
  }
  if File.size(fn1) == 0
    File.delete fn1
    fn1 = nil
  end
  if File.size(fn2) == 0
    File.delete fn2
    fn2 = nil
  end
  if File.size(fn3) == 0
    File.delete fn3
    fn3 = nil
  end
  [fn1, fn2, fn3]
end

def eqs(input)
  fn1, fn2, fn3 = partition(input)
  r = []
  if fn1
    r.concat(open(fn1) {|f| eqs(f) })
  end
  if fn2
    r << fn2
  end
  if fn3
    r.concat(open(fn3) {|f| eqs(f) })
  end
  r
end

Dir.mktmpdir {|d|
  $tmpdir = d
  fns = eqs(ARGF)
  fns.each {|fn|
    File.foreach(fn) {|line|
      puts line
    }
  }
}
