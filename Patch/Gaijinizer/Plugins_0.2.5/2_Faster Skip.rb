#==============================================================================
# ■ Faster Skip v1.2.1 for RPG Maker VX Ace by Lvl1VillagerA 
#------------------------------------------------------------------------------
# Fell free to use/modify it as long as you give me credit
#------------------------------------------------------------------------------
#　This script is intended to speed up messages and events on player input.
# It only speeds up events route when the game waits for their completion.
# It sets speed before the method execution, not during.
#
# User:
#  > add the [FS_SECTION] section in the game's ini file to use the script
#  > set FS_OPTION_1=0/1 to disable/enable the script
#  > set FS_OPTION_2=N to change skip speed
# Dev:
#  LVL1_FS.enable(bool)   #Use this to enable Faster Skip with scripts
#  LVL1_FS.enabled?       #Use this to test if Faster Skip is enabled
#  LVL1_FS.check_shortcut #Add this in your shortcut handler
# Compatibility:
#  Replaced methods (disable in parameters):
#   Window_Message.process_escape_character
#   Game_Interpreter.command_[201,204,212,213,221,223,224,225,230,232]
#   Game_Character.[process_move_command,process_route_end]
#   Window_BattleLog.message_speed
#   Scene_Battle.[wait_for_animation,wait_for_effect,wait,abs_wait]
#  Added syntax:
#   LVL1_FS (module) 
#   Game_Character @lvl1_move_speed (integer)
#   Game_Character @lvl1_speed_saved (boolean)
#  User Input:
#   Reserves 1 customizable RPG Maker VX Ace input
#  Other:
#   No game is bug free and RPGM Games ofter receive poor bug patches.
#   There is not certitude changing the game speed won't create any bug.
#   Known bug: player tped 2 cases off
#    Cause:        unidentified, tp after screen scroll and forced player route
#    Consequences: minor or game breaking if it prevents a route completion
#==============================================================================

