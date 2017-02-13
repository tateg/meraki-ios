# Cute little Cisco IOS clone using Dashboard API
# Everyone wants a CLI!
# Written by Tate Galbraith
# Feb 2017

require 'dashboard-api'
require 'colorize'

# The initial API connection can either be prompt driven or bypassed with args on start
# ARGV[0] = API key
# ARGV[1] = Organization ID
# ARGV[2] = Network ID
# ARGV[3] = Device serial number

def welcome
	# Super special welcome message
	puts puts "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =".yellow
	puts puts "Welcome to APIOS! The faux IOS clone for Meraki Dashboard.".green
	puts puts "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =".yellow
end

def error_catch
	# This is for when you don't do something right!
	puts puts "---ERROR---".red
	puts puts "Invalid entry or nothing entered!".red
end

def get_api
	# Check to see if anything entered as argument first
	if ARGV[0]
		@api_key = ARGV[0]
	else
		begin
			print "Please enter your API key: "
			@api_key = gets.chomp
			error_catch
		end
	end
end

def init_api
	# Setup the API object using the input key
	@api = DashboardAPI.new(@api_key)
end

def list_organizations
	# Check to see if anything entered as argument first	
	if ARGV[1]
		@org = ARGV[1]
	else
		@org_list = @api.list_all_organizations
		puts puts "Please select an organization from the list below by entering an ID: "
		@org_list.each do |hash|
			puts "Name: #{hash["name"]}, ID: #{hash["id"]}"
		end
		print "Enter Organization ID: "
		@org = gets.chomp
	end
end

def list_networks
	# Check to see if anything entered as argument first
	if ARGV[2]
		@network = ARGV[2]
	else
		@network_list = @api.get_networks(@org)
		puts puts "Please select a network from the list below by entering an ID: "
		@network_list.each do |hash|
			puts "Name: #{hash["name"]}, ID: #{hash["id"]}"
		end
		print "Enter Network ID: "
		@network = gets.chomp
	end
end

def list_devices
	# Check to see if anything entered as argument first
	if ARGV[3]
		@device_serial = ARGV[3]
	else
		@device_list = @api.list_devices_in_network(@network)
		puts puts "Please select a device from the list below by entering the serial: "
		@device_list.each do |hash|
			puts "Name: #{hash["name"]}, Model: #{hash["id"]}, MAC: #{hash["mac"]}, Serial: #{hash["serial"]}"
		end
		print "Enter Device Serial: "
		@device_serial = gets.chomp
		@device = @api.get_single_device(@network, @device_serial)["name"]
	end
end

def action_prompt
	# These are the different types of prompts that IOS uses based on level of config
	@prompt = "#{@device}>"
	@prompt_enable = "#{@device}\#"
	@prompt_config = "#{@device}(config)\#"
	@prompt_interface = "#{@device}(config-if)\#"
end

def action_checks
	print @prompt
	loop do
		@action_input = gets.chomp.downcase
		if @action_input.include? "en" or "ena" or "enab" or "enabl" or "enable"
			print @prompt_enable
			@action_input = gets.chomp.downcase
			if @action_input.include? "conf t" or "confi t" or "config t" or "config terminal"
				print @prompt_config
				@action_input = gets.chomp.downcase
				if @action_input.include? "int 3"
					print @prompt_interface
					@action_input = gets.chomp.downcase
					if @action_input == "sh" or "shu" or "shut" or "shutdown"
						@state = {"enabled" => "false"}
						@api.update_switchport(@device_serial, 3, @state)
					elsif @action_input == "no sh" or "no shu" or "no shut" or "no shutdown"
						@state = {"enabled" => "true"}
						@api.update_switchport(@device_serial, 3, @state)
					elsif @action_input == "exit"
						break
					else
						print @prompt_interface
					end
				end
			end
		elsif @action_input.include? "ex" or "exi" or "exit"
			break
		else
			puts "Try entering another command. Type 'help' for more info."
		end
	end
end

# Call em'
welcome
get_api
init_api
list_organizations
list_networks
list_devices
action_prompt
action_checks
