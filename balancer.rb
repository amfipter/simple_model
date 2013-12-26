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
end

#API
#сравнение
