=begin
Namepop script patcher.
Allows to translate namepop names natively.
=end

REPLACEMENTS_PATH = "Gaijinizer/Gaijinizer patch/namepop.txt"
LINE_REGEXP = "(.+) = (.+)"
WIDTH_MUL = 20

module NamepopPatcher
  def self.initialize
    @replacements = {}
    File.readlines(REPLACEMENTS_PATH).each do |line|
      key, value = line.match(LINE_REGEXP).captures
      @replacements[key] = value
    end
  end
  
  def self.get_replacement(key)
    return @replacements[key]
  end
end

class Game_Event < Game_Character
  alias namepop_patcher_setup_page_settings setup_page_settings
  def setup_page_settings
    namepop_patcher_setup_page_settings
    if (@namepop)
      @namepop = NamepopPatcher.get_replacement(@namepop) || @namepop
    end
  end
end

class Sprite_Character < Sprite_Base
  def start_namepop
    dispose_namepop
    return if @namepop == "none" || @namepop == nil
    @namepop_sprite = ::Sprite.new(viewport)
    h = TMNPOP::FONT_SIZE + 4
    @namepop_sprite.bitmap = Bitmap.new(h * WIDTH_MUL, h)
    @namepop_sprite.bitmap.font.size = TMNPOP::FONT_SIZE
    @namepop_sprite.bitmap.font.out_color.alpha = TMNPOP::FONT_OUT_ALPHA
    @namepop_sprite.bitmap.draw_text(0, 0, h * WIDTH_MUL, h, @namepop, 1)
    @namepop_sprite.ox = h * (WIDTH_MUL / 2)
    @namepop_sprite.oy = h
    update_namepop
  end
end

NamepopPatcher.initialize