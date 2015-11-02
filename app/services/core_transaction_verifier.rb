class CoreTransactionVerifier
  MAXIMUM_WAITING_TIME = 300 #seconds
  
  def initialize(user_id, server_id)
    @user = User.find(user_id)
    @server = Server.find(server_id)
    @squall_vm = Squall::VirtualMachine.new(*squall_params)
  end

  def perform_transaction
    return unless block_given?
    initial_completed_transaction_id
    yield
    @start_time = Time.now
    sleep(30) until transaction_ended? or time_passed?
  end
  
  private 
    def time_passed?
      (@start_time + MAXIMUM_WAITING_TIME.seconds) < Time.now
    end
  
    def transaction_ended?
      no_pending_transactions? and new_transaction_completed?
    end
  
    def new_transaction_completed?
      completed_transactions.last['id'] != initial_completed_transaction_id
    end
  
    def no_pending_transactions?
      pending_transactions.empty?
    end
  
    def pending_transactions
      all_transactions.select { |t| t["status"] == "pending"}
    end
  
    def completed_transactions
      all_transactions.select {|t| t['status'] == "complete"}.sort {|x,y| x['id'] <=> y['id']}
    end
  
    def all_transactions
      ts = @squall_vm.transactions(@server.identifier, 150).collect { |t| t['transaction'] }
      ts.reject { |t| t['action'].include?('market') }
    end
  
    def initial_completed_transaction_id
      @initial_completed_id ||= completed_transactions.last['id']
    end
  
    def onapp_server_id
      @onapp_server_id ||= @squall_vm.show(@server.identifier)["id"]
    end
  
    def squall_params
      [uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password]
    end
end