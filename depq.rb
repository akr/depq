# Depq - Feature Rich Double-Ended Priority Queue.
#
# = Features
#
# * queue - you can insert and delete values
# * priority - you can get a value with minimum priority
# * double-ended - you can get a value with maximum priority too
# * stable - you don't need to maintain timestamps yourself
# * update priority - usable for Dijkstra's shortest path algorithm and various graph algorithms
# * implicit binary heap - most operations are O(log n) at worst
#
# = Introduction
#
# == Simple Insertion/Deletion
#
# You can insert values into a Depq object.
# You can deletes the values from the object from ascending/descending order.
# delete_min deletes the minimum value.
# It is used for ascending order.
#
#   pd = Depq.new
#   pd.insert "durian"
#   pd.insert "banana"
#   p pd.delete_min     #=> "banana"
#   pd.insert "orange"
#   pd.insert "apple"
#   pd.insert "melon"
#   p pd.delete_min     #=> "apple"
#   p pd.delete_min     #=> "durian"
#   p pd.delete_min     #=> "melon"
#   p pd.delete_min     #=> "orange"
#   p pd.delete_min     #=> nil
#
# delete_max is similar to delete_min except it deletes maximum element
# instead of minimum.
# It is used for descending order.
#
# == The Order
#
# The order is defined by the priorities corresnponds to the values and
# comparison operator specified for the queue.
#
#   pd = Depq.new(:casecmp)   # use casecmp instead of <=>.
#   pd.inesrt 1, "Foo"          # specify the priority for 1 as "Foo"
#   pd.insert 2, "bar"
#   pd.insert 3, "Baz"
#   p pd.delete_min     #=> 2   # "bar" is minimum
#   p pd.delete_min     #=> 3
#   p pd.delete_min     #=> 1   # "Foo" is maximum
#   p pd.delete_min     #=> nil
#
# If there are multiple values with same priority, subpriority is used to compare them.
# subpriority is an integer which can be specified by 3rd argument of insert.
# If it is not specified, total number of inserted elements is used.
# So Depq is "stable" with delete_min.
# The element inserted first is minimum and deleted first.
#
#   pd = Depq.new
#   pd.insert "a", 1    # "a", "c" and "e" has same priority: 1
#   pd.insert "b", 0    # "b", "d" and "f" has same priority: 0
#   pd.insert "c", 1
#   pd.insert "d", 0
#   pd.insert "e", 1
#   pd.insert "f", 0
#   p pd.delete_min     #=> "b"         first element with priority 0
#   p pd.delete_min     #=> "d"
#   p pd.delete_min     #=> "f"         last element with priority 0
#   p pd.delete_min     #=> "a"         first element with priority 1
#   p pd.delete_min     #=> "c"
#   p pd.delete_min     #=> "e"         last element with priority 1
#
# Note that delete_max is also stable.
# This means delete_max deletes the element with maximum priority with "minimum" subpriority.
#
# == Update Element
#
# An inserted element can be modified and/or deleted.
# This is done using Depq::Locator object.
# It is returned by insert, find_min_locator, etc.
#
#   pd = Depq.new
#   d = pd.insert "durian", 1
#   m = pd.insert "mangosteen", 2
#   c = pd.insert "cherry", 3
#   p m                         #=> #<Depq::Locator: "mangosteen":2>
#   p m.value                   #=> "mangosteen"
#   p m.priority                #=> 2
#   p pd.find_min               #=> "durian"
#   p pd.find_min_locator       #=> #<Depq::Locator: "durian":1>
#   m.update("mangosteen", 0)
#   p pd.find_min               #=> "mangosteen"
#   p pd.find_min_locator       #=> #<Depq::Locator: "mangosteen":0>
#   pd.delete_element d
#   p pd.delete_min             #=> "mangosteen"
#   p pd.delete_min             #=> "cherry"
#   p pd.delete_min             #=> nil
#
# For example, this feature can be used for graph algorithms
# such as Dijkstra's shortest path finding algorithm,
# A* search algorithm, etc.
#
#    def dijkstra_shortest_path(start, edges)
#      h = {}
#      edges.each {|v1, v2, w|
#        (h[v1] ||= []) << [v2, w]
#      }
#      h.default = []
#      q = Depq.new
#      visited = {start => q.insert([start], 0)}
#      until q.empty?
#        path, w1 = q.delete_min_priority
#        v1 = path.last
#        h[v1].each {|v2, w2|
#          if !visited[v2]
#            visited[v2] = q.insert(path+[v2], w1 + w2)
#          elsif w1 + w2 < visited[v2].priority
#            visited[v2].update(path+[v2], w1 + w2)     # update val/prio
#          end
#        }
#      end
#      result = []
#      visited.each_value {|loc|
#        result << [loc.value, loc.priority]
#      }
#      result
#    end
#
#    E = [
#      ['A', 'B', 2],
#      ['A', 'C', 4],
#      ['B', 'C', 1],
#      ['C', 'B', 2],
#      ['B', 'D', 3],
#      ['C', 'D', 1],
#    ]
#    p dijkstra_shortest_path('A', E)
#    #=> [[["A"], 0],
#    #    [["A", "B"], 2],
#    #    [["A", "B", "C"], 3],
#    #    [["A", "B", "C", "D"], 4]]
#
# = Internal Heap Algorithm and Performance Tips
#
# Depq uses min-heap or max-heap internally.
# When delete_min is used, min-heap is constructed and max-heap is destructed.
# When delete_max is used, max-heap is constructed and min-heap is destructed.
# So mixing delete_min and delete_max causes bad performance.
# In future, min-max-heap may be implemented to avoid this problem.
# min-max-heap will be used when delete_min and delete_max is used both.
# (Because min-max-heap is slower than min-heap/max-heap.)
#
class Depq
  include Enumerable

  Locator = Struct.new(:value, :pdeque_or_subpriority, :index_or_priority)
  class Locator

    # if pdeque_or_subpriority is Depq
    #   pdeque_or_subpriority is pdeque
    #   index_or_priority is index
    # else
    #   pdeque_or_subpriority is subpriority
    #   index_or_priority is priority
    # end
    #
    # only 3 fields for memory efficiency.

    private :value=
    private :pdeque_or_subpriority
    private :pdeque_or_subpriority=
    private :index_or_priority
    private :index_or_priority=

    private :to_a
    private :values
    private :size
    private :length
    private :each
    private :each_pair
    private :[]
    private :[]=
    private :values_at
    private :members
    private :select

    Enumerable.instance_methods.each {|m|
      private m
    }

    define_method(:==, Object.instance_method(:eql?))
    define_method(:eql?, Object.instance_method(:eql?))
    define_method(:hash, Object.instance_method(:hash))

    include Comparable

    # Create a Depq::Locator object.
    def initialize(value, priority=value, subpriority=nil)
      super value, subpriority, priority
    end

    def inspect
      prio = self.priority
      if self.value == prio
        s = self.value.inspect
      else
        s = "#{self.value.inspect}:#{prio.inspect}"
      end
      if in_queue?
        "\#<#{self.class}: #{s}>"
      else
        "\#<#{self.class}: #{s} (no queue)>"
      end
    end
    alias to_s inspect

    def initialize_copy(obj) # :nodoc:
      raise TypeError, "can not duplicated"
    end

    # returns true if the locator is in a queue.
    def in_queue?
      pdeque_or_subpriority().kind_of? Depq
    end

    # returns the queue.
    #
    # nil is returned if the locator is not in a pdeque.
    def pdeque
      in_queue? ? pdeque_or_subpriority() : nil
    end
    alias queue pdeque

    def index
      in_queue? ? index_or_priority() : nil
    end
    private :index

    def index=(i)
      if !in_queue?
        raise ArgumentError, "not in queue"
      end
      self.index_or_priority = i
    end
    private :index=

    # returns the priority.
    def priority
      if in_queue?
        pd = pdeque_or_subpriority()
        priority, subpriority = pd.send(:internal_get_priority, self)
        priority
      else
        index_or_priority()
      end
    end

    # returns the subpriority.
    def subpriority
      if in_queue?
        pd = pdeque_or_subpriority()
        priority, subpriority = pd.send(:internal_get_priority, self)
        subpriority
      else
        pdeque_or_subpriority()
      end
    end

    # update the value, priority and subpriority.
    #
    # subpriority cannot be nil if the locator is in a queue.
    # So subpriority is not changed if subpriority is not specified or nil for a locator in a queue.
    # subpriority is set to nil if subpriority is not specified or nil for a locator not in a queue.
    #
    #   pd = Depq.new
    #   loc1 = pd.insert 1, 2, 3
    #   p [loc1.value, loc1.priority, loc1.subpriority] #=> [1, 2, 3]
    #   loc1.update(11, 12)
    #   p [loc1.value, loc1.priority, loc1.subpriority] #=> [11, 12, 3]
    #
    #   loc2 = Depq::Locator.new(4, 5, 6)
    #   p [loc2.value, loc2.priority, loc2.subpriority] #=> [4, 5, 6]
    #   loc2.update(14, 15)
    #   p [loc2.value, loc2.priority, loc2.subpriority] #=> [14, 15, nil]
    #
    # This feature is called as decrease-key/increase-key in
    # Computer Science terminology.
    def update(value, priority=value, subpriority=nil)
      subpriority = Integer(subpriority) if subpriority != nil
      if in_queue?
        pd = pdeque_or_subpriority()
        if subpriority == nil
          subpriority = self.subpriority
        else
          subpriority = Integer(subpriority)
        end
        pd.send(:internal_set_priority, self, priority, subpriority)
      else
        self.index_or_priority = priority
        self.pdeque_or_subpriority = subpriority
      end
      self.value = value
      nil
    end

    # update the value.
    #
    # This method doesn't change the priority and subpriority.
    #
    #   pd = Depq.new
    #   loc = pd.insert 1, 2, 3
    #   p [loc.value, loc.priority, loc.subpriority]    #=> [1, 2, 3]
    #   loc.update_value 10
    #   p [loc.value, loc.priority, loc.subpriority]    #=> [10, 2, 3]
    #
    def update_value(value)
      update(value, self.priority, self.subpriority)
    end

    # update the priority and subpriority.
    #
    # This method doesn't change the value.
    #
    #   pd = Depq.new
    #   loc = pd.insert 1, 2, 3
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 2, 3]
    #   loc.update_priority 10
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 10, 3]
    #   loc.update_priority 20, 30
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 20, 30]
    #
    def update_priority(priority, subpriority=nil)
      update(self.value, priority, subpriority)
    end

    def internal_inserted(pdeque, index)
      raise ArgumentError, "already inserted" if in_queue?
      priority = index_or_priority()
      self.pdeque_or_subpriority = pdeque
      self.index_or_priority = index
      priority
    end
    private :internal_inserted

    def internal_deleted(priority, subpriority)
      raise ArgumentError, "not inserted" if !in_queue?
      self.index_or_priority = priority
      self.pdeque_or_subpriority = subpriority
    end
    private :internal_deleted

  end

  # Create a Depq object.
  #
  # The optional argument, cmp, specify the method to compare priorities.
  # It should be a symbol or a Proc which takes two arguments.
  # If it is omitted, :<=> is used.
  #
  #   pd = Depq.new
  #   pd.insert "Foo"
  #   pd.insert "bar"
  #   p pd.delete_min   #=> "Foo"
  #   p pd.delete_min   #=> "bar"
  #
  #   pd = Depq.new(:casecmp)
  #   pd.insert "Foo"
  #   pd.insert "bar"
  #   p pd.delete_min   #=> "bar"
  #   p pd.delete_min   #=> "Foo"
  #
  #   pd = Depq.new(lambda {|a,b| a.casecmp(b) })
  #   pd.insert "Foo"
  #   pd.insert "bar"
  #   p pd.delete_min   #=> "bar"
  #   p pd.delete_min   #=> "Foo"
  #
  def initialize(cmp = :<=>)
    @cmp = cmp
    @ary = []
    @heapsize = 0
    @mode = nil
    @totalcount = 0
    #@subpriority_generator = nil
  end

  # :stopdoc:
  ARY_SLICE_SIZE = 3
  # :startdoc:

  def get_entry(i)
    locator = @ary[i*ARY_SLICE_SIZE+0]
    priority = @ary[i*ARY_SLICE_SIZE+1]
    subpriority = @ary[i*ARY_SLICE_SIZE+2]
    [locator, priority, subpriority]
  end
  private :get_entry

  def set_entry(i, locator, priority, subpriority)
    tmp = Array.new(ARY_SLICE_SIZE)
    tmp[0] = locator
    tmp[1] = priority
    tmp[2] = subpriority
    @ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE] = tmp
  end
  private :set_entry

  def delete_entry(i)
    locator, priority, subpriority = @ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE]
    @ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE] = []
    [locator, priority, subpriority]
  end
  private :delete_entry

  def each_entry
    0.upto(self.size-1) {|i|
      ei = @ary[i*ARY_SLICE_SIZE+0]
      pi = @ary[i*ARY_SLICE_SIZE+1]
      si = @ary[i*ARY_SLICE_SIZE+2]
      yield ei, pi, si
    }
  end
  private :each_entry

  def min_mode
    if @mode != MinHeap
      @mode = MinHeap
      @heapsize = @mode.heapify(self, @ary)
    elsif @heapsize < self.size
      @heapsize = @mode.heapify(self, @ary, @heapsize)
    end
  end
  private :min_mode

  def max_mode
    if @mode != MaxHeap
      @mode = MaxHeap
      @heapsize = @mode.heapify(self, @ary)
    elsif @heapsize < self.size
      @heapsize = @mode.heapify(self, @ary, @heapsize)
    end
  end
  private :max_mode

  def mode_heapify
    if @mode
      @heapsize = @mode.heapify(self, @ary)
    end
  end
  private :mode_heapify

  def check_locator(loc)
    if !self.equal?(loc.pdeque) ||
       !get_entry(loc.send(:index))[0].equal?(loc)
      raise ArgumentError, "unexpected locator"
    end
  end
  private :check_locator

  def default_subpriority
    #return @subpriority_generator.call if @subpriority_generator
    self.totalcount
  end
  private :default_subpriority

  def compare_for_min(priority1, subpriority1, priority2, subpriority2)
    compare_priority(priority1, priority2).nonzero? or
    (subpriority1 <=> subpriority2)
  end
  private :compare_for_min

  def compare_for_max(priority1, subpriority1, priority2, subpriority2)
    compare_priority(priority1, priority2).nonzero? or
    (subpriority2 <=> subpriority1)
  end
  private :compare_for_max

  def initialize_copy(obj) # :nodoc:
    if defined? @ary
      @ary = @ary.dup
      0.step(@ary.length-1, ARY_SLICE_SIZE) {|k|
        i = k / ARY_SLICE_SIZE
        loc1 = @ary[k]
        priority = @ary[k+1]
        loc2 = Depq::Locator.new(loc1.value, priority)
        loc2.send(:internal_inserted, self, i)
        @ary[k] = loc2
      }
    end
  end

  def inspect # :nodoc:
    unless defined? @cmp
      return "\#<#{self.class}: uninitialized>"
    end
    a = []
    each_entry {|loc, priority|
      value = loc.value
      s = value.inspect
      if value != priority
        s << ":" << priority.inspect
      end
      a << s
    }
    "\#<#{self.class}: #{a.join(' ')}>"
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      each_entry {|loc, priority|
        q.breakable
        value = loc.value
        q.pp value
        if value != priority
          q.text ':'
          q.pp priority
        end
      }
    }
  end

  # compare priority1 and priority2.
  #
  #   pd = Depq.new
  #   p pd.compare_priority("a", "b") #=> -1
  #   p pd.compare_priority("a", "a") #=> 0
  #   p pd.compare_priority("b", "a") #=> 1
  #
  def compare_priority(priority1, priority2)
    if @cmp.kind_of? Symbol
      priority1.__send__(@cmp, priority2)
    else
      @cmp.call(priority1, priority2)
    end
  end

  # returns true if the queue is empty.
  #
  #   pd = Depq.new
  #   p pd.empty?       #=> true
  #   pd.insert 1
  #   p pd.empty?       #=> false
  #   pd.delete_max
  #   p pd.empty?       #=> true
  #
  def empty?
    @ary.empty?
  end

  # returns the number of elements in the queue.
  #
  #   pd = Depq.new
  #   p pd.size         #=> 0
  #   pd.insert 1
  #   p pd.size         #=> 1
  #   pd.insert 1
  #   p pd.size         #=> 2
  #   pd.delete_min
  #   p pd.size         #=> 1
  #   pd.delete_min
  #   p pd.size         #=> 0
  #
  def size
    @ary.size / ARY_SLICE_SIZE
  end
  alias length size

  # returns the total number of elements inserted for the queue, ever.
  #
  # The result is monotonically increased.
  #
  #   pd = Depq.new
  #   p [pd.size, pd.totalcount]        #=> [0, 0]
  #   pd.insert 1
  #   p [pd.size, pd.totalcount]        #=> [1, 1]
  #   pd.insert 2
  #   p [pd.size, pd.totalcount]        #=> [2, 2]
  #   pd.delete_min
  #   p [pd.size, pd.totalcount]        #=> [1, 2]
  #   pd.insert 4
  #   p [pd.size, pd.totalcount]        #=> [2, 3]
  #   pd.insert 3
  #   p [pd.size, pd.totalcount]        #=> [3, 4]
  #   pd.insert 0
  #   p [pd.size, pd.totalcount]        #=> [4, 5]
  #   pd.delete_min
  #   p [pd.size, pd.totalcount]        #=> [3, 5]
  #   pd.insert 2
  #   p [pd.size, pd.totalcount]        #=> [4, 6]
  #
  def totalcount
    @totalcount
  end

  # make the queue empty.
  #
  # Note that totalcount is not changed.
  #
  #   pd = Depq.new
  #   pd.insert 1
  #   pd.insert 1
  #   p pd.size         #=> 2
  #   p pd.totalcount   #=> 2
  #   pd.clear
  #   p pd.size         #=> 0
  #   p pd.totalcount   #=> 2
  #   p pd.find_min     #=> nil
  #
  def clear
    @ary.clear
    @heapsize = 0
    @mode = nil
  end

  def internal_get_priority(loc)
    check_locator(loc)
    locator, priority, subpriority = get_entry(loc.send(:index))
    [priority, subpriority]
  end
  private :internal_get_priority

  def internal_set_priority(loc, priority, subpriority)
    check_locator(loc)
    if @heapsize <= loc.send(:index)
      set_entry(loc.send(:index), loc, priority, subpriority)
    else
      mode_heapify
      @mode.update_priority(self, @ary, loc, priority, subpriority)
    end
  end
  private :internal_set_priority

  # insert the locator to the queue.
  #
  # If loc.subpriority is nil, totalcount is used for stability.
  #
  # The locator should not already be inserted in a queue.
  #
  #   pd = Depq.new
  #   loc = Depq::Locator.new(1)
  #   pd.insert_locator loc
  #   p pd.delete_min           #=> 1
  #
  def insert_locator(loc)
    subpriority = loc.subpriority || default_subpriority
    i = self.size
    priority = loc.send(:internal_inserted, self, i)
    set_entry(i, loc, priority, subpriority)
    @totalcount += 1
    loc
  end

  # insert the value to the queue.
  #
  # If priority is omitted, the value itself is used as the priority.
  #
  # If subpriority is omitted or nil, totalcount is used for stability.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.delete_min   #=> 1
  #   p pd.delete_min   #=> 2
  #   p pd.delete_min   #=> 3
  #
  #   pd = Depq.new
  #   pd.insert 3, 10
  #   pd.insert 1, 20
  #   pd.insert 2, 30
  #   p pd.delete_min   #=> 3
  #   p pd.delete_min   #=> 1
  #   p pd.delete_min   #=> 2
  #
  # This method returns a locator which locates the inserted element.
  # It can be used to update the value and priority, or delete the element.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   loc1 = pd.insert 1
  #   loc2 = pd.insert 2
  #   pd.insert 4
  #   p pd.delete_max           #=> 4
  #   pd.delete_locator loc1
  #   loc2.update 8
  #   p pd.delete_max           #=> 8
  #   p pd.delete_max           #=> 3
  #   p pd.delete_max           #=> nil
  #
  def insert(value, priority=value, subpriority=nil)
    loc = Locator.new(value, priority, subpriority)
    insert_locator(loc)
  end
  alias add insert
  alias put insert
  alias enqueue insert
  alias enq insert
  alias << insert

  # insert all values in iter.
  #
  # The argument, iter, should have each method.
  #
  # This method returns nil.
  #
  #   pd = Depq.new
  #   pd.insert_all [3,1,2]
  #   p pd.delete_min   #=> 1
  #   p pd.delete_min   #=> 2
  #   p pd.delete_min   #=> 3
  #   p pd.delete_min   #=> nil
  #
  def insert_all(iter)
    iter.each {|v|
      insert v
    }
    nil
  end

  # return the locator for the minimum element.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_min_locator     #=> nil
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_min_locator     #=> #<Depq::Locator: 1>
  #
  def find_min_locator
    return nil if empty?
    min_mode
    @mode.find_min_locator(@ary)
  end

  # return the minimum value with its priority.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_min_priority    #=> nil
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   p pd.find_min_priority    #=> ["durian", 1]
  #   pd.clear
  #   p pd.find_min_priority    #=> nil
  #
  def find_min_priority
    loc = find_min_locator and [loc.value, loc.priority]
  end

  # return the minimum value.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_min     #=> nil
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_min     #=> 1
  #
  def find_min
    loc = find_min_locator and loc.value
  end
  alias min find_min
  alias first find_min

  # return the locator for the maximum element.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_max_locator     #=> nil
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_max_locator     #=> #<Depq::Locator: 3>
  #
  def find_max_locator
    return nil if empty?
    max_mode
    @mode.find_max_locator(@ary)
  end

  # return the maximum value with its priority.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_max_priority    #=> nil
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   p pd.find_max_priority    #=> ["banana", 3]
  #   pd.clear
  #   p pd.find_max_priority    #=> nil
  #
  def find_max_priority
    loc = find_max_locator and [loc.value, loc.priority]
  end

  # returns the maximum value.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   pd = Depq.new
  #   p pd.find_max     #=> nil
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_max     #=> 3
  #
  def find_max
    loc = find_max_locator and loc.value
  end
  alias max find_max
  alias last find_max

  # returns the locators for the minimum and maximum element as a two-element array.
  # If the queue is empty, [nil, nil] is returned.
  #
  #   pd = Depq.new
  #   p pd.find_minmax_locator #=> [nil, nil]
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_minmax_locator #=> [#<Depq::Locator: 1>, #<Depq::Locator: 3>]
  #
  def find_minmax_locator
    return [nil, nil] if empty?
    case @mode
    when :min
      loc1 = find_min_locator
      loc2 = loc1
      self.each_locator {|loc|
        if compare_for_max(loc2.priority, loc2.subpriority, loc.priority, loc.subpriority) < 0
          loc2 = loc
        end
      }
    when :max
      loc2 = find_max_locator
      loc1 = loc2
      self.each_locator {|loc|
        if compare_for_min(loc1.priority, loc1.subpriority, loc.priority, loc.subpriority) > 0
          loc1 = loc
        end
      }
    else
      loc1 = loc2 = nil
      self.each_locator {|loc|
        if loc1 == nil || compare_for_min(loc1.priority, loc1.subpriority, loc.priority, loc.subpriority) > 0
          loc1 = loc
        end
        if loc2 == nil || compare_for_max(loc2.priority, loc2.subpriority, loc.priority, loc.subpriority) < 0
          loc2 = loc
        end
      }
    end
    [loc1, loc2]
  end

  # returns the minimum and maximum value as a two-element array.
  # If the queue is empty, [nil, nil] is returned.
  #
  #   pd = Depq.new
  #   p pd.find_minmax  #=> [nil, nil]
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.find_minmax  #=> [1, 3]
  #
  def find_minmax
    loc1, loc2 = self.find_minmax_locator
    [loc1 && loc1.value, loc2 && loc2.value]
  end
  alias minmax find_minmax

  # delete the element specified by the locator.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   loc = pd.insert 2
  #   pd.insert 1
  #   pd.delete_locator loc
  #   p pd.delete_min           #=> 1
  #   p pd.delete_min           #=> 3
  #   p pd.delete_min           #=> nil
  #
  def delete_locator(loc)
    check_locator(loc)
    if @heapsize <= loc.send(:index)
      _, priority, subpriority = delete_entry(loc.send(:index))
      loc.send(:index).upto(self.size-1) {|i|
        loc2, _ = get_entry(i)
        loc2.send(:index=, i)
      }
      loc.send(:internal_deleted, priority, subpriority)
      loc
    else
      mode_heapify
      @heapsize = @mode.delete_locator(self, @ary, loc)
      loc
    end
  end

  # delete the minimum element in the queue and returns the locator.
  #
  # This method returns the locator for the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 2
  #   pd.insert 1
  #   pd.insert 3
  #   p pd.delete_min_locator   #=> #<Depq::Locator: 1 (no queue)>
  #   p pd.delete_min_locator   #=> #<Depq::Locator: 2 (no queue)>
  #   p pd.delete_min_locator   #=> #<Depq::Locator: 3 (no queue)>
  #   p pd.delete_min_locator   #=> nil
  #
  def delete_min_locator
    return nil if empty?
    min_mode
    loc = @mode.find_min_locator(@ary)
    @heapsize = @mode.delete_locator(self, @ary, loc)
    loc
  end

  # delete the minimum element in the queue and returns the value and its priority.
  #
  # This method returns an array which contains the value and its priority
  # of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   p pd.delete_min_priority  #=> ["durian", 1]
  #   p pd.delete_min_priority  #=> ["melon", 2]
  #   p pd.delete_min_priority  #=> ["banana", 3]
  #   p pd.delete_min_priority  #=> nil
  #
  def delete_min_priority
    loc = delete_min_locator
    return nil unless loc
    [loc.value, loc.priority]
  end

  # delete the minimum element in the queue and returns the value.
  #
  # This method returns the value of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.delete_min   #=> 1
  #   p pd.delete_min   #=> 2
  #   p pd.delete_min   #=> 3
  #   p pd.delete_min   #=> nil
  #
  def delete_min
    loc = delete_min_locator
    loc and loc.value
  end
  alias shift delete_min
  alias dequeue delete_min
  alias deq delete_min

  # delete the maximum element in the queue and returns the locator.
  #
  # This method returns the locator for the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 2
  #   pd.insert 1
  #   pd.insert 3
  #   p pd.delete_max_locator   #=> #<Depq::Locator: 3 (no queue)>
  #   p pd.delete_max_locator   #=> #<Depq::Locator: 2 (no queue)>
  #   p pd.delete_max_locator   #=> #<Depq::Locator: 1 (no queue)>
  #   p pd.delete_max_locator   #=> nil
  #
  def delete_max_locator
    return nil if empty?
    max_mode
    loc = @mode.find_max_locator(@ary)
    @heapsize = @mode.delete_locator(self, @ary, loc)
    loc
  end

  # delete the maximum element in the queue and returns the value and its priority.
  #
  # This method returns an array which contains the value and its priority
  # of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   p pd.delete_max_priority  #=> ["banana", 3]
  #   p pd.delete_max_priority  #=> ["melon", 2]
  #   p pd.delete_max_priority  #=> ["durian", 1]
  #   p pd.delete_max_priority  #=> nil
  #
  def delete_max_priority
    loc = delete_max_locator
    return nil unless loc
    [loc.value, loc.priority]
  end

  # delete the maximum element in the queue and returns the value.
  #
  # This method returns the value of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.delete_max   #=> 3
  #   p pd.delete_max   #=> 2
  #   p pd.delete_max   #=> 1
  #   p pd.delete_max   #=> nil
  #
  def delete_max
    loc = delete_max_locator
    loc and loc.value
  end
  alias pop delete_max

  # delete an element in the queue and returns the locator.
  # The element is choosen for fast deletion.
  #
  # This method returns the locator for the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 1
  #   pd.insert 4
  #   pd.insert 3
  #   p pd.delete_unspecified_locator #=> #<Depq::Locator: 3 (no queue)>
  #   p pd.delete_unspecified_locator #=> #<Depq::Locator: 4 (no queue)>
  #   p pd.delete_unspecified_locator #=> #<Depq::Locator: 1 (no queue)>
  #   p pd.delete_unspecified_locator #=> nil
  #
  def delete_unspecified_locator
    return nil if empty?
    loc, _ = get_entry(self.size-1)
    delete_locator(loc)
  end

  # delete an element in the queue and returns the value and its priority.
  # The element is choosen for fast deletion.
  #
  # This method returns an array which contains the value and its priority
  # of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   p pd.delete_unspecified_priority  #=> ["melon", 2]
  #   p pd.delete_unspecified_priority  #=> ["banana", 3]
  #   p pd.delete_unspecified_priority  #=> ["durian", 1]
  #   p pd.delete_unspecified_priority  #=> nil
  #
  def delete_unspecified_priority
    loc = delete_unspecified_locator
    return nil unless loc
    [loc.value, loc.priority]
  end

  # delete an element in the queue and returns the value.
  # The element is choosen for fast deletion.
  #
  # This method returns the value of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   pd = Depq.new
  #   pd.insert 1
  #   pd.insert 4
  #   pd.insert 3
  #   p pd.delete_unspecified   #=> 3
  #   p pd.delete_unspecified   #=> 4
  #   p pd.delete_unspecified   #=> 1
  #   p pd.delete_unspecified   #=> nil
  #
  def delete_unspecified
    loc = delete_unspecified_locator
    return nil unless loc
    loc.value
  end

  # iterate over the locators in the queue.
  #
  # The iteration order is unspecified.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.delete_min           #=> 1
  #   pd.each_locator {|v|
  #     p v     #=> #<Depq::Locator: 2>, #<Depq::Locator: 3>
  #   }
  #
  def each_locator # :yield: locator
    each_entry {|locator, priority|
      yield locator
    }
    nil
  end

  # iterate over the values and priorities in the queue.
  #
  #   pd = Depq.new
  #   pd.insert "durian", 1
  #   pd.insert "banana", 3
  #   pd.insert "melon", 2
  #   pd.each_with_priority {|val, priority|
  #     p [val, priority]
  #   }
  #   #=> ["durian", 1]
  #   #   ["banana", 3]
  #   #   ["melon", 2]
  #
  def each_with_priority # :yield: value, priority
    each_entry {|locator, priority|
      yield locator.value, priority
    }
    nil
  end

  # iterate over the values in the queue.
  #
  # The iteration order is unspecified.
  #
  #   pd = Depq.new
  #   pd.insert 3
  #   pd.insert 1
  #   pd.insert 2
  #   p pd.delete_min   #=> 1
  #   pd.each {|v|
  #     p v     #=> 2, 3
  #   }
  #
  def each # :yield: value
    each_entry {|locator, priority|
      yield locator.value
    }
    nil
  end

  # returns the largest n elements in iter as an array.
  #
  # The result array is ordered from the minimum element.
  #
  #   p Depq.nlargest(3, [5, 2, 3, 1, 4, 6, 7]) #=> [5, 6, 7]
  #
  def Depq.nlargest(n, iter)
    limit = (n * Math.log(1+n)).ceil
    limit = 1024 if limit < 1024
    pd = Depq.new
    threshold = nil
    iter.each {|v|
      if pd.size < n
        if pd.size == 0
          threshold = v
        else
          threshold = v if (v <=> threshold) < 0
        end
        pd.insert v
      else
        if (v <=> threshold) > 0
          pd.insert v
          if limit < pd.size
            tmp = []
            n.times { tmp << pd.delete_max }
            pd.clear
            pd.insert_all tmp
            threshold = tmp.last
          end
        end
      end
    }
    n = pd.size if pd.size < n
    a = []
    n.times { a << pd.delete_max }
    a.reverse!
    a
  end

  # returns the smallest n elements in iter as an array.
  #
  # The result array is ordered from the minimum element.
  #
  #   p Depq.nsmallest(5, [5, 2, 3, 1, 4, 6, 7]) #=> [1, 2, 3, 4, 5]
  #
  def Depq.nsmallest(n, iter)
    limit = (n * Math.log(1+n)).ceil
    limit = 1024 if limit < 1024
    pd = Depq.new
    threshold = nil
    iter.each {|v|
      if pd.size < n
        if pd.size == 0
          threshold = v
        else
          threshold = v if (v <=> threshold) > 0
        end
        pd.insert v
      else
        if (v <=> threshold) < 0
          pd.insert v
          if limit < pd.size
            tmp = []
            n.times { tmp << pd.delete_min }
            pd.clear
            pd.insert_all tmp
            threshold = tmp.last
          end
        end
      end
    }
    n = pd.size if pd.size < n
    a = []
    n.times {
      a << pd.delete_min
    }
    a
  end

  # iterates over iterators specified by arguments.
  #
  # The iteration order is sorted, from minimum to maximum,
  # if all the arugment iterators are sorted.
  #
  #   Depq.merge(1..4, 3..6) {|v| p v }
  #   #=> 1
  #   #   2
  #   #   3
  #   #   3
  #   #   4
  #   #   4
  #   #   5
  #   #   6
  #
  def Depq.merge(*iters, &b)
    pd = Depq.new
    iters.each {|enum|
      enum = enum.to_enum unless enum.kind_of? Enumerator
      begin
        val = enum.next
      rescue StopIteration
        next
      end
      pd.insert enum, val
    }
    loop = lambda {|y, meth|
      until pd.empty?
        loc = pd.find_min_locator
        enum = loc.value
        val = loc.priority
        y.send meth, val
        begin
          val = enum.next
        rescue StopIteration
          pd.delete_locator loc
          next
        end
        loc.update enum, val
      end
    }
    if block_given?
      loop.call(b, :call)
    else
      Enumerator.new {|y|
        loop.call(y, :yield)
      }
    end
  end

  # :stopdoc:

  module SimpleHeap

    def size(ary)
      return ary.size / ARY_SLICE_SIZE
    end

    def get_entry(ary, i)
      locator = ary[i*ARY_SLICE_SIZE+0]
      priority = ary[i*ARY_SLICE_SIZE+1]
      subpriority = ary[i*ARY_SLICE_SIZE+2]
      [locator, priority, subpriority]
    end

    def set_entry(ary, i, locator, priority, subpriority)
      tmp = Array.new(ARY_SLICE_SIZE)
      tmp[0] = locator
      tmp[1] = priority
      tmp[2] = subpriority
      ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE] = tmp
    end

    def delete_entry(ary, i)
      locator, priority, subpriority = ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE]
      ary[i*ARY_SLICE_SIZE, ARY_SLICE_SIZE] = []
      [locator, priority, subpriority]
    end

    def each_entry(ary)
      0.upto(self.size-1) {|i|
        ei = ary[i*ARY_SLICE_SIZE+0]
        pi = ary[i*ARY_SLICE_SIZE+1]
        si = ary[i*ARY_SLICE_SIZE+2]
        yield ei, pi, si
      }
    end

    def swap(ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      set_entry(ary, i, ej, pj, sj)
      set_entry(ary, j, ei, pi, si)
      ei.send(:index=, j)
      ej.send(:index=, i)
    end

    def upheap(pd, ary, j)
      while true
        return if j <= 0
        i = (j-1) >> 1
        return if upper?(pd, ary, i, j)
        swap(ary, j, i)
        j = i
      end
    end

    def downheap(pd, ary, i)
      while true
        j = i*2+1
        k = i*2+2
        return if size(ary) <= j
        if size(ary) == k
          return if upper?(pd, ary, i, j)
          swap(ary, i, j)
          i = j
        else
          return if upper?(pd, ary, i, j) && upper?(pd, ary, i, k)
          loc = upper?(pd, ary, j, k) ? j : k
          swap(ary, i, loc)
          i = loc
        end
      end
    end

    def find_top_locator(ary)
      loc, _ = get_entry(ary, 0)
      loc
    end

    def delete_locator(pd, ary, loc)
      i = loc.send(:index)
      _, priority, subpriority = get_entry(ary, i)
      last = size(ary) - 1
      loc.send(:internal_deleted, priority, subpriority)
      el, pl, sl = delete_entry(ary, last)
      if i != last
        set_entry(ary, i, el, pl, sl)
        el.send(:index=, i)
        downheap(pd, ary, i)
      end
      size(ary)
    end

    def heapify(pd, ary, heapsize=0)
      # compare number of data movements in worst case.
      # choose a way for less data movements.
      #
      #   current size = ary.size / ARY_SLICE_SIZE = n
      #   addition size = n - heapsize = m
      #   heap tree height = Math.log2(n+1) = h
      #
      # worst data movements using downheap:
      # - bottom elements cannot move.
      # - elements above can move 1 time.
      # - ...
      # - top element can move h-1 times.
      #
      #   1*2**(h-2) + 2*2**(h-3) + 3*2**(h-4) + ... + (h-1)*2**0
      #   = sum i*2**(h-1-i), i=1 to h-1
      #   = 2**h - h - 1
      #   = n - h
      #
      # worst data movements using upheap
      # - bottom elements can move h-1 times.
      # - n/2 elements are placed at bottom.
      # - approximate all elements are at bottom...
      #
      #   (h-1) * m
      #
      # condition to use downheap:
      #
      #   n - h < (h-1) * m
      #   n - 1 < (h-1) * (m+1)
      #
      currentsize = size(ary)
      h = Math.log(currentsize+1)/Math.log(2)
      if currentsize - 1 < (h - 1) * (currentsize - heapsize + 1)
        n = (currentsize - 2) / 2
        n.downto(0) {|i|
          downheap(pd, ary, i)
        }
      else
        heapsize.upto(currentsize-1) {|i|
          upheap(pd, ary, i)
        }
      end
      currentsize
    end
  end

  module MinHeap
  end
  class << MinHeap
    include SimpleHeap

    def upper?(pd, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      pd.send(:compare_for_min, pi, si, pj, sj) <= 0
    end

    def update_priority(pd, ary, loc, priority, subpriority)
      i = loc.send(:index)
      ei, pi, si = get_entry(ary, i)
      cmp = pd.send(:compare_for_min, pi, si, priority, subpriority)
      set_entry(ary, i, ei, priority, subpriority)
      if cmp < 0
        # loc.priority < priority
        downheap(pd, ary, i)
      elsif cmp > 0
        # loc.priority > priority
        upheap(pd, ary, i)
      end
    end

    alias find_min_locator find_top_locator
  end

  module MaxHeap
  end
  class << MaxHeap
    include SimpleHeap

    def upper?(pd, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      pd.send(:compare_for_max, pi, si, pj, sj) >= 0
    end

    def update_priority(pd, ary, loc, priority, subpriority)
      i = loc.send(:index)
      ei, pi, si = get_entry(ary, i)
      subpriority ||= si
      cmp = pd.send(:compare_for_max, pi, si, priority, subpriority)
      set_entry(ary, i, ei, priority, subpriority)
      if cmp < 0
        # loc.priority < priority
        upheap(pd, ary, i)
      elsif cmp > 0
        # loc.priority > priority
        downheap(pd, ary, i)
      end
    end

    alias find_max_locator find_top_locator
  end

  # :startdoc:
end
