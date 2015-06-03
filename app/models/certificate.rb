class Certificate < ActiveRecord::Base
    has_and_belongs_to_many :locations
    mount_uploader :certificate_avatar, CertificateAvatarUploader
end
