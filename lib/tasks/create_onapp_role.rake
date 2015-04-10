# Creates the non-privelged OnApp user role that all cloud.net use to interact with OnApp
task create_onapp_role: :environment do
  squall = Squall::Role.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  response = squall.create(
    label: 'user',
    permission_ids: [
      7,32,34,36,38,40,46,53,87,89,91,93,96,105,106,107,117,130,134,135,137,139,140,142,144,146,
      148,149,153,155,160,190,192,194,196,201,221,222,237,244,247,249,250,260,265,267,269,276,
      288,291,293,295,297,305,307,309,314,318,329,337,338,348,349,354,355,358,360,362,364,376,
      437,442,461,463,465,489,495,497,498,499,500,501,502,504,508,510,512,513,514,517,520,522,
      524,525,528,530,532,533,537,539,541,547,550
    ]
  )
  puts "Role created. ID is #{response['role']['id']}, set this value to the ONAPP_ROLE key in .env"
end

# Show the details of the current OnApp user role
task show_onapp_role: :environment do
  squall = Squall::Role.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  role = squall.show 2
  puts role['permissions'].map{ |p| p['permission']['id'] }.join(',')
end
