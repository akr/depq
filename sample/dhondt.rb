# D'Hondt method
#
# usage:
#   ruby -Ilib sample/dhondt.rb number-of-seats party1:votes1 party2:votes2 ...
#
# example:
#   % ruby -Ilib sample/dhondt.rb 10 A:230000 B:120000 C:90000 D:30000
#   A       230000  5
#   B       120000  3
#   C       90000   2
#   D       30000   0

require 'depq'

def dhondt(number_of_seats, number_of_votes_for_parties)
  q = Depq.new
  number_of_votes_for_parties.each {|party, votes|
    seats_gotten = 0
    q.insert [party, votes, seats_gotten], Rational(votes, seats_gotten+1)
  }
  number_of_seats.times {
    (party, votes, seats_gotten), priority = q.delete_max_priority
    if !q.empty? && q.find_min_priority[1] == priority
      # There may be two or more parties with maximum priority.
      # Random choice should be implemented here...
      raise
    end
    seats_gotten += 1
    q.insert [party, votes, seats_gotten], Rational(votes, seats_gotten+1)
  }
  h = {}
  until q.empty?
    party, votes, seats_gotten = q.delete_max
    h[party] = seats_gotten
  end
  h
end

number_of_seats = ARGV.shift.to_i
number_of_votes_for_parties = []
ARGV.each {|arg|
  /\A(.*):(\d+)\z/ =~ arg
  party = $1
  votes = $2.to_i
  number_of_votes_for_parties << [party, votes]
}

result = dhondt(number_of_seats, number_of_votes_for_parties)

number_of_votes_for_parties.each {|party, votes|
  seats_gotten = result[party]
  puts "#{party}\t#{votes}\t#{seats_gotten}"
}
