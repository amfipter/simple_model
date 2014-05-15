require 'thread'
require './feed.rb'

class Cpu
  attr_accessor :work
  attr_reader :id, :done
  def initialize(id, actual_buff_size = 10, debug_mode = nil)
    @buffer = Array.new
    @id = id
    @buff_size = 0
    @debug_mode = debug_mode
    @free_r = false
    @free_l = false
    @asked_r = false
    @asked_l = false 
    @semaphore = Mutex.new
    @@semaphore_ = Mutex.new
    @work = true
    @done = 0
    @left_status_1 = -1
    @left_status = -1
    @right_status = -1
    @right_status_1 = -1
    unless (debug_mode.nil?)
      return
    end
    driver
    executor
    communicator
  end
  
  def driver
    tr = Thread.new do
      send_to = nil
      @semaphore.lock
      puts "DRIVER #{@id} START."
      @semaphore.unlock
      while(@work) do
        #@semaphore.lock
        feed() if @id == 0
        #@semaphore.unlock

        
        send_to = Balancer.balance(@buff_size, nil, [@free_l, @free_r])
        #puts send_to.to_s + ">>>>>>>>>>>>>>" + @id.to_s
        #send_to = Balancer.simple_ai_balancer(@left_status_1, @left_status, @buff_size, @right_status, @right_status_1)#, @free_l, @free_r)
        #puts ">>>>>" + send_to.to_s
        @semaphore.lock
        unless (send_to.nil?)
          #puts "id #{@id}; send to #{send_to}"
          part = 3
          if(@buffer.size > part)
            part.times do 
              data = @buffer.pop
              $Comm.send(@id, send_to, data)
            end
          end
          @buff_size = @buffer.size
          set_busy(send_to)
        end
        @semaphore.unlock
        sleep 1/1000
      end
      @semaphore.lock
      puts "DRIVER #{@id} STOP."
      @semaphore.unlock
    end
    tr.run

    #tr.join
  end

  def set_busy(to)
    @free_l = false if to.eql? 'left'
    @free_r = false if to.eql? 'right'
  end
  
  def executor
    f = true
    tr = Thread.new do
      # @semaphore.lock
      # puts "EXECUTOR #{@id} START."
      # @semaphore.unlock
      while(@work) do
        flag = false
        data = nil
        #puts @semaphore.locked?
        @semaphore.lock
        unless(@buffer.empty?)
          flag = true
          data = @buffer.pop
        end
        #@buff_size = @buffer.size
        @semaphore.unlock
        #puts '=====> ' + @id.to_s + ' ' + @buff_size.to_s if f
        # f = false if @buff_size == 0
        # f = true if @buff_size > 0
        unless(flag)
          sleep 1/500
        else
          data.start
          @@semaphore_.lock
          $Feed.done_task.push data unless @debug_mode
          #@buff_size -=1
          @buff_size = @buffer.size
          log("load (executor): #{@buff_size}")
          @@semaphore_.unlock
          @done += 1
        end
      end
      # @semaphore.lock
      # puts "EXECUTOR #{@id} STOP."
      # @semaphore.unlock
    end
    tr.run
    #tr.join
  end
  
  def communicator
    tr = Thread.new do
      # @semaphore.lock
      # puts "COMMUNICATOR #{@id} START."
      # @semaphore.unlock
      a = 0
      while(@work) do
        #puts @id
        sync_status() if a % 10 == 0
        ask_free() if a % 10 == 0
        #puts @left_status_1.to_s + ' ' + @left_status.to_s + ' ' + @right_status.to_s + ' ' + @right_status_1.to_s if a % 100
        get_msg
        sleep 1/1000
        a += 1
      end
      # @semaphore.lock
      # puts "COMMUNICATOR #{@id} STOP."
      # @semaphore.unlock
    end
    tr.run
    #tr.join
  end

  def buff_size
    @buff_size
  end

  def add_task_safe(task)
    @semaphore.lock
    @buffer.push task
    @buff_size += 1
    @semaphore.unlock
    nil
  end
  
  def feed
    @semaphore.lock
   # while(@buff_size < 15) do
    if (@buff_size < 15)
      a = $Feed.get_ready_task
      #puts a.class
      unless(a.nil?) 
        @buffer.push a 
        @buff_size += 1
        puts "load (feed): #{@buff_size}"
        log("load (feed): #{@buff_size}")
      # else
      #   break
      end
      #puts @buffer.size unless @buffer.size == 10
     
    end
    @semaphore.unlock
  end
  
  def ask_free()
    @semaphore.lock
    unless (@asked_l)
      #puts "left"
      $Comm.send(@id, 'left', $MSG[1])
      @asked_l = true
    end

    unless (@asked_r)
      #puts "right"
      $Comm.send(@id, 'right', $MSG[1])
      @asked_r = true
    end
    
    @semaphore.unlock
  end

  def sync_status()
    @semaphore.lock
    $Comm.send(@id, 'left_1', 'status')
    $Comm.send(@id, 'left', 'status')
    $Comm.send(@id, 'right_1', 'status')
    $Comm.send(@id, 'right', 'status')
    @semaphore.unlock
  end
  
  def get_msg
    @semaphore.lock
    from, msg = $Comm.recv(@id)
    @semaphore.unlock

    return nil if from.nil?
    # puts msg
    # puts from
    if(msg.class.eql? Task)
      #puts "#{@id} msg get"
      @semaphore.lock
      @buffer.push msg
      @buff_size += 1
      log("load: #{@buff_size}")
      @semaphore.unlock  
      
      return nil
    end
    if(msg.eql? $MSG[2])
      #puts @free_l
      if(from.eql? 'right')
        @free_r = true 
        @asked_r = false
      end
      if(from.eql? 'left')
        @free_l = true 
        @asked_l = false
      end
      return nil
    end

    @semaphore.lock
    if (msg=~/status/)
      # puts msg
      msg.delete! 'status'
      if (msg.eql? '')
        # puts "gg"
        # puts from.to_s
        $Comm.send(@id, from, "status#{@buff_size}")
      elsif(from.eql? 'left_1')
        @left_status_1 = msg.to_i
      elsif (from.eql? 'left')
        @left_status = msg.to_i
      elsif (from.eql? 'right')
        @right_status = msg.to_i
      elsif (from.eql? 'right_1')
        @right_status_1 = msg.to_i
      end
      #puts "id: #{@id}; state from #{from}; data: #{msg.to_i}"
    end
    @semaphore.unlock
    
    if(msg.eql? $MSG[1])
      s = @buff_size
      if(s < 15)
        @semaphore.lock
        $Comm.send(@id, from, $MSG[2])
        @semaphore.unlock
      end
      return nil
    end
    nil 
  end
  
  def log(str)
    $Log.add "Cpu " + @id.to_s + ' ' + str
  end
end

