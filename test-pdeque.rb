require 'pdeque'
require 'test/unit'

class PDeque
  module SimpleHeap
    def validation(pd, ary)
      0.upto(size(ary)-1) {|i|
        _, x = get_entry(ary, i)
        j = i*2+1
        k = i*2+2
        if j < size(ary) && !upper?(pd, ary, i, j)
          _, y = get_entry(ary, j)
          raise "wrong binary heap: pri[#{i}]=#{x.inspect} > #{y.inspect}=pri[#{j}]"
        end
        if k < size(ary) && !upper?(pd, ary, i, k)
          _, z = get_entry(ary, k)
          raise "wrong binary heap: pri[#{i}]=#{x.inspect} > #{z.inspect}=pri[#{k}]"
        end
      }
    end
  end

  def validation
    @mode.validation(self, @ary) if @mode
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
      unless self.equal? loc.pdeque 
        raise "pdeque mismatch"
      end
      i += 1
    }
  end
end

class TestPDeque < Test::Unit::TestCase
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
    pd = PDeque.new
    n = 10
    a1 = []
    n.times {
      r = rand(n)
      a1 << r
      pd.insert(r)
      if incremental
        pd.send find
        pd.validation
      end
    }
    a1.sort!(&cmp)
    a2 = []
    n.times {
      a2 << pd.send(delete)
      pd.validation
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
      pd = PDeque.new
      a1.each {|v|
        pd.insert v
        if incremental
          pd.find_min
          pd.validation
        end
      }
      pd.find_min
      pd.validation
      a0.each {|v|
        assert_equal(v, pd.delete_min)
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
        pd = PDeque.new
        a1.each_with_index {|v,i|
          pd.insert v
          #log << v
          if n[i] != 0
            pd.find_min
            pd.validation
            #log << :find_min
          end
        }
        #p log
        a0.each {|v|
          assert_equal(v, pd.delete_min)
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
    pd = PDeque.new
    pd.insert "a", 0
    pd.insert "b", 0
    pd.insert "c", 0
    assert_equal("a", pd.delete_min)
    assert_equal("b", pd.delete_min)
    assert_equal("c", pd.delete_min)
  end

  def test_stable_max
    pd = PDeque.new
    pd.insert "a", 0
    pd.insert "b", 0
    pd.insert "c", 0
    assert_equal("a", pd.delete_max)
    assert_equal("b", pd.delete_max)
    assert_equal("c", pd.delete_max)
  end

  def test_locator_new
    pd = PDeque.new
    loc1 = PDeque::Locator.new(1)
    loc2 = PDeque::Locator.new(2, 3)
    assert_equal(1, loc1.value)
    assert_equal(1, loc1.priority)
    assert_equal(2, loc2.value)
    assert_equal(3, loc2.priority)
    pd.insert_locator loc1
    pd.insert_locator loc2
    assert_equal(loc1, pd.delete_min_locator)
    assert_equal(loc2, pd.delete_min_locator)
  end

  def test_locator_eql
    loc1 = PDeque::Locator.new(1,2,3)
    loc2 = PDeque::Locator.new(1,2,3)
    assert(!loc1.eql?(loc2))
  end

  def test_locator_priority
    pd = PDeque.new
    loc2 = pd.insert(Object.new, 2)
    loc1 = pd.insert(Object.new, 1)
    loc3 = pd.insert(Object.new, 3)
    assert_equal(1, loc1.priority)
    assert_equal(2, loc2.priority)
    assert_equal(3, loc3.priority)
    pd.delete_locator(loc1)
    assert_equal(1, loc1.priority)
  end

  def test_locator_update_min
    pd = PDeque.new
    a = pd.insert("a", 2)
    b = pd.insert("b", 1)
    c = pd.insert("c", 3)
    assert_equal(b, pd.find_min_locator)
    a.update("d", 0)
    assert_equal("d", a.value)
    assert_equal(a, pd.find_min_locator)
    a.update("e", 10)
    assert_equal("b", pd.delete_min)
    assert_equal("c", pd.delete_min)
    assert_equal("e", pd.delete_min)
    a.update "z", 20
    assert_equal("z", a.value)
    assert_equal(20, a.priority)
  end

  def test_locator_update_subpriority_min
    pd = PDeque.new
    a = pd.insert("a", 1, 0)
    b = pd.insert("b", 2, 1)
    c = pd.insert("c", 1, 2)
    d = pd.insert("d", 2, 3)
    e = pd.insert("e", 1, 4)
    f = pd.insert("f", 2, 5)
    assert_equal(a, pd.find_min_locator)
    a.update("A", 1, 10)
    assert_equal(c, pd.find_min_locator)
    a.update("aa", 1, 1)
    assert_equal(a, pd.find_min_locator)
    pd.delete_locator a
    assert_equal(c, pd.find_min_locator)
    a.update("aaa", 10, 20)
    assert_equal("aaa", a.value)
    assert_equal(10, a.priority)
    assert_equal(20, a.subpriority)
  end

  def test_locator_update_subpriority_max
    pd = PDeque.new
    a = pd.insert("a", 1, 0)
    b = pd.insert("b", 2, 1)
    c = pd.insert("c", 1, 2)
    d = pd.insert("d", 2, 3)
    e = pd.insert("e", 1, 4)
    f = pd.insert("f", 2, 5)
    assert_equal(b, pd.find_max_locator)
    b.update("B", 2, 6)
    assert_equal(d, pd.find_max_locator)
    b.update("bb", 2, 0)
    assert_equal(b, pd.find_max_locator)
    pd.delete_locator b
    assert_equal(d, pd.find_max_locator)
    b.update("bbb", -1, -2)
    assert_equal("bbb", b.value)
    assert_equal(-1, b.priority)
    assert_equal(-2, b.subpriority)
  end

  def test_locator_update_max
    pd = PDeque.new
    a = pd.insert("a", 2)
    b = pd.insert("b", 1)
    c = pd.insert("c", 3)
    assert_equal(c, pd.find_max_locator)
    b.update("d", 10)
    assert_equal("d", b.value)
    assert_equal(b, pd.find_max_locator)
    b.update("e", 0)
    assert_equal("c", pd.delete_max)
    assert_equal("a", pd.delete_max)
    assert_equal("e", pd.delete_max)
  end

  def test_locator_update_value
    pd = PDeque.new
    loc = pd.insert 1, 2, 3
    assert_equal(1, loc.value)
    assert_equal(2, loc.priority)
    assert_equal(3, loc.subpriority)
    loc.update_value 10
    assert_equal(10, loc.value)
    assert_equal(2, loc.priority)
    assert_equal(3, loc.subpriority)
  end

  def test_locator_update_priority
    pd = PDeque.new
    loc = pd.insert 1, 2, 3
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
    pd.delete_min
    assert_equal(1, loc.value)
    assert_equal(40, loc.priority)
    assert_equal(30, loc.subpriority)
    loc.update_priority 50, nil
    assert_equal(1, loc.value)
    assert_equal(50, loc.priority)
    assert_equal(nil, loc.subpriority)
  end

  def test_locator_subpriority
    pd = PDeque.new
    loc1 = pd.insert(Object.new, 1, 11)
    loc2 = pd.insert(Object.new, 2, 12)
    loc3 = pd.insert(Object.new, 3, 13)
    assert_equal(1, loc1.priority)
    assert_equal(11, loc1.subpriority)
    assert_equal(2, loc2.priority)
    assert_equal(12, loc2.subpriority)
    assert_equal(3, loc3.priority)
    assert_equal(13, loc3.subpriority)
    pd.delete_locator(loc1)
    assert_equal(11, loc1.subpriority)
  end

  def test_new
     pd = PDeque.new
     pd.insert "Foo"
     pd.insert "bar"
     assert_equal("Foo", pd.delete_min)
     assert_equal("bar", pd.delete_min)
  
     pd = PDeque.new(:casecmp)
     pd.insert "Foo"
     pd.insert "bar"
     assert_equal("bar", pd.delete_min)
     assert_equal("Foo", pd.delete_min)
  
     pd = PDeque.new(lambda {|a,b| a.casecmp(b) })
     pd.insert "Foo"
     pd.insert "bar"
     assert_equal("bar", pd.delete_min)
     assert_equal("Foo", pd.delete_min)
  end

  def test_dup
    pd = PDeque.new
    pd.insert 1
    pd2 = pd.dup
    pd.validation
    pd2.validation
    pd.insert 2
    pd2.validation
    assert_equal(1, pd2.delete_min)
    pd.validation
    pd2.validation
    assert_equal(nil, pd2.delete_min)
    pd.validation
    pd2.validation
    assert_equal(1, pd.delete_min)
    pd.validation
    pd2.validation
    assert_equal(2, pd.delete_min)
    assert_equal(nil, pd.delete_min)
  end

  def test_marshal
    pd = PDeque.new
    pd.insert 1
    pd2 = Marshal.load(Marshal.dump(pd))
    pd.validation
    pd2.validation
    pd.insert 2
    pd2.validation
    assert_equal(1, pd2.delete_min)
    pd.validation
    pd2.validation
    assert_equal(nil, pd2.delete_min)
    pd.validation
    pd2.validation
    assert_equal(1, pd.delete_min)
    pd.validation
    pd2.validation
    assert_equal(2, pd.delete_min)
    assert_equal(nil, pd.delete_min)
  end

  def test_compare_priority
    pd = PDeque.new
    assert_operator(pd.compare_priority("a", "b"), :<, 0)
    assert_operator(pd.compare_priority("a", "a"), :==, 0)
    assert_operator(pd.compare_priority("b", "a"), :>, 0)
    pd = PDeque.new(:casecmp)
    assert_operator(pd.compare_priority("a", "b"), :<, 0)
    assert_operator(pd.compare_priority("a", "B"), :<, 0)
    assert_operator(pd.compare_priority("A", "b"), :<, 0)
    assert_operator(pd.compare_priority("A", "B"), :<, 0)
    assert_operator(pd.compare_priority("a", "a"), :==, 0)
    assert_operator(pd.compare_priority("a", "A"), :==, 0)
    assert_operator(pd.compare_priority("A", "a"), :==, 0)
    assert_operator(pd.compare_priority("A", "A"), :==, 0)
    assert_operator(pd.compare_priority("b", "a"), :>, 0)
    assert_operator(pd.compare_priority("b", "A"), :>, 0)
    assert_operator(pd.compare_priority("B", "a"), :>, 0)
    assert_operator(pd.compare_priority("B", "A"), :>, 0)
    pd = PDeque.new(lambda {|a,b| [a[1],a[0]] <=> [b[1],b[0]]})
    assert_operator(pd.compare_priority([0,0], [0,0]), :==, 0)
    assert_operator(pd.compare_priority([0,0], [0,1]), :<, 0)
    assert_operator(pd.compare_priority([0,0], [1,0]), :<, 0)
    assert_operator(pd.compare_priority([0,0], [1,1]), :<, 0)
    assert_operator(pd.compare_priority([0,1], [0,0]), :>, 0)
    assert_operator(pd.compare_priority([0,1], [0,1]), :==, 0)
    assert_operator(pd.compare_priority([0,1], [1,0]), :>, 0)
    assert_operator(pd.compare_priority([0,1], [1,1]), :<, 0)
    assert_operator(pd.compare_priority([1,0], [0,0]), :>, 0)
    assert_operator(pd.compare_priority([1,0], [0,1]), :<, 0)
    assert_operator(pd.compare_priority([1,0], [1,0]), :==, 0)
    assert_operator(pd.compare_priority([1,0], [1,1]), :<, 0)
    assert_operator(pd.compare_priority([1,1], [0,0]), :>, 0)
    assert_operator(pd.compare_priority([1,1], [0,1]), :>, 0)
    assert_operator(pd.compare_priority([1,1], [1,0]), :>, 0)
    assert_operator(pd.compare_priority([1,1], [1,1]), :==, 0)
  end

  def test_empty?
    pd = PDeque.new
    assert(pd.empty?)
    pd.insert 1
    assert(!pd.empty?)
  end

  def test_size
    pd = PDeque.new
    pd.insert 1
    assert_equal(1, pd.size)
    pd.insert 10
    assert_equal(2, pd.size)
    pd.insert 2
    assert_equal(3, pd.size)
    pd.delete_max
    assert_equal(2, pd.size)
  end

  def test_totalcount
    pd = PDeque.new
    assert_equal(0, pd.totalcount)
    pd.insert 1
    assert_equal(1, pd.totalcount)
    pd.insert 2
    assert_equal(2, pd.totalcount)
    pd.delete_min
    assert_equal(2, pd.totalcount)
    pd.insert 4
    assert_equal(3, pd.totalcount)
    pd.insert 3
    assert_equal(4, pd.totalcount)
    pd.insert 0
    assert_equal(5, pd.totalcount)
    pd.delete_min
    assert_equal(5, pd.totalcount)
    pd.insert 2
    assert_equal(6, pd.totalcount)
  end

  def test_clear
    pd = PDeque.new
    pd.insert 1
    assert(!pd.empty?)
    pd.clear
    assert(pd.empty?)
  end

  def test_insert
    pd = PDeque.new
    pd.insert 1
    pd.insert 10
    pd.insert 2
    assert_equal(1, pd.delete_min)
    assert_equal(2, pd.delete_min)
    assert_equal(10, pd.delete_min)
  end

  def test_insert_all
    pd = PDeque.new
    pd.insert_all [3,1,2]
    assert_equal(1, pd.delete_min)
    assert_equal(2, pd.delete_min)
    assert_equal(3, pd.delete_min)
    assert_equal(nil, pd.delete_min)
  end

  def test_find_min_locator
    pd = PDeque.new
    pd.insert 1
    loc = pd.find_min_locator
    assert_equal(1, loc.value)
    assert_equal(1, loc.priority)
    assert_equal(pd, loc.pdeque)
    assert_equal(1, pd.delete_min)
    assert_equal(nil, loc.pdeque)
  end

  def test_find_min
    pd = PDeque.new
    pd.insert 1
    assert_equal(1, pd.find_min)
  end

  def test_find_min_priority
    pd = PDeque.new
    pd.insert "a", 1
    assert_equal(["a", 1], pd.find_min_priority)
    pd.delete_min
    assert_equal(nil, pd.find_min_priority)
  end

  def test_find_max_locator
    pd = PDeque.new
    pd.insert 1
    loc = pd.find_max_locator
    assert_equal(1, loc.value)
    assert_equal(1, loc.priority)
    assert_equal(pd, loc.pdeque)
  end

  def test_find_max
    pd = PDeque.new
    pd.insert 1
    assert_equal(1, pd.find_max)
  end

  def test_find_max_priority
    pd = PDeque.new
    pd.insert "a", 1
    assert_equal(["a", 1], pd.find_max_priority)
    pd.delete_max
    assert_equal(nil, pd.find_max_priority)
  end

  def test_find_minmax_locator
    pd = PDeque.new
    assert_equal([nil, nil], pd.find_minmax_locator)
    loc3 = pd.insert 3
    loc1 = pd.insert 1
    pd.insert 2
    res = pd.find_minmax_locator
    assert_equal([loc1, loc3], res)
  end

  def test_find_minmax
    pd = PDeque.new
    assert_equal([nil, nil], pd.find_minmax)
    pd.insert 3
    pd.insert 1
    pd.insert 2
    res = pd.find_minmax
    assert_equal([1, 3], res)
  end

  def test_delete_locator
    pd = PDeque.new
    loc = pd.insert 1
    pd.delete_locator loc
    assert(pd.empty?)
    pd = PDeque.new
    loc = pd.insert 2
    pd.insert 3
    pd.insert 1
    assert_equal(1, pd.find_min)
    pd.delete_locator(loc)
    assert_equal(1, pd.delete_min)
    assert_equal(3, pd.delete_min)
  end

  def test_delete_min
    pd = PDeque.new
    pd.insert 1
    pd.insert 2
    pd.insert 0
    assert_equal(0, pd.delete_min)
    assert_equal(1, pd.delete_min)
    assert_equal(2, pd.delete_min)
    assert_equal(nil, pd.delete_min)
  end

  def test_delete_min_locator
    pd = PDeque.new
    loc1 = pd.insert 1
    loc2 = pd.insert 2
    loc0 = pd.insert 0
    assert_equal(loc0, pd.delete_min_locator)
    assert_equal(loc1, pd.delete_min_locator)
    assert_equal(loc2, pd.delete_min_locator)
    assert_equal(nil, pd.delete_min_locator)
  end

  def test_delete_max
    pd = PDeque.new
    pd.insert 1
    pd.insert 2
    pd.insert 0
    assert_equal(2, pd.delete_max)
    assert_equal(1, pd.delete_max)
    assert_equal(0, pd.delete_max)
    assert_equal(nil, pd.delete_max)
  end

  def test_delete_max_locator
    pd = PDeque.new
    loc1 = pd.insert 1
    loc2 = pd.insert 2
    loc0 = pd.insert 0
    assert_equal(loc2, pd.delete_max_locator)
    assert_equal(loc1, pd.delete_max_locator)
    assert_equal(loc0, pd.delete_max_locator)
    assert_equal(nil, pd.delete_max)
  end

  def test_delete_unspecified
    pd = PDeque.new
    a1 = [1,2,0]
    a1.each {|v|
      pd.insert v
    }
    a2 = []
    a1.length.times {
      a2 << pd.delete_unspecified
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, pd.delete_unspecified_locator)
  end

  def test_delete_unspecified_priority
    pd = PDeque.new
    a1 = [[1,8],[2,3],[0,5]]
    a1.each {|val, priority|
      pd.insert val, priority
    }
    a2 = []
    a1.length.times {
      a2 << pd.delete_unspecified_priority
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, pd.delete_unspecified_locator)
  end

  def test_delete_unspecified_locator
    pd = PDeque.new
    a1 = [1,2,0]
    a1.each {|v|
      pd.insert v
    }
    a2 = []
    a1.length.times {
      a2 << pd.delete_unspecified_locator.value
    }
    assert_equal(a1.sort, a2.sort)
    assert_equal(nil, pd.delete_unspecified_locator)
  end

  def test_each
    pd = PDeque.new
    a = [1,2,0]
    a.each {|v|
      pd.insert v
    }
    pd.each {|v|
      assert(a.include? v)
    }
  end

  def test_each_with_priority
    pd = PDeque.new
    h = {}
    h["durian"] = 1
    h["banana"] = 3
    h["melon"] = 2
    h.each {|val, prio|
      pd.insert val, prio
    }
    pd.each_with_priority {|val, prio|
      assert_equal(h[val], prio)
    }
  end

  def test_each_locator
    pd = PDeque.new
    a = [1,2,0]
    a.each {|v|
      pd.insert v
    }
    pd.each_locator {|loc|
      assert(a.include? loc.value)
    }
  end

  def test_nlargest
    a = PDeque.nlargest(3, [5, 1, 3, 2, 4, 6, 7])
    assert_equal([5, 6, 7], a)

    assert_equal([1,2], PDeque.nlargest(3, [1,2]))

    a = []
    2000.times { a << rand }
    b = a.sort
    assert_equal(b[-30..-1], PDeque.nlargest(30, a))
  end

  def test_nsmallest
    a = PDeque.nsmallest(5, [5, 2, 3, 1, 4, 6, 7])
    assert_equal([1, 2, 3, 4, 5], a)

    assert_equal([1,2], PDeque.nsmallest(3, [1,2]))

    a = []
    2000.times { a << rand }
    b = a.sort
    assert_equal(b[0, 30], PDeque.nsmallest(30, a))
  end

  def test_merge
    a = []
    PDeque.merge(1..4, 3..6) {|v| a << v }
    assert_equal([1,2,3,3,4,4,5,6], a)
  end

  def test_merge_enumerator
    loc = PDeque.merge(1..4, 3..6)
    assert_equal(1, loc.next)
    assert_equal(2, loc.next)
    assert_equal(3, loc.next)
    assert_equal(3, loc.next)
    assert_equal(4, loc.next)
    assert_equal(4, loc.next)
    assert_equal(5, loc.next)
    assert_equal(6, loc.next)
    assert_raise(StopIteration) { loc.next }
  end

  def test_merge_enumerator2
    loc = PDeque.merge(1..4, 3..6)
    a = []
    loc.each_slice(2) {|x|
      a << x
    }
    assert_equal([[1,2],[3,3],[4,4],[5,6]], a)
  end

end
