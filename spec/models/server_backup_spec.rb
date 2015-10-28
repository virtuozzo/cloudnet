require 'rails_helper'

describe ServerBackup do
  let (:backup) { FactoryGirl.create(:server_backup) }

  it 'should be valid' do
    expect(backup).to be_valid
  end

  it 'should not be valid without a backup id' do
    backup.backup_id = nil
    expect(backup).not_to be_valid
  end

  it 'should not be valid without an identifier' do
    backup.identifier = nil
    expect(backup).not_to be_valid
  end

  it 'should not be valid without a set backup created flag' do
    backup.backup_created = nil
    expect(backup).not_to be_valid
  end

  it 'should not be valid without a server' do
    backup.server = nil
    expect(backup).not_to be_valid
  end

  it 'should give a backup size in mb with decimals' do
    [0, 1023, 1024, 432_435].each do |number|
      backup.backup_size = number
      expect(backup.backup_size_mb).to eq(number / 1024)
    end
  end

  it 'should create a backup from a backup hash for the server specified' do
    server = backup.server

    test_data = {
      'built' => true,
      'built_at' => Time.now.to_s,
      'created_at' => Time.now.to_s,
      'identifier' => 123,
      'locked' => false,
      'disk_id' => 1,
      'min_disk_size' => 5,
      'min_memory_size' => 256,
      'backup_size' => 3_243_434,
      'backup_created' => Time.now.to_s,
      'backup_id' => 23
    }

    result = server.server_backups.create(test_data)
    expect(result).to be_valid
  end
end
