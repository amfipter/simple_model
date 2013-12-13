require 'thread'
require './feed.rb'

class Cpu
  attr_accessor :work
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
    driver
    executor
    communicator
  end
  
  def driver
    tr = Thread.new do
      while(@work) do
        @@semaphore_.lock
        feed
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
          if(@free_r)
            @free_r = false
            $Comm.send(@id, "right", data)
            log("load: (driver)#{@buff_size}")
          elsif(@free_l)
            @free_l = false
            $Comm.send(@id, "left", data)
            log("load: (driver)#{@buff_size}")
          end
        end
        sleep 1/1000
      end
    end
    tr.run
    #tr.join
  end
  
  def executor
    f = true
    tr = Thread.new do
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
        end
      end
    end
    tr.run
    #tr.join
  end
  
  def communicator
    tr = Thread.new do
      while(@work) do

        unless (@free_r or @asked_r)
          ask_free("right") 
          @asked_r = true
        end
        unless (@free_l or @asked_l)
          ask_free("left") 
          @asked_l = true
        end
        get_msg
        sleep 1/1000
      end
    end
    tr.run
    #tr.join
  end

  def buff_size
    @buff_size
  end
  
  def feed
    if(@buff_size < 15)
      a = $Feed.get_ready_task
      #puts a.class
      unless(a.nil?) 
        @semaphore.lock
        @buffer.push a 
        @buff_size += 1
        log("load (feed): #{@buff_size}")
        @semaphore.unlock
      end
      #puts @buffer.size unless @buffer.size == 10
     
    end
  end
  
  def ask_free(to)
    $Comm.send(@id, to, $MSG[1])
  end
  
  def get_msg
    from, msg = $Comm.recv(@id)
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
    if(msg.eql? $MSG[1])
      s = @buff_size
      if(s < 15)
        $Comm.send(@id, from, $MSG[2])
      end
      return nil
    end
    # if(msg.eql? $MSG[3])
    #   if(from.eql? "right")
    #     $Comm.send(@id, "left", $MSG[3]) unless @id == 0
    #     return nil
    #   elsif(from.eql? "left")
    #     unless(@id == 0)
    #       $Comm.send(@id, "right", $MSG[3]) if @buffer.size == 0
    #       $Comm.send(@id, "left", $MSG[3]) unless @buffer.size == 0
    #     else
    #       return nil unless @buffer.size == 0
    #       @work = false
    #       $die = true
    #       $Comm.send(@id, "right", $MSG[4])
    #     end
    #   end
    #   return nil
    # end  
    
    # if(msg.eql? $MSG[4])
    #   @work = false
    #   $Comm.send(@id, "right", $MSG[4])
    # end   
    nil 
  end
  
  def log(str)
    $Log.add "Cpu " + @id.to_s + ' ' + str
  end
end
