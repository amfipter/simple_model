#!/usr/bin/env ruby

require './comm.rb'
require './cpu.rb'
require './feed.rb'
require './log.rb'
require './util.rb'
require './task_generator.rb'
require './balancer.rb'
require './ai.rb'
require './self_test.rb'


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
$net = nil

self_test = Self_test.new
self_test.common_test(5)
#exit

$Log = Log.new
$Comm = Comm.new($count)

$Feed = Feed.new($seed, 1, $task_size, $max_diff)
$Feed.debug_print
sleep 0.5
#comm_test()
cpu = Array.new
t1 = Time.new.to_f
$count.times {|i| cpu.push Cpu.new(i)}


t = Thread.new do
  #sleep 1
  a = 20
  t_all = 0
  t_arr = Array.new
  t_max = 0
  while(a) do
    x = 0
    cpu.each {|c| x += c.buff_size}
    if (x == 0)
      cpu.each do |i|
        puts "ID: " + i.id.to_s + " DONE: " + i.done.to_s
        t_all += i.done
        t_max = i.done if i.done > t_max
        t_arr.push i.done
      end
      puts "ALL TASKS: " + t_all.to_s
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
  # t_arr = t_arr.to_s
  # t_arr.delete! '['
  # t_arr.delete! ']'
  # t_arr.gsub! ',', ''
  # puts t_arr

  # File.open("plot.mat", 'w') {|file| file.puts("x = [0:#{$count - 1}]; y = [#{t_arr}]; xf = [0:0.1:#{$count - 1}]; cub = interp1 (x, y, xf, \"spline\"); plot(xf, cub, 'linewidth', 1); input('');") and file.close}
  # #{}`octave plot.mat`
  #{}`rm plot.mat`
end
t.run


t.join
puts "TIME"
puts (Time.new.to_f-t1)
#$Log.print
exit


  



