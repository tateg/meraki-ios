# Cute little Cisco IOS clone using Dashboard API
# Everyone keeps complaining that we don't have a CLI
# Now shut up
# Written by Tate Galbraith
# Feb 2017
# API Key: b47331131f446ae4199a8b762d579d65717b1536
# N_646829496481117942

require 'dashboard-api'

# The first portion will be menu driven because people are idiots

def get_api
	puts
	puts "Welcome to APIOS! The faux IOS clone for Meraki Dashboard."
	print "To get started please enter your API key: "
	@api_key = gets.chomp
	puts
end

def init_api
	@api = DashboardAPI.new(@api_key)
end

def list_organizations
	@org_list = @api.list_all_organizations
	puts "Please select an organization from the list below by entering an ID: "
	@org_list.each do |hash|
		puts "Name: #{hash["name"]}, ID: #{hash["id"]}"
	end
	print "Enter Organization ID: "
	@org = gets.chomp
	puts
end

def list_networks
	@network_list = @api.get_networks(@org)
	puts "Please select a network from the list below by entering an ID: "
	@network_list.each do |hash|
		puts "Name: #{hash["name"]}, ID: #{hash["id"]}"
	end
	print "Enter Network ID: "
	@network = gets.chomp
	puts
end

def list_devices
	@device_list = @api.list_devices_in_network(@network)
	puts "Please select a device from the list below by entering the serial: "
	@device_list.each do |hash|
		puts "Name: #{hash["name"]}, Model: #{hash["id"]}, MAC: #{hash["mac"]}, Serial: #{hash["serial"]}"
	end
	print "Enter Device Serial: "
	@device_serial = gets.chomp
	@device = @api.get_single_device(@network, @device_serial)["name"]
	puts
end

def action_prompt
	@prompt = "#{@device}>"
	@prompt_enable = "#{@device}\#"
	@prompt_config = "#{@device} (config)\#"
	@prompt_interface = "#{@device} (config-if)\#"
	puts "You are now in the configuration for the selected device."
	puts "Try entering some Cisco IOS commands!"
	puts
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
get_api
init_api
list_organizations
list_networks
list_devices
action_prompt
action_checks