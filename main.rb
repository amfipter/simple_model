#!/usr/bin/env ruby

require './comm.rb'
require './cpu.rb'
require './feed.rb'
require './log.rb'
require './util.rb'

#s

def comm_test()
  $Comm.send(0, 'left', 'test from 0')
  $Comm.send(0, 'right', 'test from 0')
  $Comm.send(1, 'left', 'test from 1')
  $Comm.send(1, 'right', 'test from 1')
  $Comm.send(2, 'left', 'test from 2')
  $Comm.send(2, 'right', 'test from 2')
  puts "===="
  puts $Comm.recv(0)
  puts $Comm.recv(0)
  puts $Comm.recv(1)
  puts $Comm.recv(1)
  puts $Comm.recv(2)
  puts $Comm.recv(2)
  puts "====="
  $Log.print
  exit
end


$count = 3
$seed = 100500
$task_size = 3
$max_diff = 1000
$die = false

$Log = Log.new
$Comm = Comm.new($count)

$Feed = Feed.new($seed, 1, $task_size, $max_diff)
$Feed.debug_print
#comm_test()
cpu = Array.new
$count.times {|i| cpu.push Cpu.new(i)}


t = Thread.new do
  a = 20
  while(a) do
    x = 0
    cpu.each {|c| x += c.buff_size}
    if (x == 0)
      cpu.each {|c| c.work = false}
      break
    end
    $Log.add "X=" + x.to_s
    #a -= 1 if $die
    #$Log.add "count"

    sleep 1/100
  end
end
t.run

$Log.print
t.join
exit


  



