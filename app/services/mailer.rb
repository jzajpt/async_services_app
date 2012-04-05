class Mailer < Service
  subscribe_to "user:*"

  def perform(channel, data)
    puts "Mailer.perform #{channel} #{data}"
    sleep 1
    puts "Mailer done"
  end
end
