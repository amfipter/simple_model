class Log 
  def initialize
    @data = Array.new
  end
  
  def add(str)
    @data.push str
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
