#!/usr/bin/env ruby

require './comm.rb'
require './cpu.rb'
require './feed.rb'
require './log.rb'
require './util.rb'
require './task_generator.rb'
require './balancer.rb'


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


$count = ARGV[0].to_i
$seed = 100500
$task_size = ARGV[1].to_i
$max_diff = 1000
$die = false

$Log = Log.new
$Comm = Comm.new($count)

$Feed = Feed.new($seed, 1, $task_size, $max_diff)
$Feed.debug_print
#comm_test()
cpu = Array.new
t1 = Time.new.to_f
$count.times {|i| cpu.push Cpu.new(i)}


t = Thread.new do
  a = 20
  while(a) do
    x = 0
    cpu.each {|c| x += c.buff_size}
    if (x == 0)
      cpu.each {|c| c.work = false}
      puts $Feed.done_task.size
      break
    end
    puts "X=" + x.to_s
    $Log.add "X=" + x.to_s
    #a -= 1 if $die
    #$Log.add "count"

    sleep 1
  end
end
t.run


t.join
puts "TIME"
puts (Time.new.to_f-t1)
#$Log.print
exit


  



