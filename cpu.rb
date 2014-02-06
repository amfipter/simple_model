require 'thread'
require './feed.rb'

class Cpu
  attr_accessor :work
  attr_reader :id, :done
  def initialize(id, actual_buff_size = 10)
    @buffer = Array.new
    @id = id
    @buff_size = actual_buff_size
    @free_r = false
    @free_l = false
    @asked_r = false
    @asked_l = false 
    @semaphore = Mutex.new
    @@semaphore_ = Mutex.new
    @work = true
    @done = 0
    @left_status_1 = nil
    @left_status = nil
    @right_status = nil
    @right_status_1 = nil
    driver
    executor
    communicator
  end
  
  def driver
    tr = Thread.new do
      @semaphore.lock
      puts "DRIVER #{@id} START."
      @semaphore.unlock
      while(@work) do
        @@semaphore_.lock
        feed if @id == 0
        @@semaphore_.unlock
        #puts "driver: #{@id}: #{@buff_size}"
        flag = false
        data = nil
        @semaphore.lock
        if(@buffer.size > 10)
          if(@free_r or @free_l)
            flag = true
            data = @buffer.pop
          end
        end
        @buff_size = @buffer.size
       #puts "1"
        
        @semaphore.unlock
        #puts "2"
        if(flag)
          @semaphore.lock
          send_to = Balancer.balance(@buff_size, nil, [@free_l, @free_r])
          #send_to = Balancer.simple_ai_balancer(@left_status_1, @left_status, @buff_size, @right_status, @right_status_1)
          $Comm.send(@id, send_to, data)
          @semaphore.unlock
        end
        sleep 1/1000
      end
      @semaphore.lock
      puts "DRIVER #{@id} STOP."
      @semaphore.unlock
    end
    tr.run

    #tr.join
  end
  
  def executor
    f = true
    tr = Thread.new do
      @semaphore.lock
      puts "EXECUTOR #{@id} START."
      @semaphore.unlock
      while(@work) do
        flag = false
        data = nil
        #puts @semaphore.locked?
        @semaphore.lock
        unless(@buffer.empty?)
          flag = true
          data = @buffer.pop
        end
        @buff_size = @buffer.size
        @semaphore.unlock
        puts '=====> ' + @id.to_s + ' ' + @buff_size.to_s if f
        f = false if @buff_size == 0
        f = true if @buff_size > 0
        unless(flag)
          sleep 1/500
        else
          data.start
          @@semaphore_.lock
          $Feed.done_task.push data
          @buff_size -=1
          log("load (executor): #{@buff_size}")
          @@semaphore_.unlock
          @done += 1
        end
      end
      @semaphore.lock
      puts "EXECUTOR #{@id} STOP."
      @semaphore.unlock
    end
    tr.run
    #tr.join
  end
  
  def communicator
    tr = Thread.new do
      @semaphore.lock
      puts "COMMUNICATOR #{@id} START."
      @semaphore.unlock
      a = 0
      while(@work) do

        # unless (@free_r or @asked_r)
        #   ask_free("right") 
        #   @asked_r = true
        # end
        # unless (@free_l or @asked_l)
        #   ask_free("left") 
        #   @asked_l = true
        # end
        sync_status() if a % 10 == 0
        get_msg
        sleep 1/1000
        a += 1
      end
      @semaphore.lock
      puts "COMMUNICATOR #{@id} STOP."
      @semaphore.unlock
    end
    tr.run
    #tr.join
  end

  def buff_size
    @buff_size
  end
  
  def feed
    if(@buff_size < 15)
      @semaphore.lock
      a = $Feed.get_ready_task
      @semaphore.unlock
      puts a.class
      unless(a.nil?) 
        @semaphore.lock
        @buffer.push a 
        @buff_size += 1
        log("load (feed): #{@buff_size}")
        @semaphore.unlock
      end
      puts @buffer.size unless @buffer.size == 10
     
    end
  end
  
  def ask_free(to)
    @semaphore.lock
    $Comm.send(@id, to, $MSG[1])
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
    if(msg.class.eql? Task)
      puts "#{@id} msg get"
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
    unless (msg=~/state/)
      msg.delete! 'state'
      if (msg.eql? '')
        $Comm.send(@id, from, "state#{@buff_size}")
      elsif(from.eql? 'left_1')
        left_status_1 = msg.to_i
      elsif (from.eql? 'left')
        left_status = msg.to_i
      elsif (from.eql? 'right')
        right_status = msg.to_i
      elsif (from.eql? 'right_1')
        right_status_1 = msg.to_i
      end
      puts "id: #{@id}; state from #{from}; data: #{msg.to_i}"
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

