require "ai4r"

module Ai
  def self.create()
    net = Ai4r::NeuralNetwork::Backpropagation.new([3, 24, 22, 3]) #parameters chosen without any reason
    #net = Ai4r::NeuralNetwork::Backpropagation.new([3, 2, 2, 3]) #for test
    net
  end

  def self.train(net)
    30000.times do
      input, output = Simple_ai_tool.gen()
      net.train(input, output)
    end
  end
  
end

module Simple_ai_tool
  def self.gen()
    input_data = Array.new
    output_data = Array.new(3)
    output_data.map! {|i| i = 0}

    3.times do |i|
      input_data.push Random.rand($max_tasks)
    end

    if(input_data[1] > $disbalance_threshold)
      output_data[2] = 1
    elsif (input_data[0] > $disbalance_threshold or input_data[2] > $disbalance_threshold) 
      output_data[1] = 1
    else
      output_data[0] = 1
    end

    return input_data, output_data
  end
end