class Comm
  def initialize(count)
    @count = count
    @data = Array.new(count)
    @data.size.times do |i|
      @data[i] = Array.new
    end
    @semaphore = Mutex.new
    @lat = 0.001
  end
  
  def send(id, to, msg)
    @semaphore.lock
    to_id = (id + 1) % @count if to.eql? "right"
    to_id = (id - 1) % @count if to.eql? "left" 
    to_id = (id + 2) % @count if to.eql? "right_1"
    to_id = (id - 2) % @count if to.eql? "left_1"
    @data[to_id].push Msg.new(id, to_id, msg)
    log("send from #{id} to #{to_id} msg '#{msg}'")
    @semaphore.unlock
  end
  
  def recv(id)
    @semaphore.lock
    a = @data[id].pop
    if(Time.new.to_f - a.time < @lat)
      @data[id].push a
      return nil, nil
    end
    log("receive id = #{id} from #{a.id_from} msg #{a.msg}") unless a.nil?
    unless a.nil?
      to = 'left'
      to = 'right' if a.id_from - id == 1
      to = 'right' if id - a.id_from == @count - 1
      to = 'left_1' if id - a.id_from == 2
      to = 'left_1' if a.id_from - id == @count - 2
      to = 'right_1' if a.id_from - id == 2
      to = 'right_1' if id - a.id_from == @count - 2
      return to, a.msg 
    end
    @semaphore.unlock
    return nil, nil
  end
  
  def log(str)
    $Log.add "class Comm: " + str
  end
end

class Msg
  attr_reader :msg, :id_from, :id_to, :time
  def initialize(from, to, msg)
    @id_from  = from
    @id_to = to
    @msg = msg
    @time = Time.new.to_f
  end
end
