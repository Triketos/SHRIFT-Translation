#==============================================================================
# ■ Game System Fix v1.3 for RPG Maker VX Ace by Lvl1VillagerA 
#------------------------------------------------------------------------------
# Fell free to use/modify it as long as you give me credit
#------------------------------------------------------------------------------
#　This script is intended to fool the game to use English settings.
#
# User:
#  > add the [GSF_SECTION] section in the game's ini file to use the script
#  > set GSF_OPTION_1=0/1 to disable/enable the script for all
#  > set GSF_OPTION_2=0/1 to disable/enable the script for troops naming
#  > set GSF_OPTION_3=0/1 to disable/enable the script for text width
#  > set GSF_OPTION_4=0/1 to disable/enable the script for name input
# Compatibility:
#   Replaced methods (disable in parameters):
#   Game_Troop.letter_table (enemy letter suffix)
#   Window_NameEdit.char_width (text width)
#   Window_NameInput.table (English/Japanese name input)
#  Added syntax:
#   LVL1_GSF (module) 
#  Other:
#   The japanese? method may be used in other scripts (or anti-Gaijin measures)
#   In the case, disable GSF_OPTION_1 and enable other options
#==============================================================================

module LVL1_GSF

  #--------------------------------------------------------------------------
  # ● Devs: change this to match your game needs
  #--------------------------------------------------------------------------
  
  #ini file location ([default]: './Game.ini', next to the game exe)
  FILE_INI = './Game.ini'
  
  #section in ini file, change script parameters after that
  GSF_SECTION = 'lvl1_script'
  
  #Enable option name
  GSF_OPTION_1 = 'gsf_enable'
  
  #Enable specific funtion troop option name 
  GSF_OPTION_2 = 'gsf_troop_enable'

  #Enable specific funtion width edit name  
  GSF_OPTION_3 = 'gsf_width_enable'
  
  #Enable specific funtion troop edit name  
  GSF_OPTION_4 = 'gsf_name_enable'

  #Enable specific funtion troop edit name  
  GSF_OPTION_5 = 'gsf_namepop_enable'

  #Enable specific funtion troop edit name  
  GSF_OPTION_6 = 'gsf_watermark_text'
  
  #Namepop script
  GSF_NAMEPOP_SPACE = '_'       #replaced by ' '
  GSF_NAMEPOP_MAKE_LINES = true #make new lines by (true) auto (false) substit*
  GSF_NAMEPOP_NEWLINE = '\r\n'  #*replaced by new line
  GSF_NAMEPOP_LINES_WIDTH = 10  #auto line length max (default:10)
  
  #Watermark
  GSF_WATERMARK_ON = true          #default watermark will appear if none visible
  GSF_WATERMARK_INCLUDES = 'patch' #must inlcude (lowercase) or default
  GSF_WATERMARK_FONT_SIZE = 20
      
  #Change these to avoid compatibility issues (mainly for debugging)
  #See define_method? function for more info
  GSF_JAPANESE_FIX_DEFAULT = '1' #Change japanese?
  GSF_TROOP_FIX_DEFAULT = '0'    #Change Troops
  GSF_WIDTH_FIX_DEFAULT = '0'    #Change width
  GSF_NAME_FIX_DEFAULT = '0'     #Change name
  GSF_NAMEPOP_FIX_DEFAULT = '1'  #Change to an english friendly namepop (mod)
  GSF_WATERMARK_TEXT_DEFAULT = 'English Patch' #water mark default test to differentiate games

  #--------------------------------------------------------------------------
  # ● don't change this
  #--------------------------------------------------------------------------
  
  GetPrivateProfileString     = Win32API.new('kernel32', 'GetPrivateProfileString'  , 'ppppip', 'i')
  WritePrivateProfileString   = Win32API.new('kernel32', 'WritePrivateProfileString', 'pppp'  , 'i')
  
  def self.load_script_settings
    buffer = [].pack('x256')
    section = GSF_SECTION
    filename = FILE_INI
    get_option = Proc.new do |key, default_value|
      l = GetPrivateProfileString.call(section, key, default_value, buffer, buffer.size, filename)
      buffer[0, l]
    end
    @gsf_japanese_fix = 
      get_option.call(GSF_OPTION_1, GSF_JAPANESE_FIX_DEFAULT) === '1'
    @gsf_troop_fix = 
      get_option.call(GSF_OPTION_2, GSF_TROOP_FIX_DEFAULT) === '1'
    @gsf_width_fix = 
      get_option.call(GSF_OPTION_3, GSF_WIDTH_FIX_DEFAULT) === '1'
    @gsf_name_fix = 
      get_option.call(GSF_OPTION_4, GSF_NAME_FIX_DEFAULT) === '1'
    @gsf_namepop_fix = 
      get_option.call(GSF_OPTION_5, GSF_NAMEPOP_FIX_DEFAULT) === '1'
    @gsf_watermark_text = 
      get_option.call(GSF_OPTION_6, GSF_WATERMARK_TEXT_DEFAULT)
    if GSF_WATERMARK_ON && @gsf_watermark_text.to_s.gsub(/\S/, "") == ""
      @gsf_watermark_text = GSF_WATERMARK_TEXT_DEFAULT
    else
      if GSF_WATERMARK_INCLUDES != ''
        if !@gsf_watermark_text.to_s.downcase.include?(GSF_WATERMARK_INCLUDES.downcase)
          @gsf_watermark_text = GSF_WATERMARK_TEXT_DEFAULT
        end
      end
    end
    @gsf_settings_loaded = true
  end
  
  def self.watermark
    return @gsf_watermark_text
  end
  
  def self.define_method?(method)
    if @gsf_settings_loaded != true
      load_script_settings
    end
    case method
    when 'Game_System.japanese?'
      return @gsf_japanese_fix
    when 'Game_Troop.letter_table'
      return @gsf_troop_fix
    when 'Window_NameEdit.char_width'
      return @gsf_width_fix
    when 'Window_NameInput.table'
      return @gsf_name_fix
    when 'Sprite_Character.start_namepop','Game_Event.tmnpop_game_event_setup_page_settings'
      return @gsf_namepop_fix
    when 'Scene_Title.create_foreground'
      return (@gsf_watermark_text != '')
    end
  end

  
