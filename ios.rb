# Cute little Cisco IOS clone using Dashboard API
# Everyone wants a CLI!
# Written by Tate Galbraith
# Feb 2017

require 'dashboard-api'
require 'colorize'
require 'text'
require 'curses'

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

# === Error handling === #

def error_catch(type)
	# This is for when you don't do something right!
	puts "---ERROR---".red
	case type
		when "empty"
			puts "Value cannot be empty!".red
		when "wrong_api"
			puts "API key not valid!".red
		when "wrong_org"
			puts "Organization ID not valid!".red
		when "wrong_network"
			puts "Network ID not valid!".red
		when "wrong_device"
			puts "Device serial number not valid!".red
		else
			puts "Something went wrong.".red
	end
end

# === Iniitial menu driven portion === #

def get_api
	loop do
		# Check to see if anything entered as argument first
		if ARGV[0]
			@api_key = ARGV[0]
		else
			# Loop waiting for validated input - error if empty
			print "Please enter your API key: "
			@api_key = gets.chomp
		end
		if @api_key.empty?
			error_catch("empty")
		else
			break
		end
	end
end

def init_api
	begin
		# Setup the API object using the input key
		@api = DashboardAPI.new(@api_key)
		# Catch errors for incorrect API key input by pulling org list
		@api.list_all_organizations
	rescue
		error_catch("wrong_api")
		# Exit if API key was entered as argument
		if ARGV[0] then exit end
		# Call API input again and retry API initialization
		get_api
		retry
	end
end

def show_org_list
	# Show list of orgs for selection
	@org_list = @api.list_all_organizations
	@org_list.each do |hash|
		print "\nName: #{hash["name"].green}, ID: #{hash["id"].to_s.green}\n"
	end
end

def select_org
	# Capture input for org ID
	loop do
		print "\nEnter Organization ID: "
		@org = gets.chomp
		if @org.empty?
			error_catch("empty")
		else
			break
		end
	end
end

def list_organizations
	begin
		# Check to see if key and org ID are passed	in
		if ARGV[1]
			@org = ARGV[1]
		elsif ARGV[0] and !ARGV[1]
			# Return all orgs and exit successfully
      print "\nAll organizations associated with API key listed below: \n"
      show_org_list
      exit(0)
		else
      print "\nPlease select organization ID from list belwo: \n"
			show_org_list
			select_org
		end
		# Test the org ID entered by running networks query
		@api.get_networks(@org)
	rescue
		error_catch("wrong_org")
		if ARGV[1] then exit end
		retry
	end
end

def show_network_list
  # Show list of networks for selection
  @network_list = @api.get_networks(@org)
  @network_list.each do |hash|
    print "\nName: #{hash["name"].green}, ID: #{hash["id"].green}\n"
  end
end

def select_network
  # Prompt for network ID
  loop do
    print "\nEnter network ID: "
    @network = gets.chomp
    if @network.empty?
      error_catch("empty")
    else
      break
    end
  end
end

def list_networks
	begin
		# Check to see if anything entered as argument first
		if ARGV[2]
			@network = ARGV[2]
		elsif ARGV[0-1] and !ARGV[3]
      # Show list of networks and exit cleanly
      print "\nList of networks in organization: \n"
      show_network_list
      exit(0)
    else
      # Show list of networks and prompt
      print "\nPlease select a network below:  \n"
      show_network_list
      select_network
		end
		# Test network ID by listing devices
		@api.list_devices_in_network(@network)
	rescue
		error_catch("wrong_network")
		if ARGV[2] then exit end
		retry
	end
end

def show_device_list
  # Show list of devices
  @device_list = @api.list_devices_in_network(@network)
	@device_list.each do |hash|
    print "\nName: #{hash["name"].green}, MAC: #{hash["mac"].green}, Serial: #{hash["serial"].green}\n"
	end
end

def select_device
  # Prompt for device selection
  loop do
	  print "\nEnter Device Serial: "
		@device_serial = gets.chomp
		if @device_serial.empty?
		  error_catch("empty")
	  else
		  break
		end
	end
end

def list_devices
	begin
		# Check to see if anything entered as argument first
		if ARGV[3]
			@device_serial = ARGV[3]
		elsif ARGV[0-2] and !ARGV[3]
      # Show list of devices and exit cleanly
      print "\nList of devices in network: \n"
      show_device_list
      exit(0)
    else
      # Show list of devices and prompt for selection
      print "\nSelect device from list below: \n"
      show_device_list
      select_device
		end
		# Load device ID from serial number into var - also test validity
		@device = @api.get_single_device(@network, @device_serial)
	rescue
		error_catch("wrong_device")
		if ARGV[3] then exit end
		retry
	end
end

def action_prompt
	# These are the different types of prompts that IOS uses based on level of config
  # Note: Prompt is redrawn for tab completion - IOS does this as well
  # It cannot be redrawn inline

	@prompt = "#{@device["name"]}>"
	@prompt_enable = "#{@device["name"]}\#"
	@prompt_config = "#{@device["name"]}(config)\#"
	@prompt_interface = "#{@device["name"]}(config-if)\#"
end

def distance(first, second)
  # Measure distance between words to fuzzy match commands similar to IOS
  @max_dist = 2
  if Text::Levenshtein.distance(first, second) <= @max_dist
    return true
  else
    return false
  end
end

# === Action loops for each prompt section === #

def action_check
  loop do
    print @prompt
    @input = gets.chomp
    if distance("exit", @input) then exit(0) end
    if distance("enable", @input) then break action_check_enable end
  end
end

def action_check_enable
  loop do
    print @prompt_enable
    @input = gets.chomp
    if distance("exit", @input) then break action_check end
    if distance("configure terminal", @input) then break action_check_configure end
  end
end

def action_check_configure
  loop do

    print @prompt_config
    @input = gets.chomp
    @input_all = @input.split(" ")

    if distance("exit", @input) then break action_check_enable end

    # Get interface command with interface number
    if distance("interface", @input)
      @input_intnum = @input_all[1].to_i
      if @input_intnum > 0 then action_check_interface end
    end

  end
end

def action_check_interface
  loop do
    print @prompt_interface
    @input = gets.chomp
    if distance("exit", @input) then break action_check_configure end
    if distance("shutdown", @input) then shutdown_switchport(@device_serial, @input_intnum) end
    if distance("no shutdown", @input) then enable_switchport(@device_serial, @input_intnum) end
  end
end

# === Switchport actions === #

def shutdown_switchport(serial, port)
  # Disable a switchport on a switch
  @api.update_switchport(serial, port, {"enabled" => false}) 
end

def enable_switchport(serial, port)
  # Enable a switchport on a switch
  @api.update_switchport(serial, port, {"enabled" => true})
end

# Call em'

welcome
get_api
init_api
list_organizations
list_networks
list_devices
action_prompt
action_check
