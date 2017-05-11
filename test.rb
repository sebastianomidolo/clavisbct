def send_simple_message
  RestClient.post "https://api:key-7b6778b948bb03a99743d15e20956b34"
  "@api.mailgun.net/v3/sandboxd0060054df1a41f9b265aa882ac74ff6.mailgun.org/messages",
  :from => "Mailgun Sandbox <postmaster@sandboxd0060054df1a41f9b265aa882ac74ff6.mailgun.org>",
  :to => "Sebastiano Midolo <sebastianomidolobct@gmail.com>",
  :subject => "Hello Sebastiano Midolo",
  :text => "Congratulations Sebastiano Midolo, you just sent an email with Mailgun!  You are truly awesome!"
end