end

#--------------------------------------------------------------------------
# ■ Modified RPGM methods: change if needed, disable only in parameters
#--------------------------------------------------------------------------


class Game_System
  if LVL1_GSF.define_method?('Game_System.japanese?') === true
   alias :void_japanese? :japanese?
   def japanese?
     false
   end
  end
end

class Game_Troop < Game_Unit
  if LVL1_GSF.define_method?('Game_Troop.letter_table') === true
   alias :letter_table_void :letter_table
   def letter_table
     return LETTER_TABLE_HALF
   end
 end
end

class Window_NameEdit < Window_Base
  if LVL1_GSF.define_method?('Window_NameEdit.char_width') === true
   alias :char_width_void :char_width
   def char_width
     return text_size("A").width 
   end
  end
end 

class Window_NameInput < Window_Selectable
  if LVL1_GSF.define_method?('Window_NameInput.table') === true
   alias :table_void :table
   def table
     return [LATIN1, LATIN2]
   end
  end
end

class Scene_Title < Scene_Base
  if LVL1_GSF.define_method?('Scene_Title.create_foreground') === true
    alias :lvl1_create_foreground :create_foreground
    def create_foreground
      lvl1_create_foreground
      h = LVL1_GSF::GSF_WATERMARK_FONT_SIZE
      w = Graphics.width
      @foreground_sprite.bitmap.font.size = h
      text = LVL1_GSF.watermark
      rect = Rect.new((((h * text.size) / 2) - w) / 2, 0, w, h)
      @foreground_sprite.bitmap.draw_text(rect, text, 1)
    end
  end
end
  
#--------------------------------------------------------------------------
# ■ Modified namepop methods: change if needed, disable only in parameters
#--------------------------------------------------------------------------

class Game_Event < Game_Character
  
 if LVL1_GSF.define_method?('Game_Event.tmnpop_game_event_setup_page_settings') === true
  if method_defined?(:tmnpop_game_event_setup_page_settings) === true
   alias :gsf_tmnpop_game_event_setup_page_settings :setup_page_settings
   def setup_page_settings
    tmnpop_game_event_setup_page_settings
    @namepop = nil
    if @list
     @namepop = $1 if /<namepop\s*(\S+?)>/i =~ @event.name
     @list.each do |list|
      if list.code == 108 || list.code == 408
       #Modified part:
       @namepop = $1 if /<namepop\s*(\S+?)>/i =~ list.parameters[0]
       @namepop=@namepop.gsub(LVL1_GSF::GSF_NAMEPOP_SPACE," ")if @namepop != nil
       #/Modified
      else
       break
      end
     end
    end
   end
  end
 end

end

class Sprite_Character < Sprite_Base
  
 if LVL1_GSF.define_method?('Sprite_Character.start_namepop') === true
  if method_defined?(:start_namepop) === true
   alias :start_namepop_void :start_namepop 
   def start_namepop
    dispose_namepop
    return if @namepop == "none" || @namepop == nil
    @namepop_sprite = ::Sprite.new(viewport)
    #Modified part:
    if LVL1_GSF::GSF_NAMEPOP_MAKE_LINES == true
     lines = []
     line = ''
     words = @namepop.split(" ")
     l_w = LVL1_GSF::GSF_NAMEPOP_LINES_WIDTH
     for i in 0..(words.length - 1) do
      word = words[i]
      if word.length + 1 + line.length <= l_w
       (line == '') ? (line = word) : (line = line + ' ' + word)
       lines.push(line) if  i == (words.length - 1)
      else
       lines.push(line) if line != ''
       lines.push(word) if (word.length > l_w) || (i == (words.length - 1))
       line = ''
      end
     end
    else
     lines = @namepop.split(LVL1_GSF::GSF_NAMEPOP_NEWLINE)
    end
    h_line = TMNPOP::FONT_SIZE + 4
    n = lines.count
    h = h_line * n
    w = h_line * l_w
    @namepop_sprite.bitmap = Bitmap.new(w, h)
    #/Modified
    @namepop_sprite.bitmap.font.size = TMNPOP::FONT_SIZE
    @namepop_sprite.bitmap.font.out_color.alpha = TMNPOP::FONT_OUT_ALPHA
    #Modified part:
    for i in 0..n do
     @namepop_sprite.bitmap.draw_text(0, i*h_line, w, h_line, lines[i], 1)
    end
    @namepop_sprite.ox = (h_line * l_w/2).to_i
    @namepop_sprite.oy = h
    #/Modified
    update_namepop
   end
  end
 end

end

#--------------------------------------------------------------------------
# ■ メッセージ座標ずらし (TARO Module) Fix
#--------------------------------------------------------------------------

class Window_Message < Window_Base
  
  #3 lines new page fix
  if defined? TARO::Message_Y_Switch
    alias :need_new_page_void? :need_new_page?
    def need_new_page?(text, pos)
      (self.y + pos[:y] + pos[:height] > Graphics.height || 
       pos[:y] + pos[:height] > contents.height
       ) && !text.empty?
     end
   end
   
end