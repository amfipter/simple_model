class Cpu
  attr_accessor :work
  def initialize(id, actual_buff_size = 10)
    @buffer = Array.new
    @id = id
    @buff_size = actual_buff_size
    @free_r = false
    @free_l = false
    @work = true
    driver
    executor
    communicator
  end
  
  def driver
    tr = Thread.new do
      while(@work) do
        feed if @id == 0
        if(@buffer.size > 10)
          if(@free_r)
            @free_r = false
            t = @buffer.pop
            $Comm.send(@id, "right", t)
            log("load: (driver)#{@buffer.size}")
          elsif(@free_l)
            @free_l = false
            t = @buffer.pop
            $Comm.send(@id, "left", t)
            log("load: (driver)#{@buffer.size}")
          end
        end
        sleep 1/1000
      end
    end
  end
  
  def executor
    tr = Thread.new do
      while(@work) do
        log('=====> ' + @id.to_s + ' ' + @buffer.size.to_s)
        if(@buffer.empty?)
          sleep 1/300
        else
          task = @buffer.pop
          tast.start
          log("load (executor): #{@buffer.size}")
        end
      end
    end
  end
  
  def communicator
    Thread.new do
      while(@work) do
        ask_free("right") unless @free_r
        ask_free("left") unless @free_l
        get_msg
        sleep 1/1000
      end
    end
  end
  
  def feed
    if(@buffer.size < 15)
      a = $Feed.get_ready_task
      #puts a.class unless a.nil?
      @buffer.push a unless a.nil?
      #puts @buffer.size unless @buffer.size == 10
      log("load (feed): #{@buffer.size}")
    end
  end
  
  def ask_free(to)
    $Comm.send(@id, to, $MSG[1])
  end
  
  def get_msg
    from, msg = $Comm.recv(@id)
    return nil if from.nil?
    if(msg.class.eql? Task)
      #puts "lol"
      @buffer.push Task
      log("load: #{@buffer.size}")
      return nil
    end
    if(msg.eql? $MSG[2])
      #puts @free_l
      @free_r = true if from.eql? 'right'
      @free_l = true if from.eql? 'left'
      return nil
    end
    if(msg.eql? $MSG[1])
      s = @buffer.size
      if(s < 15)
        $Comm.send(@id, from, $MSG[2])
      end
      return nil
    end
    if(msg.eql? $MSG[3])
      if(from.eql? "right")
        $Comm.send(@id, "left", $MSG[3]) unless @id == 0
        return nil
      elsif(from.eql? "left")
        unless(@id == 0)
          $Comm.send(@id, "right", $MSG[3]) if @buffer.size == 0
          $Comm.send(@id, "left", $MSG[3]) unless @buffer.size == 0
        else
          return nil unless @buffer.size == 0
          @work = false
          $die = true
          $Comm.send(@id, "right", $MSG[4])
        end
      end
      return nil
    end  
    
    if(msg.eql? $MSG[4])
      @work = false
      $Comm.send(@id, "right", $MSG[4])
    end   
    nil 
  end
  
  def log(str)
    $Log.add "Cpu " + @id.to_s + ' ' + str
  end
end