module LVL1_FS

  #--------------------------------------------------------------------------
  # ● Devs: change this to match your game needs
  #--------------------------------------------------------------------------
  
  #ini file location ([default]: './Game.ini', next to the game exe)
  FILE_INI = './Game.ini'
  
  #section in ini file, change script parameters after that
  FS_SECTION = 'lvl1_script'
  
  #Enable option name
  FS_OPTION_1 = 'fs_enable'
  
  #Speed option name
  FS_OPTION_2 = 'fs_speed'
  
  # default fast forward speed (positive integer in string),use powers of 2 if possible
  #'1': only skip dialogue faster
  #'2': most animations are 2 times faster
  #'4': recommanded speed
  #'8': maximum speed before risking breaking some scenes
  FS_SPEED_DEFAULT = '8' 
 
  #'1': script enabled [default], '0': needs ini file or in-game activation
  FS_ENABLED_DEFAULT = '0'
  
  #RPGM maximum character speed, =6[default], higher may create bugs
  FS_CHARACTER_MAX_SPEED = 6
  
  #Max fast forward speed, =FS_CHARACTER_MAX_SPEED=6[default], other may create bugs
  FS_MAX_SPEED = 6 
  
  #Change script inputs
  #See Input section in RPG Maker VX Ace Help
  #Skip key
  def self.skip_pressed?        
    return Input.press?(:CTRL)  #Change to the skip key [default] :CTRL
  end
  
  #Enable shortcut
  def self.enable_shortcut?
    return Input.trigger?(:A)   #Change enable shortcut (skip input + this)
  end
  
  #Alert user when shortcut is pressed
  def self.shortcut_alert(bool)
    bool ? Sound.play_save : Sound.play_load # on : off
    #sprintf('Fast Skip %s', bool ? 'ON' : 'OFF')
  end
  
  #Change these to avoid compatibility issues (mainly for debugging)
  #See define_method? function for more info
  FS_NO_MESSAGE_WAIT = true       #message escape characters
  FS_FAST_ROUTE = true            #speeds up character route
  FS_FAST_SCROLL = true           #screen scroll
  FS_FAST_CHAR_ANIMATION = true   #animations targetting characters
  FS_FAST_FADE = true             #screen fadein/out
  FS_FAST_COLOR_SCREEN = true     #no screen flash/ faster tint
  FS_NO_SHAKE = true              #screen shake
  FS_FAST_CHAR_WAIT = true        #character wait
  FS_FAST_PICTURE = true          #move pictures (1)
  FS_FAST_BATTLE_MESSAGE = true   #battle log
  FS_FAST_BATTLE_EFFECT = true    #battle effect/animation
  FS_FAST_BATTLE_WAIT = true      #shortens othe battle pauses
  FS_ENABLE_SHORTCUT = true       #enable shortcut
  
  #(1) Bugged with SHRIFT
  #-----move picture:      no crash Recommanded: true
  
  #--------------------------------------------------------------------------
  # ● don't change this
  #--------------------------------------------------------------------------

  
  def self.define_method?(method)
    case method
    when 'Graphics.update'
      return FS_ENABLE_SHORTCUT
    when 'Window_Message.process_escape_character'
      return FS_NO_MESSAGE_WAIT
    when 'Game_Interpreter.command_201', 'Game_Character.process_move_command',
      'Game_Character.process_route_end'
      return FS_FAST_ROUTE
    when 'Game_Interpreter.command_204'
      return FS_FAST_SCROLL
    when 'Game_Interpreter.command_212', 'Sprite_Character.start_balloon'
      return FS_FAST_CHAR_ANIMATION
    when 'Game_Interpreter.command_221', 'Game_Interpreter.command_222'
      return FS_FAST_FADE
    when 'Game_Interpreter.command_223', 'Game_Interpreter.command_224'
      return FS_FAST_COLOR_SCREEN
    when 'Game_Interpreter.command_225'
      return FS_NO_SHAKE
    when 'Game_Interpreter.command_230'
      return FS_FAST_CHAR_WAIT
    when 'Game_Interpreter.command_232'
      return FS_FAST_PICTURE
    when 'Window_BattleLog.message_speed'
      return FS_FAST_BATTLE_MESSAGE
    when 'Scene_Battle.wait_for_animation', 'Scene_Battle.wait_for_effect'
      return FS_FAST_BATTLE_EFFECT
    when 'Scene_Battle.wait', 'Scene_Battle.abs_wait'
      return FS_FAST_BATTLE_WAIT
    end
  end
  
  
  GetPrivateProfileString     = Win32API.new('kernel32', 'GetPrivateProfileString'  , 'ppppip', 'i')
  WritePrivateProfileString   = Win32API.new('kernel32', 'WritePrivateProfileString', 'pppp'  , 'i')
  
  def self.load_script_settings
    buffer = [].pack('x256')
    section = FS_SECTION
    filename = FILE_INI
    get_option = Proc.new do |key, default_value|
      l = GetPrivateProfileString.call(section, key, default_value, buffer, buffer.size, filename)
      buffer[0, l]
    end
    @fs_enabled = 
      get_option.call(FS_OPTION_1, FS_ENABLED_DEFAULT).to_i === 1
    @fs_speed = get_option.call(FS_OPTION_2, FS_SPEED_DEFAULT).to_i
    if @fs_speed === nil || @fs_speed <=1 then @fs_speed = FS_SPEED_DEFAULT end
    cap_game_speed(@fs_speed)
  end
  
  def self.save_script_settings(not_fs_enabled = false)
    if @fs_enabled === nil || @fs_speed === nil
      load_script_settings
      if not_fs_enabled then @fs_enabled =! @fs_enabled end
    end
    section = FS_SECTION
    filename = FILE_INI
    set_option = Proc.new do |key, value|
      WritePrivateProfileString.call(section, key, value.to_s, filename)
    end
    set_option.call(FS_OPTION_1, @fs_enabled ? '1' : '0')
    set_option.call(FS_OPTION_2, @fs_speed)
  end
  
  def self.speed_up_char(speed, k)
    if k == 1 || FS_CHARACTER_MAX_SPEED < 1
      return speed
    else
      return [speed + Math.log2(k).to_i, FS_CHARACTER_MAX_SPEED].min
    end
  end

  def self.cap_game_speed(speed)
    return [speed, FS_MAX_SPEED].min
  end
  
  def self.check_shortcut
    if skip_pressed? && enable_shortcut?
      @fs_enabled=!@fs_enabled
      shortcut_alert(@fs_enabled)
      save_script_settings(true)
    end
  end
  
  def self.enable(bool)
    @fs_enabled = bool
  end
  
  def self.enabled?
    if @fs_enabled === nil || @fs_speed === nil then load_script_settings end
    check_shortcut
    return @fs_enabled
  end

  def self.skip?
    return skip_pressed? \
      && enabled? \
      && (($game_player.movable? || !$game_player.normal_walk?) \
        || @allow_skip)
  end

  def self.get_fast_forward_speed
    return @fs_speed
  end
  
  def self.set_allow_skip(bool)
    @allow_skip = bool
  end
  
