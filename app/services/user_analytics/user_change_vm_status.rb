module UserAnalytics
  class UserChangeVmStatus
    ANALYSIS_PERIOD = 30
    POSSIBLE_TAGS = %i(growing shrinking stable)
    
    attr_reader :user

    def initialize(user)
      @user = user
    end
    
    def tag_user_vm_trend
      user.remove_tags_by_label(POSSIBLE_TAGS)
      user.add_tags_by_label(user_status)
    end
    
    # shrinking, stable, growing
    def user_status
      return if half_number < 5 # need at least 10 data points
      case 
      when recent_change? then last_number_bigger? ? :growing : :shrinking
      when average_difference < -0.4 then :shrinking
      when average_difference > 0.4 then :growing
      else 
        servers_count[0] == 0 ? nil : :stable
      end
    end
  
    def recent_change?
      recent_weighted_average != recent_average
    end
    
    def last_number_bigger?
      servers_count[0] > recent_average
    end

    def average_difference
      @average_difference ||= (recent_average - past_average).round(3)
    end
    
    def recent_weighted_average
      weighted_average(servers_count[0...half_number])
    end
    
    def recent_average
      @recent_average ||= average(servers_count[0...half_number])
    end
    
    def past_average
      average(servers_count[half_number..-1])
    end
    
    def average(arr)
      arr.inject(0.0) { |sum, el| sum + el } / arr.size
    end
    
    def weighted_average(arr)
      size = arr.size
      data = arr.each_with_index
      sum = data.inject([0.0, 0]) do |sum, el|
        w = el[1] < 3 ? 3 - el[1] : 1
        [sum[0] + el[0] * w, sum[1] + w]
      end
      sum[0] / sum[1]
    end
    
    def half_number
      servers_count.count / 2
    end
    
    def servers_count
      @servers_count ||= 
        user.server_count_history.order(date: :desc).limit(ANALYSIS_PERIOD).map(&:servers_count)
    end
  end
end
