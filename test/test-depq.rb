# test-depq.rb - test for depq.rb
#
# Copyright (C) 2009 Tanaka Akira  <akr@fsij.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

require 'depq'
require 'test/unit'

class Depq
  def mm_validation(&upper)
    0.upto(self.size-1) {|i|
      _, x = get_entry(i)
      j = i*2+1
      k = i*2+2
      if j < self.size && !upper.call(i, j)
        _, y = get_entry(j)
        raise "wrong binary heap: pri[#{i}]=#{x.inspect} > #{y.inspect}=pri[#{j}]"
      end
      if k < self.size && !upper.call(i, k)
        _, z = get_entry(k)
        raise "wrong binary heap: pri[#{i}]=#{x.inspect} > #{z.inspect}=pri[#{k}]"
      end
    }
  end

  def min_validation
    mm_validation &method(:min_upper?)
  end
  MinMode[:validation] = :min_validation

  def max_validation
    mm_validation &method(:max_upper?)
  end
  MaxMode[:validation] = :max_validation

  def itv_validation
    range=0...self.size
    range.each {|j|
      imin = parent_minside(j)
      imax = parent_maxside(j)
      jmin = minside(j)
      if minside?(j) && range.include?(imin) && pcmp(imin, j) > 0
        raise "ary[#{imin}].priority > ary[#{j}].priority "
      end
      if maxside?(j) && range.include?(imax) && pcmp(imax, j) < 0
        raise "ary[#{imax}].priority < ary[#{j}].priority "
      end
      if range.include?(imin) && pcmp(imin, j) == 0 && scmp(imin, j) > 0
        raise "ary[#{imin}].subpriority < ary[#{j}].subpriority "
      end
      if range.include?(imax) && pcmp(imax, j) == 0 && scmp(imax, j) > 0
        raise "ary[#{imax}].subpriority < ary[#{j}].subpriority "
      end
      if maxside?(j) && range.include?(jmin) && pcmp(jmin, j) == 0 && scmp(jmin, j) > 0
        raise "ary[#{jmin}].subpriority < ary[#{j}].subpriority "
      end
    }
  end
  IntervalMode[:validation] = :itv_validation

  def validation
    send(Mode[@mode][:validation]) if @mode
    if @ary.length % ARY_SLICE_SIZE != 0
      raise "wrong length"
    end
    i = 0
    each_entry {|loc, priority|
      if !loc.in_queue?
        raise "wrongly deleted"
      end
      if loc.send(:index) != i
        raise "index mismatch"
      end
      unless self.equal? loc.depq
        raise "depq mismatch"
      end
      i += 1
    }
  end
end

