module UserAnalytics
  class ServerCountUpdater
    MAX_DATAPOINTS_STORED_PER_USER = 365
    MAX_DATAPOINTS_FOR_EXISTING_USER = 60 # used only for initialization process for existing users
    
    attr_reader :user
    
    class << self
      def bulk_zero_update(user_ids, date = Date.today)
        bulk_zero_insert(user_ids, date)
        bulk_old_data_remove(user_ids)
      end
      
      def bulk_zero_insert(user_ids, date = Date.today)
        sql = bulk_sql(bulk_values(user_ids, date))
        ActiveRecord::Base.connection.execute(sql)
      end

      def bulk_values(user_ids, date)
        values_string = "'#{date}', 0, '#{Time.now}', '#{Time.now}'"
        user_ids.map {|id| "(#{id}, #{values_string})"}
      end
    
      def bulk_sql(values)
        "INSERT INTO user_server_counts (user_id, date, servers_count, created_at, updated_at) \
         VALUES #{values.join(', ')}"
      end
      
      def bulk_old_data_remove(user_ids)
        date_back = Date.today - (MAX_DATAPOINTS_STORED_PER_USER - 1).days
        UserServerCount.where('date < ? AND user_id IN (?)', date_back, user_ids).delete_all
      end
    end
    
    def initialize(user)
      @user = user
    end
    
    def update_user
      update_range.each { |date| update_servers_count_at(date) }
      remove_old_data if data_number_exceeded?
    end
    
    def update_servers_count_at(date)
      server_count_store = record_for_update(date)
      server_count_store.servers_count = number_of_servers(date)
      server_count_store.save if server_count_store.changed?
    end
    
    def number_of_servers(date)
      UserServerCount.all_servers(user, date).count
    end
    
    def record_for_update(date)
      UserServerCount.find_or_initialize_by(user: user, date: date)
    end
    
    def update_range
      start_update_date..Date.today
    end
    
    def start_update_date
      case
      when no_previous_data? then start_date_for_existing_user
      when recent_user? then user_created_date
      else verify_recent_servers_date
      end
    end
    
    def no_previous_data?
      last_stored_date.nil?
    end
    
    # user was created in less time ago than we use for not counting servers
    # UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS
    def recent_user?
      (last_stored_date - date_offset) < user.created_at.to_date
    end
    
    def start_date_for_existing_user
      [user_created_date, max_initial_date].max
    end
    
    def max_initial_date
      Date.today - (MAX_DATAPOINTS_FOR_EXISTING_USER - 1).days
    end
    
    def user_created_date
      user.created_at.to_date
    end
    
    # dates back to check if recently create servers passed minimum time running threshold
    # UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS
    def verify_recent_servers_date
      last_stored_date - date_offset
    end
    
    def last_stored_date
      @last_stored_date ||= user.server_count_history.maximum(:date)
    end
    
    def date_offset
      (UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS + 1).days
    end
    
    def remove_old_data
      UserServerCount.where(user: user).order(:date)
          .limit(number_of_records - MAX_DATAPOINTS_STORED_PER_USER)
          .destroy_all
    end
    
    def data_number_exceeded?
      number_of_records > MAX_DATAPOINTS_STORED_PER_USER
    end
    
    def number_of_records
      UserServerCount.where(user: user).count
    end
  end
end