# scheduler
#
# needs Ruby 1.9.2 for timeout argument of ConditionVariable#wait.

require 'depq'
require 'thread'

class Sched
  def initialize
    @q = Depq.new
    @m = Mutex.new
    @cv = ConditionVariable.new
  end

  def sync
    @m.synchronize { yield }
  end

  def insert(time, &block)
    sync {
      @q.insert block, time
    }
  end

  def wait_next_event
    sync {
      block, time = @q.find_min_priority
      now = Time.now
      if now < time
        @cv.wait(@m, time - now)
      end
      now
    }
  end

  def start
    until sync { @q.empty? }
      now = wait_next_event
      loop {
        block = time = nil
        sync {
          raise StopIteration if @q.empty?
          block, time = @q.find_min_priority
          raise StopIteration if now < time
          block, time = @q.delete_min_priority
        }
        block.call
      }
    end
  end
end

if $0 == __FILE__
  now = Time.now
  sc = Sched.new
  Thread.new {
    sleep 1.5
    sc.insert(Time.now+1) { p Time.now-now }
  }
  sc.insert(now+4) { p Time.now-now }
  sc.insert(now+3) { p Time.now-now }
  sc.insert(now+2) { p Time.now-now }
  sc.insert(now+1) { p Time.now-now }
  sc.start
end
