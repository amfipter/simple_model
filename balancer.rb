require './ai.rb'

class Balancer
  def initialize
    nil
  end

  def self.balance(current_load, net_type, status)
    Balancer.simple_balancer(current_load, status.shift, status.shift)
  end

  def self.simple_balancer(current_load, left_status, right_status)
    load_barrier = 10
    return nil if current_load <= load_barrier
    if(left_status == true)
      return 'left'
    end
    if(right_status == true)
      return 'right'
    end
    nil 
  end

  def self.simple_ai_balancer(left_load_1, left_load, current_load, right_load, right_load_1, free_l, free_r)
    if (left_load_1.nil? or left_load.nil? or current_load.nil? or right_load.nil? or right_load_1.nil?)
      return nil
    end
    #puts "DUCK SUCK!!"
    if($net.nil?)
      puts "INIT AI"
      $net = Ai.create()
      Ai.train($net)
    end
    #puts __LINE__
    main_res = $net.eval([left_load, current_load, right_load])
    main = Balancer_tools.vector_extract(main_res)
    left_res = $net.eval([left_load_1, left_load, current_load])
    left = Balancer_tools.vector_extract(left_res)
    right_res = $net.eval([current_load, right_load, right_load_1])
    right = Balancer_tools.vector_extract(right_res)
    # main_res = [rand, rand, rand]
    # main = Balancer_tools.vector_extract(main_res)
    # left_res = [rand, rand, rand]
    # left = Balancer_tools.vector_extract(left_res)
    # right_res = [rand, rand, rand]
    # right = Balancer_tools.vector_extract(right_res)
   # puts __LINE__
    if(main[2] == 1) 
      if(left[0] == 1 and free_l)
        return 'left'
      elsif (right[0] == 1 and free_r)
        return 'right'
      end
      if(left[1] == 1 and right[1] == 1)
        if (left_res[1] < right_res[1] and free_l)
          return 'left'
        elsif (free_r)
          return 'right'
        end
      end
      if(left[1] == 1 and right[2] == 1 and free_l)
        return 'left'
      elsif (right[1] == 1 and left[2] == 1 and free_r)
        return 'right'
      end

    end
    nil
  end
          
          


end



module Balancer_tools
  def self.vector_extract(v)
    m = v.max
    out = Array.new
    v.each do |i|
      out.push 1 if i == m
      out.push 0 if i != m
    end
    out
  end
end