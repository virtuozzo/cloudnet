class AllUsers
  def process
    squall = Squall::User.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    squall.list(true)
  end
end