end

  
#--------------------------------------------------------------------------
# ■ Modified RPGM methods: change if needed, disable only in parameters
#--------------------------------------------------------------------------

class Window_Message < Window_Base

  if LVL1_FS.define_method?('Window_Message.process_escape_character') === true
    alias :previous_process_escape_character :process_escape_character
    def process_escape_character(code, text, pos)
      LVL1_FS.set_allow_skip(true)
      case code.upcase
      when '.'
        if not LVL1_FS.skip? then wait(15) end
      when '|'
        if not LVL1_FS.skip? then wait(60) end
      when '!'
        if not LVL1_FS.skip? then input_pause end
      when '^'
        if not LVL1_FS.skip? then @pause_skip = true end
      end
      LVL1_FS.set_allow_skip(false)
      #in case the original is modded
      previous_process_escape_character(code, text, pos)
    end
  end
end

class << Graphics
  
  if LVL1_FS.define_method?('Graphics.update') === true
    alias :lvl1_update :update
    def update
      LVL1_FS.check_shortcut
      lvl1_update
    end
  end
end
  
class Game_Interpreter

  if LVL1_FS.define_method?('Game_Interpreter.command_201') === true
    #--------------------------------------------------------------------------
    # * Transfer Player
    #--------------------------------------------------------------------------
    alias :lvl1_command_201 :command_201
    def command_201
      lvl1_command_201
      if @lvl1_speed_saved === true
        @move_speed = @lvl1_move_speed
        @lvl1_speed_saved = false
      end
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_204') === true
    #--------------------------------------------------------------------------
    # * Scroll Map
    #--------------------------------------------------------------------------
    alias :command_204_void :command_204
    def command_204
      LVL1_FS.set_allow_skip(true)
      return if $game_party.in_battle
      Fiber.yield while $game_map.scrolling?
      if LVL1_FS.skip?
        $game_map.start_scroll(@params[0], @params[1], 
          @params[2] + LVL1_FS.get_fast_forward_speed)
      else
        $game_map.start_scroll(@params[0], @params[1], @params[2])
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_212') === true
    #--------------------------------------------------------------------------
    # * Show Animation
    #--------------------------------------------------------------------------
    alias :command_212_void :command_212
    def command_212
      LVL1_FS.set_allow_skip(true)
      character = get_character(@params[0])
      if character
        character.animation_id = @params[1]
        if !LVL1_FS.skip? && @params[2]
          Fiber.yield while character.animation_id > 0
        end
      end
      LVL1_FS.set_allow_skip(false)
    end
  end

  if LVL1_FS.define_method?('Game_Interpreter.command_221') === true
    #--------------------------------------------------------------------------
    # * Fadeout Screen
    #--------------------------------------------------------------------------
    alias :command_221_void :command_221
    def command_221
      LVL1_FS.set_allow_skip(true)
      Fiber.yield while $game_message.visible
      if LVL1_FS.skip?
        screen.start_fadeout((30.0/LVL1_FS.get_fast_forward_speed).ceil)
        wait((30.0/LVL1_FS.get_fast_forward_speed).ceil)
      else
        screen.start_fadeout(30)
        wait(30)
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_222') === true
    #--------------------------------------------------------------------------
    # * Fadein Screen
    #--------------------------------------------------------------------------
    alias :command_222_void :command_222
    def command_222
      LVL1_FS.set_allow_skip(true)
      Fiber.yield while $game_message.visible
      if LVL1_FS.skip?
        screen.start_fadein((30.0/LVL1_FS.get_fast_forward_speed).ceil)
        wait((30.0/LVL1_FS.get_fast_forward_speed).ceil)
      else
        screen.start_fadein(30)
        wait(30)
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_223') === true
    #--------------------------------------------------------------------------
    # * Tint Screen
    #--------------------------------------------------------------------------
    alias :command_223_void :command_223
    def command_223
      LVL1_FS.set_allow_skip(true)
      if LVL1_FS.skip?
        screen.start_tone_change(@params[0], (@params[1].to_f/LVL1_FS.get_fast_forward_speed.to_f).ceil)
        wait((@params[1].to_f/LVL1_FS.get_fast_forward_speed.to_f).ceil) if @params[2]
      else
        screen.start_tone_change(@params[0], @params[1])
        if @params[2] then wait(@params[1]) end
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_224') === true
    #--------------------------------------------------------------------------
    # * Screen Flash
    #--------------------------------------------------------------------------
    alias :lvl1_command_224 :command_224
    def command_224
      LVL1_FS.set_allow_skip(true)
      if not LVL1_FS.skip?
        lvl1_command_224
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_225') === true
    #--------------------------------------------------------------------------
    # * Screen Shake
    #--------------------------------------------------------------------------
    alias :lvl1_command_225 :command_225
    def command_225
      LVL1_FS.set_allow_skip(true)
      if not LVL1_FS.skip?
        lvl1_command_225
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_230') === true
    #--------------------------------------------------------------------------
    # ● Wait
    #--------------------------------------------------------------------------
    alias :lvl1_command_230 :command_230
    
    def command_230
      LVL1_FS.set_allow_skip(true)
      if LVL1_FS.skip? then
        wait((@params[0].to_f/LVL1_FS.get_fast_forward_speed.to_f).ceil)
      else
        lvl1_command_230
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
  if LVL1_FS.define_method?('Game_Interpreter.command_232') === true
    #--------------------------------------------------------------------------
    # * Move Picture
    #--------------------------------------------------------------------------
    alias :command_232_void :command_232
    def command_232
      LVL1_FS.set_allow_skip(true)
      if @params[3] == 0    # Direct designation
        x = @params[4]
        y = @params[5]
      else                  # Designation with variables
        x = $game_variables[@params[4]]
        y = $game_variables[@params[5]]
      end
      if LVL1_FS.skip?
        screen.pictures[@params[0]].move(
          @params[2], x, y, @params[6], @params[7], @params[8], @params[9],
          (@params[10].to_f/LVL1_FS.get_fast_forward_speed.to_f).ceil)
        wait(@params[10]) if @params[11]
      else
        screen.pictures[@params[0]].move(@params[2], x, y, @params[6],
          @params[7], @params[8], @params[9], @params[10])
        wait(@params[10]) if @params[11]
      end
      LVL1_FS.set_allow_skip(false)
    end
  end
  
