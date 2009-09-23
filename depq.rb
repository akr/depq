# depq.rb - Double-Ended Priority Queue.
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

# = Depq - Double-Ended Priority Queue
#
# ==  Features
#
# * queue - you can insert and delete values
# * priority - you can get a value with minimum priority
# * double-ended - you can get a value with maximum priority too
# * stable - you will get the value inserted first with minimum/maximum priority
# * update priority - usable for Dijkstra's shortest path algorithm and various graph algorithms
# * implicit binary heap - most operations are O(log n) at worst
#
# == Introduction
#
# === Simple Insertion/Deletion
#
# You can insert values into a Depq object.
# You can delete the values from the object from ascending/descending order.
# delete_min deletes the minimum value.
# It is used for ascending order.
#
#   q = Depq.new
#   q.insert "durian"
#   q.insert "banana"
#   p q.delete_min     #=> "banana"
#   q.insert "orange"
#   q.insert "apple"
#   q.insert "melon"
#   p q.delete_min     #=> "apple"
#   p q.delete_min     #=> "durian"
#   p q.delete_min     #=> "melon"
#   p q.delete_min     #=> "orange"
#   p q.delete_min     #=> nil
#
# delete_max is similar to delete_min except it deletes maximum element
# instead of minimum.
# It is used for descending order.
#
# === The Order
#
# The order is defined by the priorities corresponds to the values and
# comparison operator specified for the queue.
#
#   q = Depq.new(:casecmp)   # use casecmp instead of <=>.
#   q.insert 1, "Foo"          # specify the priority for 1 as "Foo"
#   q.insert 2, "bar"
#   q.insert 3, "Baz"
#   p q.delete_min     #=> 2   # "bar" is minimum
#   p q.delete_min     #=> 3
#   p q.delete_min     #=> 1   # "Foo" is maximum
#   p q.delete_min     #=> nil
#
# If there are multiple values with same priority, subpriority is used to compare them.
# subpriority is an integer which can be specified by 3rd argument of insert.
# If it is not specified, total number of inserted elements is used.
# So Depq is "stable" which means that the element inserted first is deleted first.
#
#   q = Depq.new
#   q.insert "a", 1    # "a", "c" and "e" has same priority: 1
#   q.insert "b", 0    # "b", "d" and "f" has same priority: 0
#   q.insert "c", 1
#   q.insert "d", 0
#   q.insert "e", 1
#   q.insert "f", 0
#   p q.delete_min     #=> "b"         first element with priority 0
#   p q.delete_min     #=> "d"
#   p q.delete_min     #=> "f"         last element with priority 0
#   p q.delete_min     #=> "a"         first element with priority 1
#   p q.delete_min     #=> "c"
#   p q.delete_min     #=> "e"         last element with priority 1
#
# Note that delete_max is also stable.
# This means delete_max deletes the element with maximum priority with "minimum" subpriority.
#
#   q = Depq.new
#   q.insert "a", 1    # "a", "c" and "e" has same priority: 1
#   q.insert "b", 0    # "b", "d" and "f" has same priority: 0
#   q.insert "c", 1
#   q.insert "d", 0
#   q.insert "e", 1
#   q.insert "f", 0
#   p q.delete_max     #=> "a"         first element with priority 1
#   p q.delete_max     #=> "c"
#   p q.delete_max     #=> "e"         last element with priority 1
#   p q.delete_max     #=> "b"         first element with priority 0
#   p q.delete_max     #=> "d"
#   p q.delete_max     #=> "f"         last element with priority 0
#
# === Update Element
#
# An inserted element can be modified and/or deleted.
# The element to be modified is specified by Depq::Locator object.
# It is returned by insert, find_min_locator, etc.
#
#   q = Depq.new
#   d = q.insert "durian", 1
#   m = q.insert "mangosteen", 2
#   c = q.insert "cherry", 3
#   p m                         #=> #<Depq::Locator: "mangosteen":2>
#   p m.value                   #=> "mangosteen"
#   p m.priority                #=> 2
#   p q.find_min               #=> "durian"
#   p q.find_min_locator       #=> #<Depq::Locator: "durian":1>
#   m.update("mangosteen", 0)
#   p q.find_min               #=> "mangosteen"
#   p q.find_min_locator       #=> #<Depq::Locator: "mangosteen":0>
#   q.delete_element d
#   p q.delete_min             #=> "mangosteen"
#   p q.delete_min             #=> "cherry"
#   p q.delete_min             #=> nil
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
# == Internal Heap Algorithm
#
# Depq uses min-heap, max-heap or interval-heap internally.
# When delete_min is used, min-heap is constructed.
# When delete_max is used, max-heap is constructed.
# When delete_min and delete_max is used, interval-heap is constructed.
#
class Depq
  include Enumerable

  Locator = Struct.new(:value, :depq_or_subpriority, :index_or_priority)
  class Locator

    # if depq_or_subpriority is Depq
    #   depq_or_subpriority is depq
    #   index_or_priority is index
    # else
    #   depq_or_subpriority is subpriority
    #   index_or_priority is priority
    # end
    #
    # only 3 fields for memory efficiency.

    private :value=
    private :depq_or_subpriority
    private :depq_or_subpriority=
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

    # Create a Depq::Locator object.
    #
    #   loc = Depq::Locator.new("a", 1, 2)
    #   p loc.value             #=> "a"
    #   p loc.priority          #=> 1
    #   p loc.subpriority       #=> 2
    #
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
      depq_or_subpriority().kind_of? Depq
    end

    # returns the queue.
    #
    # nil is returned if the locator is not in a queue.
    def depq
      in_queue? ? depq_or_subpriority() : nil
    end
    alias queue depq

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
        q = depq_or_subpriority()
        priority, subpriority = q.send(:internal_get_priority, self)
        priority
      else
        index_or_priority()
      end
    end

    # returns the subpriority.
    def subpriority
      if in_queue?
        q = depq_or_subpriority()
        priority, subpriority = q.send(:internal_get_priority, self)
        subpriority
      else
        depq_or_subpriority()
      end
    end

    # update the value, priority and subpriority.
    #
    # subpriority cannot be nil if the locator is in a queue.
    # So subpriority is not changed if subpriority is not specified or nil for a locator in a queue.
    # subpriority is set to nil if subpriority is not specified or nil for a locator not in a queue.
    #
    #   q = Depq.new
    #   loc1 = q.insert 1, 2, 3
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
        q = depq_or_subpriority()
        if subpriority == nil
          subpriority = self.subpriority
        else
          subpriority = Integer(subpriority)
        end
        q.send(:internal_set_priority, self, priority, subpriority)
      else
        self.index_or_priority = priority
        self.depq_or_subpriority = subpriority
      end
      self.value = value
      nil
    end

    # update the value.
    #
    # This method doesn't change the priority and subpriority.
    #
    #   q = Depq.new
    #   loc = q.insert 1, 2, 3
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
    #   q = Depq.new
    #   loc = q.insert 1, 2, 3
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 2, 3]
    #   loc.update_priority 10
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 10, 3]
    #   loc.update_priority 20, 30
    #   p [loc.value, loc.priority, loc.subpriority] #=> [1, 20, 30]
    #
    def update_priority(priority, subpriority=nil)
      update(self.value, priority, subpriority)
    end

    def internal_inserted(depq, index)
      raise ArgumentError, "already inserted" if in_queue?
      priority = index_or_priority()
      self.depq_or_subpriority = depq
      self.index_or_priority = index
      priority
    end
    private :internal_inserted

    def internal_deleted(priority, subpriority)
      raise ArgumentError, "not inserted" if !in_queue?
      self.index_or_priority = priority
      self.depq_or_subpriority = subpriority
    end
    private :internal_deleted

  end

  # Create a Depq object.
  #
  # The optional argument, cmp, specify the method to compare priorities.
  # It should be a symbol or a comparator like a Proc which takes two arguments and returns -1, 0, 1.
  # If it is omitted, :<=> is used.
  #
  #   q = Depq.new
  #   q.insert "Foo"
  #   q.insert "bar"
  #   p q.delete_min   #=> "Foo"
  #   p q.delete_min   #=> "bar"
  #
  #   q = Depq.new(:casecmp)
  #   q.insert "Foo"
  #   q.insert "bar"
  #   p q.delete_min   #=> "bar"
  #   p q.delete_min   #=> "Foo"
  #
  #   q = Depq.new(lambda {|a,b| a.casecmp(b) })
  #   q.insert "Foo"
  #   q.insert "bar"
  #   p q.delete_min   #=> "bar"
  #   p q.delete_min   #=> "Foo"
  #
  #   cmp = Object.new
  #   def cmp.call(a,b) a.casecmp(b) end
  #   q = Depq.new(cmp)                         
  #   q.insert "Foo"            
  #   q.insert "bar"            
  #   p q.delete_min   #=> "bar"
  #   p q.delete_min   #=> "Foo"
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

  def use_min
    if @mode == MinHeap || @mode == IntervalHeap
      if @heapsize < self.size
        @heapsize = @mode.heapify(self, @ary, @heapsize)
      end
    else
      @mode = MinHeap
      @heapsize = @mode.heapify(self, @ary)
    end
  end
  private :use_min

  def use_max
    if @mode == MaxHeap || @mode == IntervalHeap
      if @heapsize < self.size
        @heapsize = @mode.heapify(self, @ary, @heapsize)
      end
    else
      @mode = MaxHeap
      @heapsize = @mode.heapify(self, @ary)
    end
  end
  private :use_max

  def use_minmax
    if @mode == IntervalHeap
      if @heapsize < self.size
        @heapsize = @mode.heapify(self, @ary, @heapsize)
      end
    else
      @mode = IntervalHeap
      @heapsize = @mode.heapify(self, @ary)
    end
  end
  private :use_minmax

  def mode_heapify
    if @mode
      @heapsize = @mode.heapify(self, @ary)
    end
  end
  private :mode_heapify

  def check_locator(loc)
    if !self.equal?(loc.depq) ||
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
  #   q = Depq.new
  #   p q.compare_priority("a", "b") #=> -1
  #   p q.compare_priority("a", "a") #=> 0
  #   p q.compare_priority("b", "a") #=> 1
  #
  #   q = Depq.new(:casecmp)
  #   p q.compare_priority("a", "A") #=> 0
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
  #   q = Depq.new
  #   p q.empty?       #=> true
  #   q.insert 1
  #   p q.empty?       #=> false
  #   q.delete_max
  #   p q.empty?       #=> true
  #
  def empty?
    @ary.empty?
  end

  # returns the number of elements in the queue.
  #
  #   q = Depq.new
  #   p q.size         #=> 0
  #   q.insert 1
  #   p q.size         #=> 1
  #   q.insert 1
  #   p q.size         #=> 2
  #   q.delete_min
  #   p q.size         #=> 1
  #   q.delete_min
  #   p q.size         #=> 0
  #
  def size
    @ary.size / ARY_SLICE_SIZE
  end
  alias length size

  # returns the total number of elements inserted for the queue, ever.
  #
  # The result is monotonically increased.
  #
  #   q = Depq.new
  #   p [q.size, q.totalcount]        #=> [0, 0]
  #   q.insert 1
  #   p [q.size, q.totalcount]        #=> [1, 1]
  #   q.insert 2
  #   p [q.size, q.totalcount]        #=> [2, 2]
  #   q.delete_min
  #   p [q.size, q.totalcount]        #=> [1, 2]
  #   q.insert 4
  #   p [q.size, q.totalcount]        #=> [2, 3]
  #   q.insert 3
  #   p [q.size, q.totalcount]        #=> [3, 4]
  #   q.insert 0
  #   p [q.size, q.totalcount]        #=> [4, 5]
  #   q.delete_min
  #   p [q.size, q.totalcount]        #=> [3, 5]
  #   q.insert 2
  #   p [q.size, q.totalcount]        #=> [4, 6]
  #
  def totalcount
    @totalcount
  end

  # make the queue empty.
  #
  # Note that totalcount is not changed.
  #
  #   q = Depq.new
  #   q.insert 1
  #   q.insert 1
  #   p q.size         #=> 2
  #   p q.totalcount   #=> 2
  #   q.clear
  #   p q.size         #=> 0
  #   p q.totalcount   #=> 2
  #   p q.find_min     #=> nil
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
      @mode.update_prio(self, @ary, loc, priority, subpriority)
    end
  end
  private :internal_set_priority

  # insert the locator to the queue.
  #
  # If loc.subpriority is nil, totalcount is used for stability.
  #
  # The locator should not already be inserted in a queue.
  #
  #   q = Depq.new
  #   loc = Depq::Locator.new(1)
  #   q.insert_locator loc
  #   p q.delete_min           #=> 1
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
  #   q = Depq.new
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.delete_min   #=> 1
  #   p q.delete_min   #=> 2
  #   p q.delete_min   #=> 3
  #
  #   q = Depq.new
  #   q.insert 3, 10
  #   q.insert 1, 20
  #   q.insert 2, 30
  #   p q.delete_min   #=> 3
  #   p q.delete_min   #=> 1
  #   p q.delete_min   #=> 2
  #
  # This method returns a locator which locates the inserted element.
  # It can be used to update the value and priority, or delete the element.
  #
  #   q = Depq.new
  #   q.insert 3
  #   loc1 = q.insert 1
  #   loc2 = q.insert 2
  #   q.insert 4
  #   p q.delete_max           #=> 4
  #   q.delete_locator loc1
  #   loc2.update 8
  #   p q.delete_max           #=> 8
  #   p q.delete_max           #=> 3
  #   p q.delete_max           #=> nil
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
  # The argument, iter, should have +each+ method.
  #
  # This method returns nil.
  #
  #   q = Depq.new
  #   q.insert_all [3,1,2]
  #   p q.delete_min   #=> 1
  #   p q.delete_min   #=> 2
  #   p q.delete_min   #=> 3
  #   p q.delete_min   #=> nil
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
  #   q = Depq.new 
  #   p q.find_min_locator     #=> nil 
  #   q.insert 3 
  #   q.insert 1 
  #   q.insert 2 
  #   p q.find_min_locator     #=> #<Depq::Locator: 1> 
  #   p q.find_min_locator     #=> #<Depq::Locator: 1>
  #   p q.delete_min           #=> 1
  #   p q.find_min_locator     #=> #<Depq::Locator: 2>
  #
  def find_min_locator
    return nil if empty?
    use_min
    @mode.find_min_loc(self, @ary)
  end

  # return the minimum value with its priority.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   q = Depq.new
  #   p q.find_min_priority    #=> nil
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   p q.find_min_priority    #=> ["durian", 1]
  #   p q.find_min_priority    #=> ["durian", 1]
  #   p q.delete_min           #=> "durian"
  #   p q.find_min_priority    #=> ["melon", 2]
  #   q.clear
  #   p q.find_min_priority    #=> nil
  #
  def find_min_priority
    loc = find_min_locator and [loc.value, loc.priority]
  end

  # return the minimum value.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   q = Depq.new 
  #   p q.find_min     #=> nil 
  #   q.insert 3 
  #   q.insert 1 
  #   q.insert 2 
  #   p q.find_min     #=> 1 
  #   p q.find_min     #=> 1
  #   p q.delete_min   #=> 1
  #   p q.find_min     #=> 2
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
  #   q = Depq.new
  #   p q.find_max_locator     #=> nil
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.find_max_locator     #=> #<Depq::Locator: 3>
  #   p q.find_max_locator     #=> #<Depq::Locator: 3>
  #   p q.find_max_locator     #=> #<Depq::Locator: 3>
  #   p q.delete_max           #=> 3
  #   p q.find_max_locator     #=> #<Depq::Locator: 2>
  #
  def find_max_locator
    return nil if empty?
    use_max
    @mode.find_max_loc(self, @ary)
  end

  # return the maximum value with its priority.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   q = Depq.new
  #   p q.find_max_priority    #=> nil
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   p q.find_max_priority    #=> ["banana", 3]
  #   p q.find_max_priority    #=> ["banana", 3]
  #   p q.delete_max           #=> "banana"
  #   p q.find_max_priority    #=> ["melon", 2]
  #   q.clear
  #   p q.find_max_priority    #=> nil
  #
  def find_max_priority
    loc = find_max_locator and [loc.value, loc.priority]
  end

  # returns the maximum value.
  # This method returns nil if the queue is empty.
  #
  # This method doesn't delete the element from the queue.
  #
  #   q = Depq.new
  #   p q.find_max     #=> nil
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.find_max     #=> 3
  #   p q.find_max     #=> 3
  #   p q.delete_max   #=> 3
  #   p q.find_max     #=> 2
  #
  def find_max
    loc = find_max_locator and loc.value
  end
  alias max find_max
  alias last find_max

  # returns the locators for the minimum and maximum element as a two-element array.
  # If the queue is empty, [nil, nil] is returned.
  #
  #   q = Depq.new
  #   p q.find_minmax_locator #=> [nil, nil]
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.find_minmax_locator #=> [#<Depq::Locator: 1>, #<Depq::Locator: 3>]
  #
  def find_minmax_locator
    return [nil, nil] if empty?
    use_minmax
    return @mode.find_minmax_loc(self, @ary)
  end

  # returns the minimum and maximum value as a two-element array.
  # If the queue is empty, [nil, nil] is returned.
  #
  #   q = Depq.new
  #   p q.find_minmax  #=> [nil, nil]
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.find_minmax  #=> [1, 3]
  #
  def find_minmax
    loc1, loc2 = self.find_minmax_locator
    [loc1 && loc1.value, loc2 && loc2.value]
  end
  alias minmax find_minmax

  # delete the element specified by the locator.
  #
  #   q = Depq.new
  #   q.insert 3
  #   loc = q.insert 2
  #   q.insert 1
  #   q.delete_locator loc
  #   p q.delete_min           #=> 1
  #   p q.delete_min           #=> 3
  #   p q.delete_min           #=> nil
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
      @heapsize = @mode.delete_loc(self, @ary, loc)
      loc
    end
  end

  # delete the minimum element in the queue and returns the locator.
  #
  # This method returns the locator for the deleted element.
  # nil is returned if the queue is empty.
  #
  #   q = Depq.new
  #   q.insert 2
  #   q.insert 1
  #   q.insert 3
  #   p q.delete_min_locator   #=> #<Depq::Locator: 1 (no queue)>
  #   p q.delete_min_locator   #=> #<Depq::Locator: 2 (no queue)>
  #   p q.delete_min_locator   #=> #<Depq::Locator: 3 (no queue)>
  #   p q.delete_min_locator   #=> nil
  #
  def delete_min_locator
    return nil if empty?
    use_min
    loc = @mode.find_min_loc(self, @ary)
    @heapsize = @mode.delete_loc(self, @ary, loc)
    loc
  end

  # delete the minimum element in the queue and returns the value and its priority.
  #
  # This method returns an array which contains the value and its priority
  # of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   q = Depq.new
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   p q.delete_min_priority  #=> ["durian", 1]
  #   p q.delete_min_priority  #=> ["melon", 2]
  #   p q.delete_min_priority  #=> ["banana", 3]
  #   p q.delete_min_priority  #=> nil
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
  #   q = Depq.new
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.delete_min   #=> 1
  #   p q.delete_min   #=> 2
  #   p q.delete_min   #=> 3
  #   p q.delete_min   #=> nil
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
  #   q = Depq.new
  #   q.insert 2
  #   q.insert 1
  #   q.insert 3
  #   p q.delete_max_locator   #=> #<Depq::Locator: 3 (no queue)>
  #   p q.delete_max_locator   #=> #<Depq::Locator: 2 (no queue)>
  #   p q.delete_max_locator   #=> #<Depq::Locator: 1 (no queue)>
  #   p q.delete_max_locator   #=> nil
  #
  def delete_max_locator
    return nil if empty?
    use_max
    loc = @mode.find_max_loc(self, @ary)
    @heapsize = @mode.delete_loc(self, @ary, loc)
    loc
  end

  # delete the maximum element in the queue and returns the value and its priority.
  #
  # This method returns an array which contains the value and its priority
  # of the deleted element.
  # nil is returned if the queue is empty.
  #
  #   q = Depq.new
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   p q.delete_max_priority  #=> ["banana", 3]
  #   p q.delete_max_priority  #=> ["melon", 2]
  #   p q.delete_max_priority  #=> ["durian", 1]
  #   p q.delete_max_priority  #=> nil
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
  #   q = Depq.new
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.delete_max   #=> 3
  #   p q.delete_max   #=> 2
  #   p q.delete_max   #=> 1
  #   p q.delete_max   #=> nil
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
  #   q = Depq.new
  #   q.insert 1
  #   q.insert 4
  #   q.insert 3
  #   p q.delete_unspecified_locator #=> #<Depq::Locator: 3 (no queue)>
  #   p q.delete_unspecified_locator #=> #<Depq::Locator: 4 (no queue)>
  #   p q.delete_unspecified_locator #=> #<Depq::Locator: 1 (no queue)>
  #   p q.delete_unspecified_locator #=> nil
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
  #   q = Depq.new
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   p q.delete_unspecified_priority  #=> ["melon", 2]
  #   p q.delete_unspecified_priority  #=> ["banana", 3]
  #   p q.delete_unspecified_priority  #=> ["durian", 1]
  #   p q.delete_unspecified_priority  #=> nil
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
  #   q = Depq.new
  #   q.insert 1
  #   q.insert 4
  #   q.insert 3
  #   p q.delete_unspecified   #=> 3
  #   p q.delete_unspecified   #=> 4
  #   p q.delete_unspecified   #=> 1
  #   p q.delete_unspecified   #=> nil
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
  #   q = Depq.new
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.delete_min           #=> 1
  #   q.each_locator {|v|
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
  #   q = Depq.new
  #   q.insert "durian", 1
  #   q.insert "banana", 3
  #   q.insert "melon", 2
  #   q.each_with_priority {|val, priority|
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
  #   q = Depq.new
  #   q.insert 3
  #   q.insert 1
  #   q.insert 2
  #   p q.delete_min   #=> 1
  #   q.each {|v|
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
    q = Depq.new
    threshold = nil
    iter.each {|v|
      if q.size < n
        if q.size == 0
          threshold = v
        else
          threshold = v if (v <=> threshold) < 0
        end
        q.insert v
      else
        if (v <=> threshold) > 0
          q.insert v
          if limit < q.size
            tmp = []
            n.times { tmp << q.delete_max }
            q.clear
            q.insert_all tmp
            threshold = tmp.last
          end
        end
      end
    }
    n = q.size if q.size < n
    a = []
    n.times { a << q.delete_max }
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
    q = Depq.new
    threshold = nil
    iter.each {|v|
      if q.size < n
        if q.size == 0
          threshold = v
        else
          threshold = v if (v <=> threshold) > 0
        end
        q.insert v
      else
        if (v <=> threshold) < 0
          q.insert v
          if limit < q.size
            tmp = []
            n.times { tmp << q.delete_min }
            q.clear
            q.insert_all tmp
            threshold = tmp.last
          end
        end
      end
    }
    n = q.size if q.size < n
    a = []
    n.times {
      a << q.delete_min
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
    q = Depq.new
    iters.each {|enum|
      enum = enum.to_enum unless enum.kind_of? Enumerator
      begin
        val = enum.next
      rescue StopIteration
        next
      end
      q.insert enum, val
    }
    loop = lambda {|y, meth|
      until q.empty?
        loc = q.find_min_locator
        enum = loc.value
        val = loc.priority
        y.send meth, val
        begin
          val = enum.next
        rescue StopIteration
          q.delete_locator loc
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

  module HeapArray
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

    def swap(ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      set_entry(ary, i, ej, pj, sj)
      set_entry(ary, j, ei, pi, si)
      ei.send(:index=, j)
      ej.send(:index=, i)
    end
  end

  module SimpleHeap
    include HeapArray

    def upheap(q, ary, j)
      while true
        return if j <= 0
        i = (j-1) >> 1
        return if upper?(q, ary, i, j)
        swap(ary, j, i)
        j = i
      end
    end

    def downheap(q, ary, i)
      while true
        j = i*2+1
        k = i*2+2
        return if size(ary) <= j
        if size(ary) == k
          return if upper?(q, ary, i, j)
          swap(ary, i, j)
          i = j
        else
          return if upper?(q, ary, i, j) && upper?(q, ary, i, k)
          loc = upper?(q, ary, j, k) ? j : k
          swap(ary, i, loc)
          i = loc
        end
      end
    end

    def find_top_loc(q, ary)
      loc, _ = get_entry(ary, 0)
      loc
    end

    def delete_loc(q, ary, loc)
      i = loc.send(:index)
      _, priority, subpriority = get_entry(ary, i)
      last = size(ary) - 1
      loc.send(:internal_deleted, priority, subpriority)
      el, pl, sl = delete_entry(ary, last)
      if i != last
        set_entry(ary, i, el, pl, sl)
        el.send(:index=, i)
        downheap(q, ary, i)
      end
      size(ary)
    end

    def heapify(q, ary, heapsize=0)
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
          downheap(q, ary, i)
        }
      else
        heapsize.upto(currentsize-1) {|i|
          upheap(q, ary, i)
        }
      end
      currentsize
    end
  end

  module MinHeap
  end
  class << MinHeap
    include SimpleHeap

    def upper?(q, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      q.send(:compare_for_min, pi, si, pj, sj) <= 0
    end

    def update_prio(q, ary, loc, priority, subpriority)
      i = loc.send(:index)
      ei, pi, si = get_entry(ary, i)
      cmp = q.send(:compare_for_min, pi, si, priority, subpriority)
      set_entry(ary, i, ei, priority, subpriority)
      if cmp < 0
        # loc.priority < priority
        downheap(q, ary, i)
      elsif cmp > 0
        # loc.priority > priority
        upheap(q, ary, i)
      end
    end

    alias find_min_loc find_top_loc
  end

  module MaxHeap
  end
  class << MaxHeap
    include SimpleHeap

    def upper?(q, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      q.send(:compare_for_max, pi, si, pj, sj) >= 0
    end

    def update_prio(q, ary, loc, priority, subpriority)
      i = loc.send(:index)
      ei, pi, si = get_entry(ary, i)
      subpriority ||= si
      cmp = q.send(:compare_for_max, pi, si, priority, subpriority)
      set_entry(ary, i, ei, priority, subpriority)
      if cmp < 0
        # loc.priority < priority
        upheap(q, ary, i)
      elsif cmp > 0
        # loc.priority > priority
        downheap(q, ary, i)
      end
    end

    alias find_max_loc find_top_loc
  end

  module IntervalHeap
  end
  class << IntervalHeap
    include HeapArray

    def root?(i) i < 2 end
    def minside?(i) i.even? end
    def maxside?(i) i.odd? end
    def minside(i) i & ~1 end
    def maxside(i) i | 1 end
    def parent_minside(j) (j-2)/2 & ~1 end
    def parent_maxside(j) (j-2)/2 | 1 end
    def child1_minside(i) i &= ~1; (i*2+2) & ~1 end
    def child1_maxside(i) i &= ~1; (i*2+2) | 1 end
    def child2_minside(i) i &= ~1; (i*2+4) & ~1 end
    def child2_maxside(i) i &= ~1; (i*2+4) | 1 end

    def pcmp(q, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      q.compare_priority(pi, pj)
    end

    def scmp(q, ary, i, j)
      ei, pi, si = get_entry(ary, i)
      ej, pj, sj = get_entry(ary, j)
      si <=> sj
    end

    def psame(q, ary, i)
      pcmp(q, ary, minside(i), maxside(i)) == 0
    end

    def travel(q, ary, i, range, fix_subpriority)
      while true
        j = yield i
        return i if !j
        swap ary, i, j
        if fix_subpriority
          imin = minside(i)
          imax = maxside(i)
          if range.include?(imin) && range.include?(imax)
            if pcmp(q, ary, imin, imax) == 0 && scmp(q, ary, imin, imax) > 0
              swap ary, imin, imax
            end
          end
        end
        i = j
      end
    end

    def upheap_minside(q, ary, i, range)
      travel(q, ary, i, range, true) {|j|
        if root?(j)
          nil
        elsif !range.include?(k = parent_minside(j))
          nil
        else
          if pcmp(q, ary, k, j) > 0
            swap(ary, minside(k), maxside(k)) if psame(q, ary, k)
            k
          else
            nil
          end
        end
      }
    end

    def upheap_maxside(q, ary, i, range)
      travel(q, ary, i, range, true) {|j|
        if root?(j)
          nil
        elsif !range.include?(k = parent_maxside(j))
          nil
        else
          if pcmp(q, ary, k, j) < 0
            k
          else
            nil
          end
        end
      }
    end

    def downheap_minside(q, ary, i, range)
      travel(q, ary, i, range, true) {|j|
        k1 = child1_minside(j)
        k2 = child2_minside(j)
        if !range.include?(k1)
          nil
        else
          if !range.include?(k2)
            k = k1
          else
            if (pc = pcmp(q, ary, k1, k2)) < 0
              k = k1
            elsif pc > 0
              k = k2
            elsif (sc = scmp(q, ary, k1, k2)) <= 0
              k = k1
            else
              k = k2
            end
          end
          if (pc = pcmp(q, ary, k, j)) < 0
            k
          else
            nil
          end
        end
      }
    end

    def downheap_maxside(q, ary, i, range)
      travel(q, ary, i, range, true) {|j|
        k1 = child1_maxside(j)
        k2 = child2_maxside(j)
        k1 = minside(k1) if range.include?(k1) && psame(q, ary, k1)
        k2 = minside(k2) if range.include?(k2) && psame(q, ary, k2)
        if !range.include?(k1)
          nil
        else
          if !range.include?(k2)
            k = k1
          else
            if (pc = pcmp(q, ary, k1, k2)) < 0
              k = k2
            elsif pc > 0
              k = k1
            elsif (sc = scmp(q, ary, k1, k2)) <= 0
              k = k1
            else
              k = k2
            end
          end
          if (pc = pcmp(q, ary, k, j)) > 0
            swap(ary, minside(k), maxside(k)) if minside?(k)
            maxside(k)
          else
            nil
          end
        end
      }
    end

    def upheap_sub(q, ary, i, range)
      travel(q, ary, i, range, false) {|j|
        k = nil
        if minside?(j)
          if range.include?(kk=parent_maxside(j)) && pcmp(q, ary, j, kk) == 0
            k = kk
          elsif range.include?(kk=parent_minside(j)) && pcmp(q, ary, j, kk) == 0
            k = kk
          end
        else
          if range.include?(kk=minside(j)) && pcmp(q, ary, j, kk) == 0
            k = kk
          elsif range.include?(kk=parent_maxside(j)) && pcmp(q, ary, j, kk) == 0
            k = kk
          end
        end
        if !k
          nil
        elsif scmp(q, ary, k, j) > 0
          k
        else
          nil
        end
      }
    end

    def downheap_sub(q, ary, i, range)
      travel(q, ary, i, range, false) {|j|
        k1 = k2 = nil
        if minside?(j)
          if range.include?(kk=maxside(j)) && pcmp(q, ary, j, kk) == 0
            k1 = kk
          else
            k1 = kk if range.include?(kk=child1_minside(j)) && pcmp(q, ary, j, kk) == 0
            k2 = kk if range.include?(kk=child2_minside(j)) && pcmp(q, ary, j, kk) == 0
          end
        else
          if range.include?(kk=child1_minside(j)) && pcmp(q, ary, j, kk) == 0
            k1 = kk
          elsif range.include?(kk=child1_maxside(j)) && pcmp(q, ary, j, kk) == 0
            k1 = kk
          end
          if range.include?(kk=child2_minside(j)) && pcmp(q, ary, j, kk) == 0
            k2 = kk
          elsif range.include?(kk=child2_maxside(j)) && pcmp(q, ary, j, kk) == 0
            k2 = kk
          end
        end
        if k1 && k2
          k = scmp(q, ary, k1, k2) > 0 ? k2 : k1
        else
          k = k1 || k2
        end
        if k && scmp(q, ary, k, j) < 0
          k
        else
          nil
        end
      }
    end

    def adjust(q, ary, i, range)
      if minside?(i)
        j = upheap_minside(q, ary, i, range)
        if i == j
          i = downheap_minside(q, ary, i, range)
          if !range.include?(child1_minside(i)) && range.include?(j=maxside(i)) && pcmp(q, ary, i, j) > 0
            swap(ary, i, j)
            i = j
          end
          if maxside?(i) || !range.include?(maxside(i))
            i = upheap_maxside(q, ary, i, range)
          end
        end
      else
        j = upheap_maxside(q, ary, i, range)
        if i == j
          i = downheap_maxside(q, ary, i, range)
          if !range.include?(child1_maxside(i))
            if range.include?(j=child1_minside(i)) && pcmp(q, ary, j, i) > 0
              swap(ary, i, j)
              i = j
            elsif range.include?(j=minside(i)) && pcmp(q, ary, j, i) > 0
              swap(ary, i, j)
              i = j
            end
          end
          if minside?(i)
            i = upheap_minside(q, ary, i, range)
          end
        end
      end
      i = upheap_sub(q, ary, i, range)
      downheap_sub(q, ary, i, range)
    end

    def update_prio(q, ary, loc, prio, subprio)
      i = loc.send(:index)
      ei, pi, si = get_entry(ary, i)
      subpriority ||= si
      set_entry(ary, i, ei, prio, subprio)
      range = 0...size(ary)
      adjust(q, ary, i, range)
    end

    def heapify(q, ary, heapsize=0)
      currentsize = size(ary)
      h = Math.log(currentsize+1)/Math.log(2)
      if currentsize - 1 < (h - 1) * (currentsize - heapsize + 1)
        (currentsize-1).downto(0) {|i|
          adjust(q, ary, i, i...currentsize)
        }
      else
        heapsize.upto(currentsize-1) {|i|
          adjust(q, ary, i, 0...(i+1))
        }
      end
      currentsize
    end

    def find_minmax_loc(q, ary)
      case size(ary)
      when 0
        [nil, nil]
      when 1
        e0, p0, s0 = get_entry(ary, 0)
        [e0, e0]
      else
        if pcmp(q, ary, 0, 1) == 0
          e0, p0, s0 = get_entry(ary, 0)
          [e0, e0]
        else
          e0, p0, s0 = get_entry(ary, 0)
          e1, p1, s1 = get_entry(ary, 1)
          [e0, e1]
        end
      end
    end

    def find_min_loc(q, ary)
      find_minmax_loc(q, ary).first
    end

    def find_max_loc(q, ary)
      find_minmax_loc(q, ary).last
    end

    def delete_loc(q, ary, loc)
      i = loc.send(:index)
      _, priority, subpriority = get_entry(ary, i)
      last = size(ary) - 1
      loc.send(:internal_deleted, priority, subpriority)
      el, pl, sl = delete_entry(ary, last)
      if i != last
        set_entry(ary, i, el, pl, sl)
        el.send(:index=, i)
        adjust(q, ary, i, 0...last)
      end
      size(ary)
    end
  end

  # :startdoc:
end
