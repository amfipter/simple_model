module Task_generator
  def self.simple(num, min_diff = 100, max_diff = 1000, seed = 100500)
    tasks = Array.new
    random = Random.new(seed)
    num.times do |i|
      task = Task.new(random.rand(min_diff..max_diff), i, nil)
      task.ready = true
      log("task created: " + task.to_s)
      tasks.push task
    end
    tasks
  end

  def self.log(str)
    $Log.add "Task_generator: " + str
  end
end