end

class Game_Character < Game_CharacterBase
  
  if LVL1_FS.define_method?('Game_Character.process_move_command') === true
    #--------------------------------------------------------------------------
    # * Process Move Command
    #--------------------------------------------------------------------------
    alias :process_move_command_void :process_move_command
    def process_move_command(command)
      
      #---------CHANGED PART----------
      if LVL1_FS.skip?
        if not (@lvl1_speed_saved === true)
          @lvl1_speed_saved = true
          @lvl1_move_speed = @move_speed
          @move_speed = LVL1_FS.speed_up_char(@move_speed, LVL1_FS.get_fast_forward_speed)
        end
      else
        if @lvl1_speed_saved === true
          @lvl1_speed_saved = false
          @move_speed = @lvl1_move_speed
        end
      end
      #------------------------------
      
      params = command.parameters
      case command.code
      when ROUTE_END;               process_route_end
      when ROUTE_MOVE_DOWN;         move_straight(2)
      when ROUTE_MOVE_LEFT;         move_straight(4)
      when ROUTE_MOVE_RIGHT;        move_straight(6)
      when ROUTE_MOVE_UP;           move_straight(8)
      when ROUTE_MOVE_LOWER_L;      move_diagonal(4, 2)
      when ROUTE_MOVE_LOWER_R;      move_diagonal(6, 2)
      when ROUTE_MOVE_UPPER_L;      move_diagonal(4, 8)
      when ROUTE_MOVE_UPPER_R;      move_diagonal(6, 8)
      when ROUTE_MOVE_RANDOM;       move_random
      when ROUTE_MOVE_TOWARD;       move_toward_player
      when ROUTE_MOVE_AWAY;         move_away_from_player
      when ROUTE_MOVE_FORWARD;      move_forward
      when ROUTE_MOVE_BACKWARD;     move_backward
      when ROUTE_JUMP;              jump(params[0], params[1])
      when ROUTE_WAIT
        #---------CHANGED PART----------
        if LVL1_FS.skip? then
          @wait_count = (params[0].to_f/LVL1_FS.get_fast_forward_speed.to_f).ceil - 1
        else
          @wait_count = params[0] - 1
        end
        #-------------------------------
      when ROUTE_TURN_DOWN;         set_direction(2)
      when ROUTE_TURN_LEFT;         set_direction(4)
      when ROUTE_TURN_RIGHT;        set_direction(6)
      when ROUTE_TURN_UP;           set_direction(8)
      when ROUTE_TURN_90D_R;        turn_right_90
      when ROUTE_TURN_90D_L;        turn_left_90
      when ROUTE_TURN_180D;         turn_180
      when ROUTE_TURN_90D_R_L;      turn_right_or_left_90
      when ROUTE_TURN_RANDOM;       turn_random
      when ROUTE_TURN_TOWARD;       turn_toward_player
      when ROUTE_TURN_AWAY;         turn_away_from_player
      when ROUTE_SWITCH_ON;         $game_switches[params[0]] = true
      when ROUTE_SWITCH_OFF;        $game_switches[params[0]] = false
      when ROUTE_CHANGE_SPEED
        #---------CHANGED PART----------
        if LVL1_FS.skip?
          @lvl1_speed_saved = true
          @lvl1_move_speed = params[0]
          @move_speed = LVL1_FS.speed_up_char(params[0], LVL1_FS.get_fast_forward_speed)
        else
          if @lvl1_speed_saved === true
            @lvl1_speed_saved = false
          end
          @move_speed = params[0]
        end
        #-------------------------------
      when ROUTE_CHANGE_FREQ;       @move_frequency = params[0]
      when ROUTE_WALK_ANIME_ON;     @walk_anime = true
      when ROUTE_WALK_ANIME_OFF;    @walk_anime = false
      when ROUTE_STEP_ANIME_ON;     @step_anime = true
      when ROUTE_STEP_ANIME_OFF;    @step_anime = false
      when ROUTE_DIR_FIX_ON;        @direction_fix = true
      when ROUTE_DIR_FIX_OFF;       @direction_fix = false
      when ROUTE_THROUGH_ON;        @through = true
      when ROUTE_THROUGH_OFF;       @through = false
      when ROUTE_TRANSPARENT_ON;    @transparent = true
      when ROUTE_TRANSPARENT_OFF;   @transparent = false
      when ROUTE_CHANGE_GRAPHIC;    set_graphic(params[0], params[1])
      when ROUTE_CHANGE_OPACITY;    @opacity = params[0]
      when ROUTE_CHANGE_BLENDING;   @blend_type = params[0]
      when ROUTE_PLAY_SE;           params[0].play
      when ROUTE_SCRIPT;            eval(params[0])
      end
    end
  end
  
  if LVL1_FS.define_method?('Game_Character.process_route_end') === true
    #--------------------------------------------------------------------------
    # * Process Move Route End
    #--------------------------------------------------------------------------
    alias :lvl1_process_route_end :process_route_end
    def process_route_end
      if @lvl1_speed_saved === true
        @move_speed = @lvl1_move_speed
        @lvl1_speed_saved = false
      end
      lvl1_process_route_end
    end
  end
