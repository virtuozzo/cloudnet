module KeysHelper
  
  def fingerprint(key)
    SSHFingerprint.compute(key)
  end
  
end
