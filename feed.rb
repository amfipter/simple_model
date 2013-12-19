require './task_generator.rb'
class Feed
  attr_accessor :work, :done_task
  def initialize(seed, type, size, max_diff)
    @seed = seed
    @type = type
    @size = size
    @max_diff = max_diff
    @tasks = Array.new
    @ready_task = Array.new
    @done_task = Array.new
    @work = true
    atomic_gen if type == 1
    most_atomic_gen if type == 2
    most_tree_gen if type == 3
    tree_gen if type == 4
    hard_gen if type == 5
    monitor

  end
  
  def atomic_gen
    # prng = Random.new(@seed)
    # @size.times do |i|
    #   a = Task.new(prng.rand(@max_diff), i, nil)
    #   a.ready = true
    #   #puts a.to_s
    #   log("Task created " + a.to_s)
    #   @tasks.push a
    #   #log("Task created " + a.to_s)
    # end
    @tasks = Task_generator.simple(@size)
  end
  
  def most_atomic_gen
    nil
  end

  
  def most_tree_gen
    nil
  end
  
  def tree_gen
    nil
  end
  
  def get_ready_task
    #puts @ready_task.to_s unless @ready_task.empty?
    #$Log.add "FEED: " + @ready_task.size.to_s 
    @ready_task.pop
  end
  
  # def done_task(task_id)
  #   @done_task.push task.id
  # end 
  
  def monitor
    Thread.new do
      while(@work) do
        t = Array.new
        #puts @tasks.to_s
        break if @tasks.empty?
        @tasks.each do |i|
          if(i.ready)
            @ready_task.push i
          else
            t.push i
          end
        end
        @tasks = t
        sleep 1/1000
      end 
    end
  end
  
  def debug_print
    @tasks.each {|i| puts i.to_s}
  end
  
  def log(str)
    $Log.add "class Feed: " + str
  end
end

class Task
  attr_reader :id, :done
  attr_accessor :ready 
  def initialize(diff, id, dep_id, mutation_prob = nil)
    @diff = diff.to_f / 1000
    @id = id
    @dep_id = dep_id
    @done = false
    @mutation = false
    @mutation_prob = mutation_prob 
    @ready = false
  end
  
  def start
    sleep @diff unless @done
    @done = true
  end
  
  def to_s
    s = "id = #{@id}; time = #{@diff} s; "
    s += "DONE " if @done
    s += "mutation probability = #{@mutation_prob} " unless @mutation_prob.nil?
    s
  end
end
