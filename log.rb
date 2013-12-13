class Log 
  def initialize
    @data = Array.new
    @last_str = ''
    @semaphore = Mutex.new
  end
  
  def add(str)
    @semaphore.lock
    @data.push str unless str.eql?(@last_str)
    @last_str = str
    @semaphore.unlock
  end
  
  def print
    puts @data
  end

  def print_str(str)
  	@data.each do |d|
  	  puts d if d.match('==')
  	end
  end
end
