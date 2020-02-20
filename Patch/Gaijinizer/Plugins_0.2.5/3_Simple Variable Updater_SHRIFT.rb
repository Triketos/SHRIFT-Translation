#==============================================================================
# ■ Simple Variable Updater v1.2.1 for RPG Maker VX Ace by Lvl1VillagerA 
#------------------------------------------------------------------------------
# Fell free to use/modify it as long as you give me credit
#------------------------------------------------------------------------------
#　This script is intended for use when resuming a game session.
#
# User:
#  > add the [LVL1_SECTION] section in the game's ini file to use the script
#  > set [SVU_OPTION_1]=1 to disable permanently txt script execution on this game file
#  > set [SVU_OPTION_2]=N to enable certain features of the script (once)
#  N=0 nothing; N=1 enables default_method; N=LVL1_PASSWORD enables txt script eval
# Advanced User:
#  > write your txt script in ruby and put it on LVL1_PATH
# Dev:
#  Use this code on any game to assert if the script is being used
#  (you won't know what they did exactly or if they used it before):
#  #---
#  lvl1_script_used = false
#  begin
#    if LVL1_SVU.ini_checked? === true
#      lvl1_script_used = true
#    end
#  rescue NoMethodError
#  end
#  if lvl1_script_used === true
#    # - Your code if true
#  else
#    # - Your code if false
#  end
#  #---
#  Use this code to check if the text script eval has been disabled:
#  #---
#  lvl1_script_used_and_disabled = false
#  begin
#   if $game_switches[LVL1_SVU.get_switch_off_index] === true
#    lvl1_script_used_and_disabled = true
#   end
#  rescue NoMethodError
#  #---
#  And this one to disable it:
#  #---
#  begin
#   $game_switches[LVL1_SVU.get_switch_off_index] = true
#  rescue NoMethodError
#  #---
# Compatibility:
#  replaces Scene_Load.on_load_success
#==============================================================================

if defined?(LVL1_SVU::SVU_SECTION)
  msgbox("Warning, " + 
   "you have two or more copies of Simple Variable Updater in your Scripts.\n" +
   "The script ##{__FILE__} has been disabled.\n" +
   "You may still experience issues when loading a new save.\n" +
   "Please remove the duplicate scripts to make this error disappear.")