class TestDepq < Test::Unit::TestCase
  def random_test(mode, incremental)
    case mode
    when :min
      find = :find_min
      delete = :delete_min
      cmp = lambda {|a, b| a <=> b }
    when :max
      find = :find_max
      delete = :delete_max
      cmp = lambda {|a, b| b <=> a }
    else
      raise "wrong mode"
    end
    q = Depq.new
    n = 10
    a1 = []
    n.times {
      r = rand(n)
      a1 << r
      q.insert(r)
      if incremental
        q.send find
        q.validation
      end
    }
    a1.sort!(&cmp)
    a2 = []
    n.times {
      a2 << q.send(delete)
      q.validation
    }
    assert_equal(a1, a2)
  end

  def test_random100_minmode
    100.times { random_test(:min, false) }
    100.times { random_test(:min, true) }
    100.times { random_test(:max, false) }
    100.times { random_test(:max, true) }
  end

  def perm_test(ary, incremental)
    a0 = ary.to_a.sort
    a0.permutation {|a1|
      q = Depq.new
      a1.each {|v|
        q.insert v
        if incremental
          q.find_min
          q.validation
        end
      }
      q.find_min
      q.validation
      a0.each {|v|
        assert_equal(v, q.delete_min)
      }
    }
  end

  def test_permutation
    5.times {|n|
      perm_test(0..n, true)
      perm_test(0..n, false)
    }
  end

  def perm_test2(ary)
    a0 = ary.to_a.sort
    a0.permutation {|a1|
      0.upto(2**(a1.length-1)-1) {|n|
        #log = []; p [:n, n, 2**(a1.length-1)-1]
        q = Depq.new
        a1.each_with_index {|v,i|
          q.insert v
          #log << v
          if n[i] != 0
            q.find_min
            q.validation
            #log << :find_min
          end
        }
        #p log
        a0.each {|v|
          assert_equal(v, q.delete_min)
        }
      }
    }
  end

  def test_permutation2
    5.times {|n|
      perm_test2(0..n)
    }
  end

  def test_stable_min
    q = Depq.new
    q.insert "a", 0
    q.insert "b", 0
    q.insert "c", 0
    assert_equal("a", q.delete_min)
    assert_equal("b", q.delete_min)
    assert_equal("c", q.delete_min)
  end

  def test_stable_max
    q = Depq.new
    q.insert "a", 0
    q.insert "b", 0
    q.insert "c", 0
    assert_equal("a", q.delete_max)
    assert_equal("b", q.delete_max)
    assert_equal("c", q.delete_max)
  end

  def test_locator_new
    q = Depq.new
    loc1 = Depq::Locator.new(1)
    loc2 = Depq::Locator.new(2, 3)
    assert_equal(1, loc1.value)
    assert_equal(1, loc1.priority)
    assert_equal(2, loc2.value)
    assert_equal(3, loc2.priority)
    q.insert_locator loc1
    q.insert_locator loc2
    assert_equal(loc1, q.delete_min_locator)
    assert_equal(loc2, q.delete_min_locator)
  end

  def test_locator_dup
    loc = Depq::Locator.new(1)
    assert_raise(TypeError) { loc.dup }
  end

  def test_locator_eql
    loc1 = Depq::Locator.new(1,2,3)
    loc2 = Depq::Locator.new(1,2,3)
    assert(!loc1.eql?(loc2))
  end

  def test_locator_priority
    q = Depq.new
    loc2 = q.insert(Object.new, 2)
    loc1 = q.insert(Object.new, 1)
    loc3 = q.insert(Object.new, 3)
    assert_equal(1, loc1.priority)
    assert_equal(2, loc2.priority)
    assert_equal(3, loc3.priority)
    q.delete_locator(loc1)
    assert_equal(1, loc1.priority)
  end

  def test_locator_update_min
    q = Depq.new
    a = q.insert("a", 2)
    b = q.insert("b", 1)
    c = q.insert("c", 3)
    assert_equal(b, q.find_min_locator)
    a.update("d", 0)
    assert_equal("d", a.value)
    assert_equal(a, q.find_min_locator)
    a.update("e", 10)
    assert_equal("b", q.delete_min)
    assert_equal("c", q.delete_min)
    assert_equal("e", q.delete_min)
    a.update "z", 20
    assert_equal("z", a.value)
    assert_equal(20, a.priority)
  end

  def test_locator_update_subpriority_min
    q = Depq.new
    a = q.insert("a", 1, 0)
    b = q.insert("b", 2, 1)
    c = q.insert("c", 1, 2)
    d = q.insert("d", 2, 3)
    e = q.insert("e", 1, 4)
    f = q.insert("f", 2, 5)
    assert_equal(a, q.find_min_locator)
    a.update("A", 1, 10)
    assert_equal(c, q.find_min_locator)
    a.update("aa", 1, 1)
    assert_equal(a, q.find_min_locator)
    q.delete_locator a
    assert_equal(c, q.find_min_locator)
    a.update("aaa", 10, 20)
    assert_equal("aaa", a.value)
    assert_equal(10, a.priority)
    assert_equal(20, a.subpriority)
  end

  def test_locator_update_subpriority_max
    q = Depq.new
    a = q.insert("a", 1, 0)
    b = q.insert("b", 2, 1)
    c = q.insert("c", 1, 2)
    d = q.insert("d", 2, 3)
    e = q.insert("e", 1, 4)
    f = q.insert("f", 2, 5)
    assert_equal(b, q.find_max_locator)
    b.update("B", 2, 6)
    assert_equal(d, q.find_max_locator)
    b.update("bb", 2, 0)
    assert_equal(b, q.find_max_locator)
    q.delete_locator b
    assert_equal(d, q.find_max_locator)
    b.update("bbb", -1, -2)
    assert_equal("bbb", b.value)
    assert_equal(-1, b.priority)
    assert_equal(-2, b.subpriority)
  end

  def test_locator_update_max
    q = Depq.new
    a = q.insert("a", 2)
    b = q.insert("b", 1)
    c = q.insert("c", 3)
    assert_equal(c, q.find_max_locator)
    b.update("d", 10)
    assert_equal("d", b.value)
    assert_equal(b, q.find_max_locator)
    b.update("e", 0)
    assert_equal("c", q.delete_max)
    assert_equal("a", q.delete_max)
    assert_equal("e", q.delete_max)
  end

  def test_locator_update_value
    q = Depq.new
    loc = q.insert 1, 2, 3
    assert_equal(1, loc.value)
    assert_equal(2, loc.priority)
    assert_equal(3, loc.subpriority)
    loc.update_value 10
    assert_equal(10, loc.value)
    assert_equal(2, loc.priority)
    assert_equal(3, loc.subpriority)
  end

  def test_locator_update_priority
    q = Depq.new
    loc = q.insert 1, 2, 3
    assert_equal(1, loc.value)
    assert_equal(2, loc.priority)
    assert_equal(3, loc.subpriority)
    loc.update_priority 10
    assert_equal(1, loc.value)
    assert_equal(10, loc.priority)
    assert_equal(3, loc.subpriority)
    loc.update_priority 20, 30
    assert_equal(1, loc.value)
    assert_equal(20, loc.priority)
    assert_equal(30, loc.subpriority)
    loc.update_priority 40, nil
    assert_equal(1, loc.value)
    assert_equal(40, loc.priority)
    assert_equal(30, loc.subpriority)
    q.delete_min
    assert_equal(1, loc.value)
    assert_equal(40, loc.priority)
    assert_equal(30, loc.subpriority)
    loc.update_priority 50, nil
    assert_equal(1, loc.value)
    assert_equal(50, loc.priority)
    assert_equal(nil, loc.subpriority)
  end

  def test_locator_minmax_update_priority
    q = Depq.new
    loc = q.insert 1, 2, 3
    q.insert 4, 5, 6
    q.insert 2, 3, 4
    q.insert 3, 4, 5
    assert_equal([1, 4], q.minmax)
    loc.update 7, 8, 9
    assert_equal([2, 7], q.minmax)
  end

  def test_locator_subpriority
    q = Depq.new
    loc1 = q.insert(Object.new, 1, 11)
    loc2 = q.insert(Object.new, 2, 12)
    loc3 = q.insert(Object.new, 3, 13)
    assert_equal(1, loc1.priority)
    assert_equal(11, loc1.subpriority)
    assert_equal(2, loc2.priority)
    assert_equal(12, loc2.subpriority)
    assert_equal(3, loc3.priority)
    assert_equal(13, loc3.subpriority)
    q.delete_locator(loc1)
    assert_equal(11, loc1.subpriority)
  end

  def test_new
     q = Depq.new
     q.insert "Foo"
     q.insert "bar"
     assert_equal("Foo", q.delete_min)
     assert_equal("bar", q.delete_min)

     q = Depq.new(:casecmp)
     q.insert "Foo"
     q.insert "bar"
     assert_equal("bar", q.delete_min)
     assert_equal("Foo", q.delete_min)

     q = Depq.new(lambda {|a,b| a.casecmp(b) })
     q.insert "Foo"
     q.insert "bar"
     assert_equal("bar", q.delete_min)
     assert_equal("Foo", q.delete_min)
  end

  def test_dup
    q = Depq.new
    q.insert 1
    q2 = q.dup
    q.validation
    q2.validation
    q.insert 2
    q2.validation
    assert_equal(1, q2.delete_min)
    q.validation
    q2.validation
    assert_equal(nil, q2.delete_min)
    q.validation
    q2.validation
    assert_equal(1, q.delete_min)
    q.validation
    q2.validation
    assert_equal(2, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_marshal
    q = Depq.new
    q.insert 1
    q2 = Marshal.load(Marshal.dump(q))
    q.validation
    q2.validation
    q.insert 2
    q2.validation
    assert_equal(1, q2.delete_min)
    q.validation
    q2.validation
    assert_equal(nil, q2.delete_min)
    q.validation
    q2.validation
    assert_equal(1, q.delete_min)
    q.validation
    q2.validation
    assert_equal(2, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_compare_priority
    q = Depq.new
    assert_operator(q.compare_priority("a", "b"), :<, 0)
    assert_operator(q.compare_priority("a", "a"), :==, 0)
    assert_operator(q.compare_priority("b", "a"), :>, 0)
    q = Depq.new(:casecmp)
    assert_operator(q.compare_priority("a", "b"), :<, 0)
    assert_operator(q.compare_priority("a", "B"), :<, 0)
    assert_operator(q.compare_priority("A", "b"), :<, 0)
    assert_operator(q.compare_priority("A", "B"), :<, 0)
    assert_operator(q.compare_priority("a", "a"), :==, 0)
    assert_operator(q.compare_priority("a", "A"), :==, 0)
    assert_operator(q.compare_priority("A", "a"), :==, 0)
    assert_operator(q.compare_priority("A", "A"), :==, 0)
    assert_operator(q.compare_priority("b", "a"), :>, 0)
    assert_operator(q.compare_priority("b", "A"), :>, 0)
    assert_operator(q.compare_priority("B", "a"), :>, 0)
    assert_operator(q.compare_priority("B", "A"), :>, 0)
    q = Depq.new(lambda {|a,b| [a[1],a[0]] <=> [b[1],b[0]]})
    assert_operator(q.compare_priority([0,0], [0,0]), :==, 0)
    assert_operator(q.compare_priority([0,0], [0,1]), :<, 0)
    assert_operator(q.compare_priority([0,0], [1,0]), :<, 0)
    assert_operator(q.compare_priority([0,0], [1,1]), :<, 0)
    assert_operator(q.compare_priority([0,1], [0,0]), :>, 0)
    assert_operator(q.compare_priority([0,1], [0,1]), :==, 0)
    assert_operator(q.compare_priority([0,1], [1,0]), :>, 0)
    assert_operator(q.compare_priority([0,1], [1,1]), :<, 0)
    assert_operator(q.compare_priority([1,0], [0,0]), :>, 0)
    assert_operator(q.compare_priority([1,0], [0,1]), :<, 0)
    assert_operator(q.compare_priority([1,0], [1,0]), :==, 0)
    assert_operator(q.compare_priority([1,0], [1,1]), :<, 0)
    assert_operator(q.compare_priority([1,1], [0,0]), :>, 0)
    assert_operator(q.compare_priority([1,1], [0,1]), :>, 0)
    assert_operator(q.compare_priority([1,1], [1,0]), :>, 0)
    assert_operator(q.compare_priority([1,1], [1,1]), :==, 0)
  end

  def test_empty?
    q = Depq.new
    assert(q.empty?)
    q.insert 1
    assert(!q.empty?)
  end

  def test_size
    q = Depq.new
    q.insert 1
    assert_equal(1, q.size)
    q.insert 10
    assert_equal(2, q.size)
    q.insert 2
    assert_equal(3, q.size)
    q.delete_max
    assert_equal(2, q.size)
  end

  def test_totalcount
    q = Depq.new
    assert_equal(0, q.totalcount)
    q.insert 1
    assert_equal(1, q.totalcount)
    q.insert 2
    assert_equal(2, q.totalcount)
    q.delete_min
    assert_equal(2, q.totalcount)
    q.insert 4
    assert_equal(3, q.totalcount)
    q.insert 3
    assert_equal(4, q.totalcount)
    q.insert 0
    assert_equal(5, q.totalcount)
    q.delete_min
    assert_equal(5, q.totalcount)
    q.insert 2
    assert_equal(6, q.totalcount)
  end

  def test_clear
    q = Depq.new
    q.insert 1
    assert(!q.empty?)
    q.clear
    assert(q.empty?)
  end

  def test_insert
    q = Depq.new
    q.insert 1
    q.insert 10
    q.insert 2
    assert_equal(1, q.delete_min)
    assert_equal(2, q.delete_min)
    assert_equal(10, q.delete_min)
  end

  def test_insert_all
    q = Depq.new
    q.insert_all [3,1,2]
    assert_equal(1, q.delete_min)
    assert_equal(2, q.delete_min)
    assert_equal(3, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_find_min_locator
    q = Depq.new
    q.insert 1
    loc = q.find_min_locator
    assert_equal(1, loc.value)
    assert_equal(1, loc.priority)
    assert_equal(q, loc.depq)
    assert_equal(1, q.delete_min)
    assert_equal(nil, loc.depq)
  end

  def test_find_min
    q = Depq.new
    q.insert 1
    assert_equal(1, q.find_min)
  end

  def test_find_min_priority
    q = Depq.new
    q.insert "a", 1
    assert_equal(["a", 1], q.find_min_priority)
    q.delete_min
    assert_equal(nil, q.find_min_priority)
  end

  def test_find_max_locator
    q = Depq.new
    q.insert 1
    loc = q.find_max_locator
    assert_equal(1, loc.value)
    assert_equal(1, loc.priority)
    assert_equal(q, loc.depq)
  end

  def test_find_max
    q = Depq.new
    q.insert 1
    assert_equal(1, q.find_max)
  end

  def test_find_max_priority
    q = Depq.new
    q.insert "a", 1
    assert_equal(["a", 1], q.find_max_priority)
    q.delete_max
    assert_equal(nil, q.find_max_priority)
  end

  def test_find_minmax_locator
    q = Depq.new
    assert_equal([nil, nil], q.find_minmax_locator)
    loc3 = q.insert 3
    assert_equal([loc3, loc3], q.find_minmax_locator)
    loc1 = q.insert 1
    q.insert 2
    res = q.find_minmax_locator
    assert_equal([loc1, loc3], res)
  end

  def test_find_minmax_locator2
    q = Depq.new
    loc1 = q.insert 10
    assert_equal([loc1, loc1], q.find_minmax_locator)
    loc2 = q.insert 10
    assert_equal([loc1, loc1], q.find_minmax_locator)
  end

  def test_find_minmax
    q = Depq.new
    assert_equal([nil, nil], q.find_minmax)
    q.insert 3
    q.insert 1
    q.insert 2
    res = q.find_minmax
    assert_equal([1, 3], res)
  end

  def test_find_minmax_after_min
    q = Depq.new
    assert_equal([nil, nil], q.find_minmax)
    q.insert 3
    q.insert 1
    q.insert 2
    assert_equal(1, q.min)
    res = q.find_minmax
    assert_equal([1, 3], res)
  end

  def test_find_minmax_after_max
    q = Depq.new
    assert_equal([nil, nil], q.find_minmax)
    q.insert 3
    q.insert 1
    q.insert 2
    assert_equal(3, q.max)
    res = q.find_minmax
    assert_equal([1, 3], res)
  end

  def test_delete_locator
    q = Depq.new
    loc = q.insert 1
    q.delete_locator loc
    assert(q.empty?)
    q = Depq.new
    loc = q.insert 2
    q.insert 3
    q.insert 1
    assert_equal(1, q.find_min)
    q.delete_locator(loc)
    assert_equal(1, q.delete_min)
    assert_equal(3, q.delete_min)
  end

  def test_delete_locator_err
    q = Depq.new
    loc = q.insert 1
    q2 = Depq.new
    assert_raise(ArgumentError) { q2.delete_locator(loc) }
  end

  def test_delete_min
    q = Depq.new
    q.insert 1
    q.insert 2
    q.insert 0
    assert_equal(0, q.delete_min)
    assert_equal(1, q.delete_min)
    assert_equal(2, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_delete_min_priority
    q = Depq.new
    q.insert "apple", 1
    q.insert "durian", 2
    q.insert "banana", 0
    assert_equal(["banana", 0], q.delete_min_priority)
    assert_equal(["apple", 1], q.delete_min_priority)
    assert_equal(["durian", 2], q.delete_min_priority)
    assert_equal(nil, q.delete_min_priority)
  end

  def test_delete_min_locator
    q = Depq.new
    loc1 = q.insert 1
    loc2 = q.insert 2
    loc0 = q.insert 0
    assert_equal(loc0, q.delete_min_locator)
    assert_equal(loc1, q.delete_min_locator)
    assert_equal(loc2, q.delete_min_locator)
    assert_equal(nil, q.delete_min_locator)
  end

  def test_delete_max
    q = Depq.new
    q.insert 1
    q.insert 2
    q.insert 0
    assert_equal(2, q.delete_max)
    assert_equal(1, q.delete_max)
    assert_equal(0, q.delete_max)
    assert_equal(nil, q.delete_max)
  end

  def test_delete_max_priority
    q = Depq.new
    q.insert "apple", 1
    q.insert "durian", 2
    q.insert "banana", 0
    assert_equal(["durian", 2], q.delete_max_priority)
    assert_equal(["apple", 1], q.delete_max_priority)
    assert_equal(["banana", 0], q.delete_max_priority)
    assert_equal(nil, q.delete_max)
  end

  def test_delete_max_locator
    q = Depq.new
    loc1 = q.insert 1
    loc2 = q.insert 2
    loc0 = q.insert 0
    assert_equal(loc2, q.delete_max_locator)
    assert_equal(loc1, q.delete_max_locator)
    assert_equal(loc0, q.delete_max_locator)
    assert_equal(nil, q.delete_max)
  end

  def test_delete_max_after_insert
    q = Depq.new
    q.insert 1
    q.insert 2
    q.insert 0
    assert_equal(2, q.delete_max)
    q.insert 3
    assert_equal(3, q.delete_max)
  end

  def test_minmax_after_insert
    q = Depq.new
    q.insert 2
    q.insert 3
    q.insert 1
    assert_equal([1,3], q.minmax)
    q.insert 10
    q.insert 0
    assert_equal([0,10], q.minmax)
  end

  def test_stable_minmax
    q = Depq.new
    q.insert :a, 2
    q.insert :b, 2
    q.insert :c, 1
    q.insert :d, 1
    q.insert :e, 2
    q.insert :f, 1
    q.insert :g, 2
    q.insert :h, 1
    assert_equal([:c, :a], q.minmax)
  end

  def test_stable_minmax2
    q = Depq.new
    q.insert :a, 1, 0
    q.insert :b, 2, 1
    q.insert :c, 2, 2
    assert_equal([:a, :b], q.minmax)
    q.insert :d, 3, 3
    assert_equal([:a, :d], q.minmax)
  end

  def test_minmax_upheap_minside
    q = Depq.new
    q.insert :a, 1, 0
    q.insert :b, 2, 1
    assert_equal([:a, :b], q.minmax)
    q.insert :c, 0, 2
    assert_equal([:c, :b], q.minmax)
  end

  def test_minmax_upheap_minside2
    q = Depq.new
    q.insert :a, 1, 0
    q.insert :b, 2, 1
    assert_equal([:a, :b], q.minmax)
    q.insert :c, 2, 2
    assert_equal([:a, :b], q.minmax)
  end

  def test_minmax_downheap_minside
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 9
    q.insert :c, 2
    q.insert :d, 5
    q.insert :e, 6
    q.insert :f, 7
    assert_equal([:a, :b], q.minmax)
    assert_equal(:a, q.delete_min)
    assert_equal(:c, q.delete_min)
    assert_equal(:d, q.delete_min)
    assert_equal(:e, q.delete_min)
    assert_equal(:f, q.delete_min)
    assert_equal(:b, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_minmax_downheap_minside2
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 9
    q.insert :c, 2, 10
    q.insert :d, 5
    q.insert :e, 2, 9
    q.insert :f, 7
    assert_equal([:a, :b], q.minmax)
    assert_equal(:a, q.delete_min)
    assert_equal(:e, q.delete_min)
    assert_equal(:c, q.delete_min)
    assert_equal(:d, q.delete_min)
    assert_equal(:f, q.delete_min)
    assert_equal(:b, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_minmax_downheap_maxside
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 9
    q.insert :c, 2
    q.insert :d, 7
    q.insert :e, 6
    q.insert :f, 5
    assert_equal([:a, :b], q.minmax)
    assert_equal(:b, q.delete_max)
    assert_equal(:d, q.delete_max)
    assert_equal(:e, q.delete_max)
    assert_equal(:f, q.delete_max)
    assert_equal(:c, q.delete_max)
    assert_equal(:a, q.delete_max)
    assert_equal(nil, q.delete_max)
  end

  def test_minmax_downheap_maxside2
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 9
    q.insert :c, 2
    q.insert :d, 7
    q.insert :e, 6
    q.insert :f, 7
    assert_equal([:a, :b], q.minmax)
    assert_equal(:b, q.delete_max)
    assert_equal(:d, q.delete_max)
    assert_equal(:f, q.delete_max)
    assert_equal(:e, q.delete_max)
    assert_equal(:c, q.delete_max)
    assert_equal(:a, q.delete_max)
    assert_equal(nil, q.delete_max)
  end

  def test_minmax_upheap_sub
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 2
    assert_equal([:a, :b], q.minmax)
    q.insert :c, 1
    assert_equal([:a, :b], q.minmax)
  end

  def test_minmax_downheap_sub
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 5
    q.insert :c, 2
    q.insert :d, 3
    q.insert :e, 5
    q.insert :f, 5
    assert_equal([:a, :b], q.minmax)
  end

  def test_minmax_adjust
    q = Depq.new
    q.insert :a, 1
    q.insert :b, 5
    q.insert :c, 2
    assert_equal([:a, :b], q.minmax)
    q.insert :d, 1
    assert_equal([:a, :b], q.minmax)
  end

  def test_delete_unspecified
    q = Depq.new
    a1 = [1,2,0]
    a1.each {|v|
      q.insert v
    }
    a2 = []
    a1.length.times {
      a2 << q.delete_unspecified
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, q.delete_unspecified_locator)
  end

  def test_delete_unspecified_priority
    q = Depq.new
    a1 = [[1,8],[2,3],[0,5]]
    a1.each {|val, priority|
      q.insert val, priority
    }
    a2 = []
    a1.length.times {
      a2 << q.delete_unspecified_priority
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, q.delete_unspecified_locator)
  end

  def test_delete_unspecified_locator
    q = Depq.new
    a1 = [1,2,0]
    a1.each {|v|
      q.insert v
    }
    a2 = []
    a1.length.times {
      a2 << q.delete_unspecified_locator.value
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, q.delete_unspecified_locator)
  end

  def test_replace_min
    q = Depq.new
    q.insert 1
    q.insert 2
    q.insert 0
    assert_equal(0, q.min)
    loc = q.find_min_locator
    assert_equal(2, loc.subpriority)
    assert_equal(3, q.totalcount)
    assert_equal(loc, q.replace_min(10))
    assert_equal(4, q.totalcount)
    assert_equal(1, q.delete_min)
    assert_equal(2, q.delete_min)
    assert_equal(3, q.find_min_locator.subpriority)
    assert_equal(10, q.delete_min)
    assert_equal(nil, q.delete_min)
  end

  def test_replace_max
    q = Depq.new
    q.insert 3
    q.insert 4
    q.insert 2
    assert_equal(4, q.max)
    loc = q.find_max_locator
    assert_equal(1, loc.subpriority)
    assert_equal(3, q.totalcount)
    assert_equal(loc, q.replace_max(1))
    assert_equal(4, q.totalcount)
    assert_equal(3, q.delete_max)
    assert_equal(2, q.delete_max)
    assert_equal(3, q.find_min_locator.subpriority)
    assert_equal(1, q.delete_max)
    assert_equal(nil, q.delete_max)
  end

  def test_each
    q = Depq.new
    a = [1,2,0]
    a.each {|v|
      q.insert v
    }
    q.each {|v|
      assert(a.include? v)
    }
  end

  def test_each_with_priority
    q = Depq.new
    h = {}
    h["durian"] = 1
    h["banana"] = 3
    h["melon"] = 2
    h.each {|val, prio|
      q.insert val, prio
    }
    q.each_with_priority {|val, prio|
      assert_equal(h[val], prio)
    }
  end

  def test_each_locator
    q = Depq.new
    a = [1,2,0]
    a.each {|v|
      q.insert v
    }
    q.each_locator {|loc|
      assert(a.include? loc.value)
    }
  end

  def test_nlargest
    a = Depq.nlargest(3, [5, 1, 3, 2, 4, 6, 7])
    assert_equal([5, 6, 7], a)

    a = Depq.nlargest(3, [5, 1, 3, 2, 4, 6, 7]) {|e| -e }
    assert_equal([3, 2, 1], a)

    assert_equal([1,2], Depq.nlargest(3, [1,2]))

    a = []
    2000.times { a << rand }
    b = a.sort
    assert_equal(b[-30..-1], Depq.nlargest(30, a))
  end

  def test_nsmallest
    a = Depq.nsmallest(5, [5, 2, 3, 1, 4, 6, 7])
    assert_equal([1, 2, 3, 4, 5], a)

    a = Depq.nsmallest(5, [5, 2, 3, 1, 4, 6, 7]) {|e| -e }
    assert_equal([7, 6, 5, 4, 3], a)

    assert_equal([1,2], Depq.nsmallest(3, [1,2]))

    a = []
    2000.times { a << rand }
    b = a.sort
    assert_equal(b[0, 30], Depq.nsmallest(30, a))
  end

  def test_merge
    a = []
    Depq.merge(1..4, 3..6) {|v| a << v }
    assert_equal([1,2,3,3,4,4,5,6], a)
  end

  def test_merge_enumerator
    e = Depq.merge(1..4, 3..6)
    assert_equal(1, e.next)
    assert_equal(2, e.next)
    assert_equal(3, e.next)
    assert_equal(3, e.next)
    assert_equal(4, e.next)
    assert_equal(4, e.next)
    assert_equal(5, e.next)
    assert_equal(6, e.next)
    assert_raise(StopIteration) { e.next }
  end

  def test_merge_enumerator2
    e = Depq.merge(1..4, 3..6)
    a = []
    e.each_slice(2) {|x|
      a << x
    }
    assert_equal([[1,2],[3,3],[4,4],[5,6]], a)
  end

  def test_merge_empty
    e = Depq.merge(1..4, 2...2, 3..6)
    assert_equal(1, e.next)
    assert_equal(2, e.next)
    assert_equal(3, e.next)
    assert_equal(3, e.next)
    assert_equal(4, e.next)
    assert_equal(4, e.next)
    assert_equal(5, e.next)
    assert_equal(6, e.next)
    assert_raise(StopIteration) { e.next }
  end

end
