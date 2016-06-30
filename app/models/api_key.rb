class ApiKey < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :user
  
  before_save :ensure_api_key

  attr_encrypted :key
  
  validates :title, presence: true
  validates :encrypted_key, uniqueness: true
  validate :api_keys_limit
  
  def ensure_api_key
    if key.blank?
      self.key = generate_api_key
    end
  end

  private
  
  def generate_api_key
    loop do
      token = Devise.friendly_token
      encrypted = SymmetricEncryption.encrypt token
      break token unless ApiKey.with_deleted.where(encrypted_key: encrypted).first
    end
  end
  
  def api_keys_limit
    errors.add(:base, 'Only 3 API keys allowed per user') if user.api_keys.count > 2
  end
  
end
