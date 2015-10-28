# From https://github.com/victorgama/ssh-fingerprint

require 'digest/md5'
require 'base64'

class SSHFingerprint
  class << self
    PUBRE = /^(ssh-[dr]s[as]\s+)|(\s+.+\@.+)|\n/
    COLONS = /(.{2})(?=.)/
    
    def compute(key)
      key = key.clone
      key.gsub!(PUBRE, '')
      key = Base64.decode64(key)
      key = Digest::MD5.hexdigest(key)
      key.gsub!(COLONS, '\1:')
    end
  end
end