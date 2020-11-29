=begin
Allows to use colors and stuff everywhere.
=end

MIRROR_SIZE = 1024

class Window_Base < Window
  alias c_initialize initialize
  def initialize(x, y, width, height)
    c_initialize(x, y, width, height)
    @ex_p_color = [normal_color, true]
    @change_ex_p_color = true
  end
  
  def text_size_ex(text)
    text = text.gsub(/\e.\[.+\]/, "")
    text = text.gsub(/\e./, "")
    return text_size(text)
  end
  
  alias c_change_color change_color
  def change_color(color, enabled = true)
    c_change_color(color, enabled)
    if (@change_ex_p_color)
      @ex_p_color = [color, enabled]
    end
  end
  
  def draw_text_ex_p(rect, text, alignment = 0)
    text = convert_escape_characters(text)
    pos = {
      :x => rect.x,
      :y => rect.y,
      :new_x => rect.x,
      :height => calc_line_height(text)
    }
    size = text_size_ex(text)
    if (alignment == 1)
      pos[:x] += (rect.width - size.width) / 2
      pos[:y] += (rect.height - size.height) / 2
    end
    if (size.width > rect.width)
      mirror = Bitmap.new(MIRROR_SIZE, MIRROR_SIZE)
      contents_original = contents
      self.contents = mirror
    end
    @change_ex_p_color = false
    reset_font_settings
    @change_ex_p_color = true
    change_color(@ex_p_color[0], @ex_p_color[1])
    process_character(text.slice!(0, 1), text, pos) until text.empty?
    if (size.width > rect.width)
      self.contents = contents_original
      source = Rect.new(rect.x, rect.y, size.width, size.height)
      contents.stretch_blt(rect, mirror, source)
      mirror.dispose
    end
  end
  
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    change_color(normal_color, enabled)
    draw_text_ex_p(Rect.new(x + 24, y, width, line_height), item.name)
  end
end

class Window_Command < Window_Selectable
  def draw_item(index)
    change_color(normal_color, command_enabled?(index))
    draw_text_ex_p(item_rect_for_text(index), command_name(index), alignment)
  end
end