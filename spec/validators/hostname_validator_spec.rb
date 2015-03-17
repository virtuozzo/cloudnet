require 'rails_helper'

describe HostnameValidator do
  describe 'Hostname format should be as per RFC 1123' do
    before do
      @server = Server.new
      @valid_hostnames   = %w(
        abc
        123abc
        123.abc.def
        123.abc-def
        aaaaa.bbbbb.ccccc.dddd.eeee
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com
      )
      @invalid_hostnames = %w{
        $abc
        abc(def)
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com
      }
    end

    it 'should be valid' do
      @valid_hostnames.each do |hostname|
        @server.hostname = hostname
        @server.save
        expect(@server.errors[:hostname]).to be_blank
      end
    end

    it 'should be not valid' do
      @invalid_hostnames << nil
      @invalid_hostnames.each do |hostname|
        @server.hostname = hostname
        @server.save
        expect(@server.errors[:hostname]).not_to be_blank
      end
    end
  end
end
