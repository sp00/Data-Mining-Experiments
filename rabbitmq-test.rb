require 'rubygems'
require 'amqp'
#gem 'rabbitmq-jruby-client'
#require 'rabbitmq_client'

EventMachine.run do
  connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
begin
  channel = AMQP::Channel.new(connection)
  exchange = channel.direct('lambda_exchange', :auto_delete => true)
  queue = channel.queue('lambda', :auto_delete => false, :passive => true)
  queue.bind(exchange, :routing_key => 'lambda')
  queue.status do |a, b|
    puts a
    puts b
  end
  exchange.publish "lambda {|all| all[0..3]}", :routing_key => 'lambda'
  queue.status do |a, b|
    puts a
    puts b
  end
rescue => e
	puts e
end
#  connection.close { EventMachine.stop }
end

#		client = RabbitMQClient.new
#		queue = client.queue('lambda')
#		exchange = client.exchange('lambda_exchange')
#		queue.bind(exchange)
#		queue.publish "{|x| }"
#		p "It is published"

