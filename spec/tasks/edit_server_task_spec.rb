require 'rails_helper'

describe EditServerTask do
  let(:server) {FactoryGirl.create(:server, disk_size: 20, memory: 512, cpus: 2,
                            state: :on, os: 'linux')}
  let(:old_params) { {"cpus"=>2,
                      "memory"=>512,
                      "name"=>"xyz"}
                    }
  let(:entry_params) {[[false, false, false], [20, false, false],
                       [false, 33, false], [10, false, false],
                       [20, false, old_params], [10, 33, false],
                       [30, 33, false], [false, 33, {"memory"=>128}],
                       [false, 33, {"memory"=>1024}], [10, 33, {"memory"=>128}],
                       [30, 33, {"memory"=>1024}],
                       [10, 33, {"memory"=>1024}],
                       [30, 33, {"memory"=>128}], [false, 33, {"memory"=>512, "cpus"=>1}],
                       [30, 33, {"memory"=>512, "cpus"=>1}],
                       [10, 33, {"memory"=>512, "cpus"=>5}]
                      ]}
  let(:order) {[[], [],
                [:rebuild_template], [:resize_disk],
                [:change_params], [:resize_disk, :rebuild_template],
                [:rebuild_template, :resize_disk], [:change_params, :rebuild_template],
                [:rebuild_template, :change_params], [:change_params, :resize_disk, :rebuild_template],
                [:rebuild_template, :resize_disk, :change_params],
                [:resize_disk, :rebuild_template, :change_params],
                [:change_params, :rebuild_template, :resize_disk], [:rebuild_template, :change_params],
                [:rebuild_template, :resize_disk, :change_params],
                [:resize_disk, :rebuild_template, :change_params]
              ]}

  it "should set proper tasks order" do
    entry_params.each_with_index do |p, i|
      task = EditServerTask.new(server.user.id, server.id, *p)
      expect(task.tasks_order).to eq order[i]
    end
  end

  context "calling proper api methods" do
    before(:each) do
      @server_tasks = double('ServerTasks')
      @verifier = double('CoreTransactionVerifier')
      allow(ServerTasks).to receive_messages(new: @server_tasks)
      allow(CoreTransactionVerifier).to receive_messages(new: @verifier)
      CreateSiftEvent.jobs.clear
    end

    it "should send one call" do
      expect(server.state).to be :on
      expect(@server_tasks).to receive(:perform)
      expect(@verifier).to receive(:perform_transaction)
      task = EditServerTask.new(server.user.id, server.id, *entry_params[2])
      task.edit_server
      server.reload
      expect(server.state).to be :building
    end

    it "should send two calls" do
      expect(server.state).to be :on
      expect(@server_tasks).to receive(:perform)
      expect(@verifier).to receive(:perform_transaction).twice
      task = EditServerTask.new(server.user.id, server.id, *entry_params[5])
      task.edit_server
      server.reload
      expect(server.state).to be :building
    end

    it "should send three calls" do
      expect(server.state).to be :on
      expect(@server_tasks).to receive(:perform)
      expect(@verifier).to receive(:perform_transaction).exactly(3).times
      task = EditServerTask.new(server.user.id, server.id, *entry_params[9])
      task.edit_server
      server.reload
      expect(server.state).to be :building
    end

    it 'should create events at Sift' do
      expect(@server_tasks).to receive(:perform)
      expect(@verifier).to receive(:perform_transaction)
      task = EditServerTask.new(server.user.id, server.id, *entry_params[2])
      task.edit_server
      assert_equal 1, CreateSiftEvent.jobs.size
    end
  end
end
