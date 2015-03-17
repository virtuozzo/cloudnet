#redirect to sign_up instead of sign_in for unsuccesfull request
class CustomFailure < Devise::FailureApp
   def route(scope)
     return super unless [:user].include?(scope) #make it specific to a scope
     if URI(url_for(params)).path == servers_create_path
       :new_user_registration_url
     else
       super
     end
   end

   # You need to override respond to eliminate recall
   def respond
     if http_auth?
       http_auth
     else
       redirect
     end
   end
 end