else
   
  module LVL1_SVU
    #--------------------------------------------------------------------------
    # ● Devs: change this to match your game needs
    #--------------------------------------------------------------------------

    SVU_PATH = '聖樹伝説.txt' # txt file to load
    SVU_SWITCH_OFF_INDEX = 999 # switch used to disable execution from txt file
    SVU_PASSWORD = 1567 # integer, password to enable the code execution from txt file once
    SVU_DEFAULT_ACCESS = 1 #0:OFF, 1:default_method, 2:txt script
    SVU_DEFAULT_USER_STRING = '' #Rename character
    
    FILE_INI = './Game.ini'
    SVU_SECTION = 'lvl1_script' # hidden section to change the script paramters
    SVU_OPTION_1 = 'svu_disable'
    SVU_OPTION_2 = 'svu_password'
    SVU_OPTION_3 = 'svu_user_string'
    def self.default_method
      #--------------------------------------------------------------------------
      # 'safe method' that can, for example, be used to:
      # -patch a bug
      # -rename the characters
      #--------------------------------------------------------------------------

		#Main caracter
		if @user_string == ''
		  if $game_actors[1].name == "カズヤ"
			$game_actors[1].name = "Kazuya"
		  end
		else
		  $game_actors[1].name = @user_string
		end
		
		#Haru
		if $game_actors[2].name == "Spring" || $game_actors[2].name == "ハル"
		  $game_actors[2].name = "Haru"
		end
		if $game_actors[2].name == "ハルちゃん"
		  $game_actors[2].name = "Haru-chan"
		end
		if $game_actors[2].name == "ハルさま"
		  $game_actors[2].name = "Haru-sama"
		end
		
		#Liz
		if $game_actors[3].name == "リズ"
		  $game_actors[3].name = "Liz"
		end
		if $game_actors[3].name == "リズちゃん"
		  $game_actors[3].name = "Liz-chan"
		end
		if $game_actors[3].name == "リズさま"
		  $game_actors[3].name = "Liz-sama"
		end
	  
    end

    def self.before_txt_script
      #--------------------------------------------------------------------------
      # executed before the txt script, can be used to add a watchdog
      #--------------------------------------------------------------------------
    end

    def self.after_txt_script
      #--------------------------------------------------------------------------
      # executed after the txt script, can be used to keep track of code execution
      #--------------------------------------------------------------------------
    end
    
    #--------------------------------------------------------------------------
    # ● don't change this
    #--------------------------------------------------------------------------
    
    GetPrivateProfileString   = Win32API.new('kernel32', 'GetPrivateProfileString'  , 'ppppip'      , 'i')
    
    def initialize
      load_script_settings
    end
    
    def self.load_script_settings
      
      #Read ini method
      buffer = [].pack('x256')
      section = SVU_SECTION
      filename = FILE_INI
      get_option = Proc.new do |key, default_value|
        l = GetPrivateProfileString.call(section, key, default_value, buffer, buffer.size, filename)
        buffer[0, l]
      end
      
      # Check Disabled
      @script_disabled = get_option.call(SVU_OPTION_1, '0').to_i === 1
      if @script_disabled === true
        $game_switches[SVU_SWITCH_OFF_INDEX] = true
      end
      
      # Check Password, give access
      @script_password = get_option.call(SVU_OPTION_2, '-1').to_i
      case @script_password
      when 0
        @script_access = 0
      when 1
        @script_access = 1
      when SVU_PASSWORD
        @script_access = 2
      else
        @script_access = SVU_DEFAULT_ACCESS
      end
      
      # Get user string
      @user_string = get_option.call(SVU_OPTION_3, SVU_DEFAULT_USER_STRING)

      #Confirm check
      @lvl1_ini_checked = true
    end
    
    #Get script variables and constants
    
    def self.get_switch_off_index
      return SVU_SWITCH_OFF_INDEX
    end
    
    def self.get_path
      return SVU_PATH
    end
    
    def self.get_script_access
      if @script_access === nil
        @script_access = 0
      end
      return @script_access
    end
    
    def self.ini_checked?
      return @lvl1_ini_checked === true || false
    end
    
  end #module


  #--------------------------------------------------------------------------
  # ● Devs: Change this if you don't want the code to run at Scene_Load.on_load_success
  #--------------------------------------------------------------------------
    
  class Scene_Load < Scene_File
    
    alias :previous_on_load_success :on_load_success

    #--------------------------------------------------------------------------
    # ● on_load_success (RMG Maker VX Ace script)
    #--------------------------------------------------------------------------
    
    def on_load_success
      
      #run previous
      previous_on_load_success
      
      begin
        #--------------------------------------------------------------------------
        # check the disable switch > check the ini file
        # if allowed runs txt script or if allowed runs default_method
        #--------------------------------------------------------------------------
        if $game_switches[LVL1_SVU.get_switch_off_index] === false
          if not LVL1_SVU.ini_checked? === true
            LVL1_SVU.load_script_settings
          end
          
          @lvl1_svu_path = LVL1_SVU.get_path
          if LVL1_SVU.get_script_access > 1 and File.exist?(@lvl1_svu_path)
            LVL1_SVU.before_txt_script
            eval(File.open(@lvl1_svu_path, "r").read)
            LVL1_SVU.after_txt_script
          else
            if LVL1_SVU.get_script_access > 0
              LVL1_SVU.default_method
            end
          end
        end
      rescue => e
        msgbox(e.backtrace.inspect )
      end
      
    end

  end #class

end #if