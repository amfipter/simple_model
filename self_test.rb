class Self_test
  def initialize()
    @size = 5
    @task_size = 50
    @Log = Log.new
    @Comm = Comm.new(@size, Log.new)
    @Feed = Feed.new(100500, 1, @task_size, 1000, Log.new)
    @test_count = 14
    @l = 0
    @c = 0
    @f = 0
  end

  def proof_test(cpu_count, task_count)
    cpu = Array.new
    t1 = Time.new.to_f
    cpu_count.times {|i| cpu.push Cpu.new(i, 10, true)}
    feed = Feed.new($seed, 1, task_count, $max_diff)
    #sleep 1/10
    task = feed.get_ready_task()
    cpu.each {|i| i.executor()}
    i = 1
    until (task.nil?) do
      #puts "lol"
      c = nil
      print "\r#{i}/#{task_count}"
      while (c.nil?) do
        cpu.each do |el|
          #puts el.buff_size
          if(el.buff_size == 0)
            c = el
            break
          end
        end
        #puts ''
        #sleep 1/1000000
      end
      c.add_task_safe(task)
      task = feed.get_ready_task()
      i += 1
    end
    puts ''

    #sleep 3

    c = true
    while(c) do
      c = false
      cpu.each do |el|
        c = true if el.buff_size > 0
        #puts el.buff_size
      end
      sleep 1/300
      #puts ''
    end

    t_all = 0
    cpu.each do |i|
      puts "ID: " + i.id.to_s + " DONE: " + i.done.to_s
      t_all += i.done
      #t_max = i.done if i.done > t_max
      #t_arr.push i.done
    end
    puts "ALL TASKS: " + t_all.to_s
    puts task_count
    cpu.each {|c| c.work = false}
    nil
  end

  def reinit()
    @size *= 2
    @task_size *= 2
    @Log = Log.new
    @Comm = Comm.new(@size, Log.new)
    @Feed = Feed.new(100500, 1, @task_size, 1000, Log.new)
  end

  def common_test(t=nil)
    unless(t.nil?)
      @test_count = t
    end
    puts "COMMON TEST"
    @test_count.times do 
      l = log_test()
      c = comm_test()
      f = feed_test()
      cool_print_common(l, c, f)
      reinit()
    end
    puts "\nEND"
  end

  def cool_print_common(l, c, f)
    @l += 1 if l
    @c += 1 if c
    @f += 1 if f
    print "\rLOG PASSED: #{@l}/#{@test_count}; COMM PASSED: #{@c}/#{@test_count}; FEED PASSED: #{@f}/#{@test_count}"
  end

  def log_test()
    #puts "LOG TEST..."
    pass = true
    1000.times do 
      @Log.add "test"
    end
    @Log.data.each do |e|
      unless (e.eql?"test")
        pass = false
      end
    end
    # print "LOG TEST "
    # puts "PASSED!" if pass
    # puts "FAILED!" unless pass
    pass
  end

  def comm_test()
    #puts "COMM TEST..."
    pass = true
    @size.times do |i|
      @Comm.send(i, 'left_1', i.to_s)
      @Comm.send(i, 'left', i.to_s)
      @Comm.send(i, 'right_1', i.to_s)
      @Comm.send(i, 'right', i.to_s)
    end

    res = nil
    ans = ['left', 'left_1', 'right', 'right_1'].sort

    @size.times do |i|
      res = Array.new
      k, p = @Comm.recv(i)
      until (p.nil?)
        res.push k
        k, p = @Comm.recv(i)
      end
      unless (res.sort.eql? ans)
        pass = false
        puts "COMM FAIL. id: #{i}; res: #{res.to_s}; ans: #{ans.to_s}"
      end
    end
    # print 'COMM TEST '
    # puts 'PASSED!' if pass
    # puts 'FAILED!' unless pass
    pass
  end

  def feed_test()
    #puts "FEED TEST..."
    pass = true
    res = Array.new
    p = @Feed.get_ready_task
    sleep 0.1
    until (p.nil?)
      res.push p
      p = @Feed.get_ready_task
    end
    # puts ''
    # puts res.size
    # puts @task_size
    # sleep 10
    pass = false if res.size != @task_size

    # print "FEED TEST "
    # puts "PASSED!" if pass
    # puts "FAILED!" unless pass
    pass
  end
end