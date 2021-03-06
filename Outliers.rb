require 'rubygems'

Gem.clear_paths
ENV['GEM_HOME'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'
ENV['GEM_PATH'] = '/home/avishek/jruby/jruby-1.6.4/lib/ruby/gems/1.8'

require 'schema'
require 'set'
require 'ruby-processing'
require 'basis_processing'
require 'amqp'

include Math

class OutliersSketch < Processing::App
	app = self
	def setup
		frame_rate(30)
		no_loop
		smooth
		background(0,0,0)
		color_mode(HSB, 1.0)

		@old_points = []
		@points_to_highlight = []
		responses = Response.find(:all)
		@bins = []
		57.times do
			answer_distribution = []
			56.times {answer_distribution << 0}
			@bins << answer_distribution
		end
		responses.each do |r|
			bit_string = r[:pre_performance].to_s(2).rjust(56, '0')
			i = 0
			bit_string.each_char do |bit|
				@bins[r[:pre_total]][i] = @bins[r[:pre_total]][i] + 1 if bit == '1'
				i += 1
			end
		end

		sums = []
		57.times {|total| sums << responses.select {|r| r[:pre_total] == total}.count}
		@bins.each_index do |bin_index|
			@bins[bin_index].each_index do |answer_index|
				@bins[bin_index][answer_index] = @bins[bin_index][answer_index]/sums[bin_index].to_f
			end
		end

		@scale = 10

		x_basis_vector = {:x => 1.0, :y => 0.0}
		y_basis_vector = {:x => 0.0, :y => 1.0}

		@basis = CoordinateSystem.standard({:minimum => 0, :maximum => 56}, {:minimum => 0, :maximum => 56}, self)
		screen_transform = Transform.new({:x => 10.0, :y => -10.0}, {:x => 300, :y => 900})

		@screen = Screen.new(screen_transform, self, @basis)
		stroke(0,0,0)
		rect_mode(CENTER)
		@bins.each_index do |bin_index|
			@bins[bin_index].each_index do |answer_index|
				scaled_color = @bins[bin_index][answer_index]/1.0
				color_mode(HSB, 1.0)
				fill(0.5,1,scaled_color) if @bins[bin_index][answer_index] > 0
				fill(1.0,1,0) if @bins[bin_index][answer_index] == 0
				point = {:x => answer_index, :y => bin_index}
				@screen.plot(point, :track => true) {|o,m,s| rect(m[:x], m[:y], @scale, @scale)}
			end
		end
		@screen.draw_axes(10,10)
		@highlight_block = lambda do |o,m,s|
			fill(0.1,1,1)
			rect(m[:x], m[:y], @scale, @scale)
		end
#		Thread.new do
#			puts "Inside: #{Thread.current}"
#			EventMachine.run do
#				connection = AMQP.connect(:host => '127.0.0.1', :port => 5672)
#			  	puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
#			  	channel = AMQP::Channel.new(connection)
#			  	exchange = channel.direct('lambda_exchange', :auto_delete => true)
#				queue = channel.queue('lambda', :auto_delete => true)
#				answer_queue = channel.queue('lambda_response', :auto_delete => true)
#			  	queue.bind(exchange, :routing_key => 'lambda')
#			  	answer_queue.bind(exchange, :routing_key => 'lambda_response')

#				queue.subscribe do |message|
#					evaluate(message)
#				  	exchange.publish("#{YAML::dump(@points_to_highlight || [])}", :routing_key => 'lambda_response')
#				end
#			end
#		end
	end

	def evaluate(message)
		begin
			b = eval(message)
			@points_to_highlight = []
			@bins.each_index {|r| @bins[r].each_index {|c| @points_to_highlight << {:y => r, :x => c} if b.call(@bins[r][c])}}
			redraw
		rescue => e
			puts e
		end
	end

	def draw
	end
end

h = 1000
w = 1400
OutliersSketch.send :include, Interactive
OutliersSketch.new(:title => "My Sketch", :width => w, :height => h)

