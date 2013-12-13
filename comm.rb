class Comm
  def initialize(count)
    @count = count
    @data = Array.new(count)
    @data.size.times do |i|
      @data[i] = Array.new
    end
    @semaphore = Mutex.new
  end
  
  def send(id, to, msg)
    @semaphore.lock
    to_id = (id + 1) % @count if to.eql? "right"
    to_id = (id - 1) % @count if to.eql? "left" 
    @data[to_id].push Msg.new(id, to_id, msg)
    log("send from #{id} to #{to_id} msg '#{msg}'")
    @semaphore.unlock
  end
  
  def recv(id)
    @semaphore.lock
    a = @data[id].pop
    log("receive id = #{id} from #{a.id_from} msg #{a.msg}") unless a.nil?
    unless a.nil?
      to = 'left'
      to = 'right' if a.id_from - id == 1
      to = 'right' if id - a.id_from == @count - 1
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
  attr_reader :msg, :id_from, :id_to
  def initialize(from, to, msg)
    @id_from  = from
    @id_to = to
    @msg = msg
  end
end