end

class Window_BattleLog < Window_Selectable
  
  if LVL1_FS.define_method?('Window_BattleLog.message_speed') === true
    #--------------------------------------------------------------------------
    # * Get Message Speed
    #--------------------------------------------------------------------------
    alias :lvl1_message_speed :message_speed
    def message_speed
      if LVL1_FS.skip?
        return (20.0/LVL1_FS.get_fast_forward_speed).ceil
      else
        return lvl1_message_speed
      end
    end
  end
end

class Scene_Battle < Scene_Base

  if LVL1_FS.define_method?('Scene_Battle.wait_for_animation') === true
    #--------------------------------------------------------------------------
    # * Wait Until Animation Display has Finished
    #--------------------------------------------------------------------------
    alias :wait_for_animation_void :wait_for_animation
    def wait_for_animation
      update_for_wait
      if not LVL1_FS.skip?
        update_for_wait while @spriteset.animation?
      end
    end
  end
    
  if LVL1_FS.define_method?('Scene_Battle.wait_for_effect') === true
    #--------------------------------------------------------------------------
    # * Wait Until Effect Execution Ends
    #--------------------------------------------------------------------------
    alias :wait_for_effect_void :wait_for_effect
    def wait_for_effect
      update_for_wait
      if not LVL1_FS.skip?
        update_for_wait while @spriteset.effect?
      end
    end
  end
  
  if LVL1_FS.define_method?('Scene_Battle.wait') === true
  #--------------------------------------------------------------------------
  # * Wait
  #--------------------------------------------------------------------------
    alias :lvl1_wait :wait
    def wait(duration)
      if LVL1_FS.skip?
        (duration/LVL1_FS.get_fast_forward_speed).ceil.times \
        {|i| update_for_wait if i < duration / 2 || !show_fast? }
      else
        lvl1_wait(duration)
      end
    end
  end

  if LVL1_FS.define_method?('Scene_Battle.abs_wait') === true
    #--------------------------------------------------------------------------
    # * Wait (No Fast Forward)
    #--------------------------------------------------------------------------
    alias :lvl1_abs_wait :abs_wait
    def abs_wait(duration)
      if not LVL1_FS.skip?
        lvl1_abs_wait(duration)
      end
    end
  end
  
end

class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # * Start Balloon Icon Display
  #--------------------------------------------------------------------------
  if LVL1_FS.define_method?('Scene_Battle.abs_wait') === true
    alias :lvl1_start_balloon :start_balloon
    def start_balloon
      LVL1_FS.set_allow_skip(true)
      dispose_balloon
      
      d = 8 * balloon_speed + balloon_wait
      if LVL1_FS.skip?
        @balloon_duration = (d.to_f / LVL1_FS.get_fast_forward_speed).ceil
      else
        @balloon_duration = d
      end
      
      @balloon_sprite = ::Sprite.new(viewport)
      @balloon_sprite.bitmap = Cache.system("Balloon")
      @balloon_sprite.ox = 16
      @balloon_sprite.oy = 32
      update_balloon
      LVL1_FS.set_allow_skip(false)
    end
  end
end