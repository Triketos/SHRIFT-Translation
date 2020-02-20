#==============================================================================
# ■ Gaijinizer::Patchmaker v0.2.3 for RPG Maker VX Ace
#------------------------------------------------------------------------------
# Fell free to use/modify it as long as you give me credit
#------------------------------------------------------------------------------
# This script can be used without other Gaijinizer scripts.
# Novice translators should pick one of the already existing configurations.
# Others can have fun with the features they are interested in.
# Basic customization should be easy wherever you read #Alias me
#
# Features:
#  >Write text patch from RPG Maker VX Ace
#  >>Customizable filters to sort useless content
#  >>Customizable syntax, adaptable to RPG Maker Trans V4.5
#  >Apply text patch to RPG Maker VX Ace
#  >>Commentable
#  >>Multiple tranlsation languages
#  >>Resilient to game updates
#  >>Add plugins
#  >>Update Patchmaker from patch
#  >Multiple patch formats
#  >>Translated game assets (! sharing such a patch is illegal even if often tolerated)
#  >>Text files (! the untranslated text within the patch is still subject to copyright)
#  >>Hash (no copyrighted material but patching is slightly more difficult for the end user)
#  >Switch language on restart
#  >Translation Data stored as Hash (usable by other applications)
#  >Execution time < 1min (Write ~ 6s, Apply ~ 12s)
# Planned:
#  >Compatibility with dynamic text replacer (WIP)
#  >Remake patch from updated games (WIP)
#  >Better Script Regex extraction
#  >Extract translation from data folder (to take over translations on hiatus)
#  >External patcher (to avoid having to share Script.rvdata2 which may contain copyrighted material)
#  >Ruby optimization
#==============================================================================

module Gaijinizer
  #
end



module Gaijinizer::Patchmaker

  #--------------------------------------------------------------------------
  # ● Parameters (avoid changing CONSTANTS when a @variable is available)
  #--------------------------------------------------------------------------
  
  #General
  SCRIPT_VERSION  = '0.2.3'
  PATCH_VERSION  = '1'
  
  LOAD_DATA_ALT   = true
  IGNORE_CACHE    = false
  
  RESET_CACHE     = true; @reset_cache = RESET_CACHE
  
  #script ini
  INI_FILE    = './Gaijinizer/Gaijinizer.ini' #'./Game.ini'
  SECTION     = 'patchmaker' #'lvl1_script'
  EVAL_PATH   = 'ruby_file_eval'; @ruby_file_eval = nil
  PATCH_NEW   = 'patch_new_directory'; @patch_new_directory = nil
  PATCH_TL    = 'patch_tl_directory'; @patch_tl_directory = nil
  PATCH_IN    = 'patch_in_directory'; @patch_in_directory = nil #limits the scope
  PATCH_OUT   = 'patch_out_directory'; @patch_out_directory = nil
  PATCH_UP    = 'patch_update_directory'; @patch_update_directory = nil
  PLUGIN      = 'plugin_directory'; @plugin_directory = nil
  FORMAT      = 'patch_format'; @patch_format = nil
  LANG        = 'language'; @language = nil
  START       = 'on_start'; @on_start = nil
  UP_MODE     = 'auto_update_mode'; @auto_update_mode = nil
  TL_UP_MODE  = 'translation_update_mode'; @translation_update_mode = nil
  PIC_IN      = 'pictures_in_directory'; @pictures_in_directory = nil
  PIC_OUT     = 'pictures_out_directory'; @pictures_out_directory = nil
  
  #game ini
  GAME_INI_FILE       = 'Game.ini'; @game_ini_file = GAME_INI_FILE
  GAME_INI_FILE_SUB   = 'Game_.ini'; @game_ini_file_sub = GAME_INI_FILE_SUB
  MAIN_SECTION        = 'Game'; @main_section = MAIN_SECTION
  SCRIPTS_OPTION      = 'Scripts'; @scripts_option = SCRIPTS_OPTION
  SCRIPTS_DFLT        = 'Data/Scripts.rvdata2'; @scripts_dflt = SCRIPTS_DFLT
  UPDATE_INI_OPTIONS  = true; @update_ini_options = UPDATE_INI_OPTIONS
  
  #Patch syntax
  FILE_HEADER   = '> GAIJINIZER PATCH FILE'; @file_header = FILE_HEADER
  RMGMT_BS      = '> BEGIN STRING'; @rmgmt_bs = RMGMT_BS
  RMGMT_C       = '> CONTEXT: '; @rmgmt_c = RMGMT_C
  RMGMT_ES      = '> END STRING'; @rmgmt_es = RMGMT_ES
  UNLED_TAG     = ' < UNTRANSLATED'; @untled_tag = UNLED_TAG
  UNUSED_TAG    = ' < UNUSED'; @unused_tag = UNUSED_TAG
  NO_CONTEXT    = 'None'; @no_context = NO_CONTEXT
  UNUSED_TEXT   = 'unused.txt'; @unused_text = UNUSED_TEXT
  
  #Additional syntax
  LANG_TAG            = '> LANGUAGE: '; @lang_tag = LANG_TAG
  DFLT_LANG           = 'jp'; @dflt_lang = DFLT_LANG
  DFLT_TLED_LANG      = 'en'; @dflt_tled_lang = DFLT_TLED_LANG
  FILE_HEADER_UNUSED  = '> UNUSED TRANSLATION'; @file_header_unused = FILE_HEADER_UNUSED
  
  #Context syntax
  CONTEXT_JOIN    = '/'; @context_join = CONTEXT_JOIN
  CONTEXT_SAFE    = '_'; @context_safe = CONTEXT_SAFE #Replaces forbidden characters in context (like CONTEXT_JOIN)
  
  #RPGM Class
  EVC_CLASS   = 'RPG::EventCommand'; @evc_class  = EVC_CLASS
  
  #Files
  PATCHER_CACHE     = 'Gaijinizer/Patcher_Cache'; @patcher_cache = PATCHER_CACHE
  PATCH_EXTENSION   = '.txt'; @patch_extension  = PATCH_EXTENSION
  DATA_PATTERN      = 'Data/*.rvdata2'; @data_pattern = DATA_PATTERN
  INI_PATTERN       = '*.ini'; @ini_pattern = INI_PATTERN
  
  #Patch update
  AUTO_UPDATE_TL      = true; @auto_update_tl = AUTO_UPDATE_TL
  ADD_PLUGINS_AFTER  = ''; @add_plugins_after = ADD_PLUGINS_AFTER
  
  #Filters
  CONTEXT_EXCLUDE   = %w(Animations Tilesets AudioFile bgm bgs battle_bgm battle_end_me sounds gameover_me title_bgm)
  @context_exclude  = CONTEXT_EXCLUDE
  CONTEXT_INCLUDE   = %w(name display_name nickname description basic params etypes commands message1 message2 message3 message4 currency_unit Choice game_title skill_types weapon_types armor_types elements) #note)
  @context_include  = CONTEXT_INCLUDE
  CONTEXT_TEXT_EXCLUDE  = [%r{\ACommonEvents_[0-9]+/name\z}, %r{\AMap[0-9]+/events/[0-9]+/name\z}, /\ANone\z/]
  @context_text_exclude = CONTEXT_TEXT_EXCLUDE
  TEXT_INCLUDE  = [/\p{Hiragana}|\p{Katakana}|\p{Han}/] 
  #[\x2E80-\x2FD5]|
  #[\xFF5F-\xFF9F]|
  #[\x3000-\x303F]|[\x31F0-\x31FF\x3220-\x3243\x3280-\x337F]/]
  @text_include = TEXT_INCLUDE
  SCRIPT_REGEX  = %r{
    (?:(?<!.)=begin(?:[\s]|\n)+(?:|.|\n)*(?:\n=end(?:[\s]|\n))| #=begin comment =end
    (?<!\$)"(?:"|(?:\#\{[^\}]\}|\\"|\\\\|[^"])*")| # "string"
    (?<!\$)'(?:'|(?:\\'|\\\\|[^'])*')| # 'string'
    (?:(?<=[,:;/\[(!=+\-])\s*|(?<=\n)|^)/(?:\#{.*}|\\/|\\\\|[^/])*/[a-zA-Z]*| # [space]/regex/modifier
    (?<!\\)\#[^\n]*) # #comment
  }x
  #TODO: %Q, %q, %W, %w, %r, improve regex
  @script_regex = SCRIPT_REGEX
  INI_REGEX     = %r{
    (?:(?<!.)\[.+\])| # [section]
    (?:(?<!.).+=.+)   # option = value
  }x
  @ini_regex    = INI_REGEX

  #UI
  SHOW_UI = false; @show_ui = SHOW_UI

  
  #--------------------------------------------------------------------------
  # ● Main
  #--------------------------------------------------------------------------

  def self.main
    # #Alias me to change what this script will do
    case on_start
    when 'show_ui' then #show_ui
    when 'new_patch' then new_patch
    when 'patch_game' then patch_game
    when 'test' then test
    end
  end
  
  def self.apply_patch_player
    # #Alias me to change how the player will patch his game
    #PLACEHOLDER
  end
  
  def self.module_eval(s)
    begin
      eval(s)
    rescue
    end
  end
  
  #-------------------------AVOID MODIFICATION-------------------------------

  DEBUG = true
  LOG_FILE = "Log.txt"
  
  def self.initialize_log(log_file = LOG_FILE, header = "Time:#{Time.now}, Script Version:#{script_version}\n")
    File.open(LOG_FILE, 'w') {|f| f.write(header)}
  end
  
  def self.log_this(text, ok = DEBUG, log_file = LOG_FILE)
    return if ok === false
    File.open(log_file, 'w') unless File.exists?(log_file)
    f = File.open(log_file, "a")
    f << "#{text}\n"
    f.close
  end

  
  def self.test
    t = Time.now
    #test me
    make_patch
    #/test me
    msgbox(Time.now - t)
    rgss_stop
  end

  def self.new_patch
    return unless patch_in_directory == "" || File.directory?(patch_in_directory)
    write_patch_in_dir(get_files_data, patch_new_directory)
  end


  def self.patch_game(tl_data = [], c_ref_to_c = {}, var = {})
    return unless patch_exist?
    tl_data = get_translation_from_dir(patch_tl_directory) #OK
    get_changes(get_files_data, tl_data, c_ref_to_c, var)
    replace_data = [c_ref_to_c, tl_data[1], {}]
    files_translation(replace_data, false)
    var["added_s"] = replace_data[2]
    write_updated_translation(get_files_data, tl_data, c_ref_to_c, var)
    update_ini_file if @update_ini_options
  end

  def self.remake_patch
    #PLACEHOLDER
  end

  def self.extract_patch
    #PLACEHOLDER
  end

  def self.get_replace_data
    #PLACEHOLDER
  end
  
  #--------------------------------------------------------------------------
  # ● UI
  #--------------------------------------------------------------------------
  
  def self.get_ui_options
    #Alias me to change UI
    return {
      lang: {
        name: "Language",
        description: "Select the game language\n(current: #{language})",
        changes: {
          en: "language('en')",
          jp: "language('jp')"
        }
      },
      format: {
        name: "Patch Format",
        description: "Select the patch source\n(current: from #{patch_format})",
        changes: {
          default: "patch_format('default')",
          txt: "patch_format('txt')" #marshal in temp folder
        }
      },
      replace: {
        name: "Replace Method",
        description: "Select how texts will be replaced [WIP]\n(load_data)",
        changes: {
          load_data: ""
        },
        enabled: false
      },
      start: {
        name: "On Start",
        description: "Select what to do next time the game starts\n(current: #{on_start})",
        changes: {
          show_ui: "on_start('show_ui')",
          new_patch: "on_start('new_patch')",
          patch_game: "on_start('patch_game')"
        }
      }
    }
  end
  
  #-------------------------AVOID MODIFICATION-------------------------------
  
  def self.update_ui_options(ui_options, option, value)
    eval(ui_options[option][:changes][value])
    return get_ui_options
  end
  
  def self.show_ui?
    return on_start == "show_ui"
  end
  
  #--------------------------------------------------------------------------
  # ●  Patch Hash <=> Game Files (translated | untranslated)
  #--------------------------------------------------------------------------

  def self.files_translation(data, to_hash = true)
    # #Alias me to change where to look for data
    # default: 
    # -- Look for strings in objects in data folder .rvdata2 files only
    # -- Look for string regex matches in ini files
    
    if to_hash == false
      dir_in = patch_in_directory
      dir_out = patch_out_directory
    end
    
    #Data
    files = Dir.glob(@data_pattern)
    files.each_with_index do |file, i|
      folders = file.split('/')
      obj     = marshal_load_data(file) #load object from file
      update_object(obj, [folders.last.split('.')[-2]], to_hash, data)
      update_file_object(obj, file, dir_in, dir_out) if to_hash == false
    end #each
    #Ini
    files = Dir.glob(@ini_pattern)
    files.each_with_index do |file, i|
      folders = file.split('/')
      encoding = ""
      text = read_encoded_file(file, encoding)
      update_script(text, folders, to_hash, data, 
        @ini_regex, 
        :do_with_ini_match,
        :ini_index_array
      )
      update_file_text(text, file, dir_in, dir_out) if to_hash == false
    end #each
    #Text
    #Change me to add files to translate
    return data
  end
      
  #-------------------------AVOID MODIFICATION-------------------------------

  def self.patch_exist?
    return File.directory?(patch_tl_directory)
  end
  
  #Get patch hash
  def self.get_files_data
    data_ji_hash_cache = "#{@patcher_cache}/data_ji_hash"
    if !File.exist?(data_ji_hash_cache) || IGNORE_CACHE
      data = {}
      files_translation(data)
      File.open(data_ji_hash_cache, "wb") { |f| Marshal.dump(data, f)}
    else
      File.open(data_ji_hash_cache, "rb") { |f| data = Marshal.load(f)}
    end
    return data
  end
  
  #Get updated file path #TODO
  def self.update_path(file,
    dir_in = patch_in_directory, 
    dir_out = patch_out_directory, 
    new_name = '',
    mkdir = true
  )
    if    new_name  = '' && dir_in  = ''
      path  = "#{dir_out}/#{file}"
    elsif new_name != '' && dir_in  = ''
      path  = "#{dir_out}/#{file.sub(%r{^[^/]+$},'').sub(%r{/[^/]+$},'')}/#{new_name}"
    elsif new_name  = '' && dir_in != ''
      path  = file.sub(dir_in, dir_out)
    else#if  _name != '' && dir_in != ''
      path  = "#{file.sub(dir_in, dir_out).sub(%r{^[^/]+$},'').sub(%r{/[^/]+$},'')}/#{new_name}"
    end
    dir   = path.sub(%r{/[^/]+$},'')
    mkdir_nested(dir) if file.include?("/") && mkdir == true
    return path
  end

  #Write updated file
  def self.update_file_object(obj, file, dir_in, dir_out)
    path = update_path(file, dir_in, dir_out)
    File.open(path, "wb") { |f| Marshal.dump(obj, f)}
  end
  
  def self.update_file_text(text, file, dir_in, dir_out, new_name = '')
    path = update_path(file, dir_in, dir_out, new_name)
    File.open(path, "w") { |f| f.write(text)}
  end
  
  #util
  def self.read_encoded_file(file, encoding) #not reliable in ruby
    text = ''
    File.open(file, "r") { |f| text = File.read(f) }
    #return text.force_encoding(encoding).encode("UTF-8") if encoding != ""
    s = text.dup
    begin
      s = text.dup.force_encoding("Windows-31J").encode!("UTF-8")
      encoding.replace("Windows-31J")
    rescue
      begin
        s = text.dup.force_encoding("SHIFT_JIS").encode!("UTF-8")
        encoding.replace("SHIFT_JIS")
      rescue
        s = text.dup
        encoding.replace("UTF-8")
      end
    end
    return s
  end

  #File Encoding
  def self.load_encodings
    s = "素材".encode('SHIFT_JIS') #load (dummy) encodings
    s = "素材".encode("Windows-31J")
  end

  def self.switch_ini_sub(ini1 = @game_ini_file, ini2 = @game_ini_file_sub)
    return unless File.exist?(ini1) || File.exist?(ini2)
    if File.exist?(ini1) && File.exist?(ini2)
      encoding1 = ""
      text1 = read_encoded_file(ini1, encoding1)
      encoding2 = ""
      text2 = read_encoded_file(ini2, encoding2)
    elsif File.exist?(ini1)
      encoding1 = ""
      text1 = read_encoded_file(ini1, encoding1)
      encoding2 = encoding1
      text2 = text1
    else
      encoding2 = ""
      text2 = read_encoded_file(ini2, encoding2)
      encoding1 = encoding2
      text1 = text2
    end
    File.open(ini1, "w:#{encoding2}") {|f| f.write(text2.encode(encoding2))}
    File.open(ini2, "w:#{encoding1}") {|f| f.write(text1.encode(encoding1))}
  end
  
  
  #ini
  def self.update_ini_file(ini = @game_ini_file)
    return unless File.exist?(ini)
    #translate options
    ini_tled = update_path(ini)
    
    if File.exist?(ini_tled)
      update_ini_options(ini, ini_tled)
    end
    #update scripts path
    scripts = get_option(@main_section, @scripts_option, @scripts_dflt, ini)
    scripts_tled = update_path(scripts)
    return unless File.exist?(scripts_tled)
    set_option(@main_section, @scripts_option, scripts_tled, ini)

  end



  def self.update_ini_options(ini1, ini2) #only works if similar
    encoding1 = ""
    lines1 = read_encoded_file(ini1, encoding1).split(/\n/)
    encoding2 = ""
    lines2 = read_encoded_file(ini2, encoding2).split(/\n/)
    section = ''
    lines1.each_with_index do |line1, index|
      break unless index <= lines2.length
      line2 = lines2[index]
      if line1 =~ /\A\[(.*)\]\z/
        next if line1 != line2
        section = $1
      elsif line1 != line2
        if line1 =~ /\A([^=]*)=(.*)\z/
          option1 = $1
          value1 = $2
        else next
        end
        if line2 =~ /\A([^=]*)=(.*)\z/
          option2 = $1
          value2 = $2
        else next
        end
        next if option1 != option2 || value1 == value2
        next if value1 != get_option(section, option1, '', ini1).force_encoding(encoding1).encode("UTF-8")
        next if value2 != get_option(section, option1, '', ini2).force_encoding(encoding2).encode("UTF-8")
        set_option(section, option1, value2, ini1)
      end #if
    end #each_with_index
  end #update_ini_options


  #--------------------------------------------------------------------------
  #                      Patch Hash <=> rvdata2 Object
  #--------------------------------------------------------------------------
 
  def self.marshal_load_data(filename)
    obj = nil
    stop = false
    n = 0
    while stop == false
      f = File.open(filename, "rb")
      begin
        obj = Marshal.load(f)
        return obj #Exit loop normal
      rescue ArgumentError => e
        f.close
        begin
          s = e.message
          raise 'e' unless s =~ %r{undefined class/module (.*)}
          mod = "Module"
          b = false
          a = $1.split('::',-1)
          a.each do |c|
            break if c == ""
            eval("b = #{mod}.const_defined?('#{c}')")
            eval("#{mod}.const_set('#{c}', Class.new {})") unless b
            mod = (mod == "Module") ? c : "#{mod}::#{c}"
          end
        rescue
        end
      end
      n += 1
      stop = true if n > 1000 #Exit loop infinite
    end
    return nil
  end
  
  #--------------------------------------------------------------------------
  # ●  Object: Patch <=> rvdata2
  #--------------------------------------------------------------------------
 
  def self.update_custom(obj, index_array, to_hash, var)
    # #Alias me to use custom methods
    # implemented:
    #   update_scripts : extract text from scripts
    #   update_list : concatenate text in list (RPG::EventCommand array)
    p_index_array = index_array.dup; latest = p_index_array.pop
    if latest.kind_of?(Numeric)
      return nil
    elsif latest == 'Scripts'
      return update_scripts(obj, to_hash, var)
    elsif latest == 'list'
      return update_list(obj, index_array, to_hash, var)
    end
    return nil
  end

  #-------------------------AVOID MODIFICATION-------------------------------
  
  def self.update_object(obj, index_array = [], to_hash, var)
    updated_custom = update_custom(obj, index_array, to_hash, var)
    if updated_custom == true then
      return true   #already updated
    elsif obj.kind_of?(Numeric) then
      return false  #not interested
    elsif obj.kind_of?(Array) then
      return update_array(obj, index_array, to_hash, var)
    elsif obj.kind_of?(String) then
      return update_string(obj, index_array, to_hash, var)
    elsif obj.kind_of?(Hash) then
      return update_hash(obj, index_array, to_hash, var)
    else #will be skipped if no instance variable
      return update_instance_variables(obj, index_array, to_hash, var)
    end
  end

  def self.update_instance_variables(obj, index_array, to_hash, var)
    updated = false
    obj.instance_variables.each do |i_var|
      val = obj.instance_variable_get(i_var)
      v = i_var.to_s.delete("@")
      #a = val.kind_of?(String) ? index_array.dup << v << '' : index_array.dup << v
      a = index_array.dup << v
      p_updated = update_object(val, a, to_hash, var)
      obj.instance_variable_set(i_var, val) if p_updated == true && to_hash == false
      updated ||= p_updated
    end
    return updated
  end
  
  def self.update_hash(hash, index_array, to_hash, var)
    updated = false
    hash.each do |key, value|
      p_updated = update_object(value, index_array.dup << key, to_hash, var)
      hash[key] = value if p_updated == true && to_hash == false
      updated ||= p_updated
    end
    return updated
  end
  
  def self.update_array(a, index_array, to_hash, var)
    updated = false
    a.each_with_index do |item, index|
      next unless item
      p_updated = update_object(item, index_array.dup << index, to_hash, var)
      updated ||= p_updated
    end
    return updated
  end
  
  def self.update_string(str, index_array, to_hash, var)
    return false if !index_array_ok?(index_array) || !text_ok?(str)
    p_str = encode_text(str)
    if to_hash == true
      var[p_str] = var[p_str] ? var[p_str] << index_array.dup : [index_array.dup]
      return true
    else
      if !var[0][index_array] then
        var[2][p_str] = var[2][p_str] ? var[2][p_str] << index_array : [index_array]
        return false     #doesn't exists
      else str.replace(decode_text(var[1][var[0][index_array]])) #translated (mutated)
      end
      return true
    end
  end

  #text encoding (avoids modification during marshal load/dump)
  def self.encode_text(text) #\r deleted (from notes...)
    #return "" if !text || text == ""
    Marshal.dump(text.gsub(/\r/, "").split("\n", -1).map{|s| [s].pack("m")})
  end

  def self.decode_text(text)
    return "" if !text || text == ""
    return Marshal.load(text).map{|s| s.unpack("m")}.join("\n").force_encoding("UTF-8")
  end
  
  #--------------------------------------------------------------------------
  # ●  list: Patch <=> rvdata2
  #--------------------------------------------------------------------------
  
  def self.do_with_list_item(obj, code, params, i_array, index, hash)
    # #Alias me to change how to act with list item (or edit me if you're lazy)
    # implemented for hash:
    #   first_line : nil, text doesn't start at code ; string, first line
    #   param_loop : nil, no loop ; next line(s) to be found in .parameters[param_loop] with code += 300
    #   index_array_method : method to use to return index array (implemented only for param_loop)
    #   text : text found
    #   new_obj : recur standard method with this new object (not considered as event command)
    #   param : text/new_obj found in .parameters[param]
    #   script : extract strings from text as script (implemented only for param_loop)
    if obj.class.name == @evc_class #is list element an event command?
      i_array.pop #removes 'list'
      if code == 101
        return false unless params[0]
        hash['index_array_method'] = :dialogue_index_array
        hash['param_loop'] = 0
        hash['first_line'] = nil
      elsif code == 102
        return false unless params[0]
        i_array.push(index, 'Choice')
        hash['param'] = 0
        hash['new_obj'] = params[0]
      elsif code == 105
        #return false unless params[0]
        i_array.push(index, 'ScrollText')
        hash['param_loop'] = 0
        hash['first_line'] = nil
      elsif code == 108
        return false unless params[0] && comment_108_ok?(params[0], i_array, hash)
        i_array.push(index, 'Comment')
        hash['param_loop'] = 0
        hash['param'] = 0
        hash['first_line'] = params[0]
      elsif code == 320
        return false unless params[0] && params[1]
        i_array.push(index, 'Rename', params[0])
        hash['param'] = 1
        hash['text'] = params[1]
      elsif code == 355
        return false unless params[0]
        i_array.push(index, 'InlineScript')
        hash['param_loop'] = 0
        hash['first_line'] = params[0]
        hash['script'] = true
      else
        return false #Change me to switch off code filter
        i_array.push(index, 'Code' , code)
        hash['new_obj'] = obj
      end
    else
      return false #Change me to allow non event commands
      i_array.push(index, item.class.name)
      hash['new_obj'] = obj
    end
    return true #Do something in convert_list
  end #do_with_list_item
  
  def self.dialogue_index_array(list, index, index_array, text)
    # #Alias me for more explicit dialogue context
    index_array.push(index, 'Dialogue')
    face = list[index].parameters[0].to_s
    index_array.push(face) if face != '' #Add Face Name
    return index_array
  end
  
  def self.comment_108_ok?(line, index_array, hash)
    # #Alias me to get some comments (ex: /<name_pop>.*/ )
    # Otherwise, comments shouldn't ever be used to store in game text
    return false
  end

  def self.update_command_300(obj, index, code, hash, to_hash, index_array, var)
    # #Alias me to make changes after knowing the whole text
    index0      = index
    next_code   = code + 300
    next_index  = index + 1
    param_loop  = hash['param_loop']
    #get text
    text        = hash['first_line']
    text = get_text_command_300(obj, index, next_code, text, param_loop, to_hash)
    #update index_array
    if hash['index_array_method']
      index_array = self.send(hash['index_array_method'], obj, index, index_array, text)
    end
    #update text
    text0 = text.dup
    return false if !text_ok?(text)
    if hash['script']
      updated = update_script(text, index_array, to_hash, var)
    #elsif code == 101 && text =~ @dialogue_style1_regex
      #updated = update_dialogue_style1_text(text, index_array, to_hash, var)
    else
      updated = update_command_300_text(text, index_array, to_hash, var)
    end
    return false if updated == false
    #update list
    if to_hash == false
      return false unless text && text != '' && text != text0
      translate_command_300(obj, index0, text0, text, hash, param_loop, next_code)
    end
    #return
    return updated
  end
  
  #-------------------------AVOID MODIFICATION-------------------------------

  def self.update_list(object, index_array, to_hash, var)
    return false if !object.kind_of?(Array) #is list an array?
    index = (to_hash == true) ? index = 0 : index = (object.length - 1)
    while index >= 0 && index <= (object.length - 1)
      item = object[index] #get item
      if item
        code    = item.instance_variable_get('@code')
        params  = item.instance_variable_get('@parameters')
        i_array = index_array.dup
        hash    = {} #additional parameters
        if do_with_list_item(item, code, params, i_array, index, hash) == true
          if hash['param_loop']
            update_command_300(object, index, code, hash, to_hash, i_array, var)
          elsif hash['text']
            p_obj = hash['text']
            updated = update_string(p_obj, i_array, to_hash, var)
          elsif hash['new_obj'] #other item or array
            p_obj = hash['new_obj']
            updated = update_object(p_obj, i_array, to_hash, var)
          end
        end
      end
      index = (to_hash == true) ? index + 1 : index - 1
    end #loop
    return true
  end #convert_list
  
  def self.update_command_300_text(text_decoded, index_array, to_hash, var)
    text = encode_text(text_decoded)
    #update hash
    if to_hash == true
      var[text] = var[text] ? var[text] << index_array : [index_array]
    else
      new_index_array = var[0][index_array]
      if !new_index_array then
        var[2][text] = var[2][text] ? var[2][text] << index_array : [index_array]
        text.replace("") #doesn't exists
      else text_decoded.replace(decode_text(var[1][new_index_array]))
      end
    end
    return true
  end
  
  def self.new_event_command(obj, index, code, index_ref) #util
    if index <= obj.length && obj[index] && obj[index].code == code
      return Marshal.load(Marshal.dump(obj[index])) #deep copy
    else
      return RPG::EventCommand.new(code, obj[index_ref].indent)
    end
  end
  
  def self.translate_command_300(obj, i0, jap, eng, h, param, next_code) #util
    j_lines = jap.split(/\n/, -1); e_lines = eng.split(/\n/, -1)
    min_j = [j_lines.length - 1, e_lines.length - 1].min
    max_j = [j_lines.length - 1, e_lines.length - 1].max
    j = 0
    if h['first_line'] then obj[i0].parameters[param] = e_lines[j]; j += 1 end
    i = i0 + 1
    d = nil
    param_loop = h['param_loop']
    while obj[i].code == next_code
      if j <= min_j #replace
        obj[i].parameters[param_loop] = e_lines[j]
      elsif max_j == j_lines.length - 1 #delete
        d = i unless d
        obj.delete_at(d) #delete at same index
        i -= 1
      else
        break #error?
      end
      i += 1
      j += 1
    end
    while j <= e_lines.length - 1 #add
      e = new_event_command(obj, i0 + 1, next_code, i0)
      e.parameters[param_loop] = e_lines[j]
      obj.insert(i, e.dup)
      j += 1
      i += 1
    end
  end
  
  def self.get_text_command_300(obj, index, next_code, text, param_loop, to_hash) #util
    next_index = index + 1
    while next_index < obj.length && obj[next_index].code == next_code
      next_item = obj[next_index]
      next_index += 1
      index += 1 if to_hash == true
      if text then text = "#{text}\n#{next_item.parameters[param_loop]}"
      else text = next_item.parameters[param_loop]
      end
    end
    return text
  end

  #--------------------------------------------------------------------------
  # ●  Script: Patch <=> rvdata2
  #--------------------------------------------------------------------------

  def self.do_with_script_match(raw_data, i, match)
    # #Alias me to select what to do with match data from script
    # implemented in update_script: 'nothing', 'replace'
    # user either raw_data, i, match if needed
    if !text_ok?(match) || match.start_with?('=begin') || match.start_with?('#')
      return 'nothing' #(comment)
    elsif match.start_with?('"') || match.start_with?("'") #|| match.start_with?('\\')
      return 'replace' #string but not regex
    end
    return 'nothing'
  end

  def self.script_index_array(script, index_array, raw_data, i, match)
    # #Alias me for clearer contexts
    # Change index_array[0] to change patch file name
    # No need for invert function
    # return nil to exclude
    left = script[1..raw_data[i][1][0]]
    line_number = left.lines.count
    line_position = (line_number == 1) ? raw_data[i][1][0] : left.reverse.index("\n")
    return index_array.dup << "#{line_number}:#{line_position}"
  end
  
  #-------------------------AVOID MODIFICATION-------------------------------

  #Update
  def self.update_scripts(object, to_hash, var) #util
    updated = false; unnamed_scripts = 'Unamed_Script_(0)'
    get_last_script(object) if to_hash == false && @add_plugins_after == ''
    next_add_plugins = nil
    index = to_hash == true ? 0 : object.length
    object.each_with_index do |item, index|
      name = get_script_name(item[1], unnamed_scripts)
      index_array = ['Scripts', name]
      script = inflate(item[2]).force_encoding("utf-8")
      if to_hash == false
        if name == @add_plugins_after && next_add_plugins.nil?
          next_add_plugins = true
        elsif next_add_plugins && next_add_plugins == true
          next_add_plugins = false
          p_updated = add_plugins(object, index)
          updated ||= p_updated
        end
      end
      if script != '' && !(name =~ /\AGaijinizer.+/)
        p_updated = update_script(script, index_array, to_hash, var)
        object[index][2] = deflate(script) if p_updated == true && to_hash == false
        updated ||= p_updated
      end
    end
    return updated
  end

  def self.get_last_script(object)
    #Before Main
    i = object.size
    while i >= 0
      break if object[i] && object[i][1] == "Main"
      i -= 1
    end
    i_main = i
    #After last blank if possible else not Scene_Gameover else Scene_Gameover
    unnamed_scripts = 'Unamed_Script_(0)'
    can_be_last_script = false
    object.each_with_index do |item, index|
      name = get_script_name(item[1], unnamed_scripts)
      can_be_last_script = true if name == "Scene_Gameover"
      can_be_last_script = false if index >= i_main
      @add_plugins_after = name if can_be_last_script == true
    end
  end
  
  def self.update_script(script, index_array, to_hash, var, 
    regex = @script_regex, 
    do_with_match = :do_with_script_match,
    new_indew_array = :script_index_array
  )
    updated = false
    raw_data = []; script.scan(regex) { |m| raw_data << [m, $~.offset(0)]}
    lines = script.lines
    i = (to_hash == true) ? 0 : raw_data.length
    while i >= 0 && i <= raw_data.length
      if raw_data[i]
        match = raw_data[i][0]
        s = self.send(do_with_match, raw_data, i, match)
        if s == 'nothing'
          #ignore
        elsif s == 'replace'
          a = self.send(new_indew_array, script, index_array, raw_data, i, match)
          if a
            p_match = encode_text(match)
            if to_hash == true
              var[p_match] = var[p_match] ? var[p_match] << a : [a]
            else
              if !var[0][a] then
                var[2][p_match] = var[2][p_match] ? var[2][p_match] << a : [a] 
                tled_match = nil #doesn't exists
              else tled_match = decode_text(var[1][var[0][a]]) #translated
              end
              script[raw_data[i][1][0]..(raw_data[i][1][1] - 1)] = tled_match if tled_match #mutating
            end
            updated = true
          end
        else
          #ignore
        end
      end
      i = (to_hash == true) ? i + 1 : i - 1
    end #while
    return updated
  end #update_script

  #Compression Util
  def self.inflate(string)
    zstream = Zlib::Inflate.new()
    text = zstream.inflate(string)
    zstream.finish
    zstream.close
    return text
  end

  def self.deflate(string, level = Zlib::BEST_COMPRESSION)
    z = Zlib::Deflate.new(level)
    data = z.deflate(string, Zlib::FINISH)
    z.close
    return data
  end
  
  #Other Util
  def self.get_script_name(script_name, unnamed) #util
    if script_name.to_s == ''
      new_name = unnamed.succ
      unnamed.replace(new_name)
    else new_name = script_name
    end
    return new_name.gsub(@context_join, @context_safe).gsub(/ /, @context_safe).gsub(/#/, "\\#")
  end
  
  def self.add_plugins(obj, index_before)
    updated = false
    return false if plugin_directory == ''
    a = []
    script_names = obj.map{ |item| item ? item[1] : ""}
    files = Dir.glob("#{plugin_directory}/*.*")
    files.each do |f|
      if f =~ %r{/([0-9]+)_([^/]+)(.rb|.txt)\z}
        script_pos  = $1.to_i
        script_name = $2
        script_text = ''
        File.open(f, 'r'){ |script| script_text = deflate(File.read(script))}
        script_index = nil
        if script_index = script_names.index(script_name) #no duplicates
          obj[script_index][1] = script_text
        else
          a << [script_pos, script_name, script_text]
        end
        updated = true
      end
    end
    return false if updated == false
    if a != []
      a.sort_by { |item| item[0] }
      a.reverse_each { |item| obj.insert(index_before, [12345678, item[1], item[2]]) }
    end
    return updated
  end
  
  #--------------------------------------------------------------------------
  #                      Patch Hash <=> txt File
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # ● Patch Hash <=> ini file
  #--------------------------------------------------------------------------
  
  def self.do_with_ini_match(raw_data, i, match)
    # #Alias me to select what to do with match data from ini (considered as script)
    # implemented in update_script: 'nothing', 'replace'
    # user either raw_data, i, match if needed
    if match.start_with?('[') 
      return 'nothing' # [Section]
    elsif j = match.include?('=')
      return 'replace' # Option=Value
    end
    return 'nothing'
  end

  def self.ini_index_array(text, index_array, raw_data, i, match)
    # #Alias me for clearer contexts
    # Current: File_nameEXTENSION/(Section)/Option
    # Change index_array[0] to change patch file name
    # No need for invert function
    # return nil to exclude
    j = match.index('=')
    option = match[0..(j - 1)].gsub(/\s+$/, '')
    match.replace(match[(j + 1)..-1])
    return nil if !text_ok?(match)
    raw_data[i][1][0] = raw_data[i][1][0] + j + 1
    #position.replace(position + j) #script[pos..raw_data[i][1][1]] = tled_match
    j = i - 1
    section = ""
    while j >= 0
      if (p_match = raw_data[j][0]) && p_match =~ /^\[.+\]$/
        section = p_match[1..-2]
        break
      end
      j -= 1
    end
    a = index_array[-1].split(".")
    section = '' if section == a[0]
    a = ["#{a[0].gsub(/ /, '_')}#{a[1].upcase}"] #File_name EXTENSION
    a << section if section != ''
    a << option ##GameINI/Title : File_name EXTENSION (Section) Option
    return a
  end
  
  #--------------------------------------------------------------------------
  # ● (Add more if needed)
  #--------------------------------------------------------------------------
  
  #--------------------------------------------------------------------------
  #                               Conversions
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # ● path <=> index_array
  #--------------------------------------------------------------------------
  
  def self.index_arrays_to_file(c, dir = '', extension = @patch_extension)
    # #Alias me to change how file path is determined
    # current: index_array[0] (custom)
    index_array = custom_index_array(c[0])
    if dir == '' then return "#{index_array[0]}#{extension}"
    else return "#{dir}/#{index_array[0]}#{extension}"
    end
  end
  
  #--------------------------------------------------------------------------
  # ● Text rvdata2 <=> Text patch
  #--------------------------------------------------------------------------
  
  #Text
  def self.custom_text(text)
    # #Alias me
    # > => \> no text line starts with '>' (or '> END STRING')
    # # => \# no text line includes comment
    # \ => \\ match RPGMTrans 4.5 syntax
    return text.to_s.gsub(/\\/,"\\\\\\").gsub(/#/,'\#').gsub(/>/,'\>').to_s
  end

  def self.original_text(text)
    #Alias me custom_text inverse function
    return text.to_s.gsub(/\\\\/,"\\").gsub(/\\#/,'#').gsub(/\\>/,'>').to_s
  end

  #Comment
  def self.comment(line, comment) #Alias me
    return line + '#' + comment
  end
  
  def self.uncomment(line) #Alias me
    #Alias me uncomment inverse function
    return line.match(/^(\\#|[^#])*/).to_s
  end

  #--------------------------------------------------------------------------
  # ● index_array <=> context
  #--------------------------------------------------------------------------
 
  def self.custom_index_array(index_array)
    # #Alias me for clearer contexts
    # Change index_array[0] to change patch file name
    a = index_array.dup
    begin
      if a[0] == 'CommonEvents'
        a[0] = "#{a[0]}_#{a[1]}" #join
        a.delete_at(1)
        return a
      end
    rescue
    end
    return index_array
  end
  
  def self.original_index_array(index_array)
    # #Alias me
    # original_index_array inverse function
    if index_array[0] =~ /\ACommonEvents_[0-9]+/
      index_array.insert(0, 'CommonEvents') #separate
      index_array[1] = index_array[1][('CommonEvents_'.size)..-1].to_i
      return index_array
    else
      return index_array
    end
  end
 
  #-------------------------AVOID MODIFICATION-------------------------------
  
  #index_array: String <=> Array
  def self.index_array_to_s(context_array = [@no_context])
    begin
      return context_array.join(@context_join)
    rescue
      return @no_context
    end
  end

  def self.index_array_from_s(context_string = @no_context)
    index_array = context_string.split(@context_join, -1)
    index_array.each_with_index do |e, i|
      index_array[i] = e.to_i if e.match(/\A[0-9]+\z/)
    end
  end
  
  #Custom String (Context) <=> Original Array (index_array)
  def self.context_from_a(index_array = [@no_context])
    return index_array_to_s(custom_index_array(index_array))
  end

  def self.index_array_from_context(context_string = @no_context)
    return original_index_array(index_array_from_s(context_string))
  end

  #--------------------------------------------------------------------------
  #                           Write / Read patch
  #--------------------------------------------------------------------------
  
  #--------------------------------------------------------------------------
  # ● Write patch (AVOID MODIFICATION)
  #--------------------------------------------------------------------------

  #write patch file string
  def self.write_string_untled(text_encoded, c = [[]], tag = @untled_tag)
    s = ''
    text = decode_text(text_encoded)
    c.each do |index_array|
      context = context_from_a(index_array)
      next if !context_ok?(context)
      s << "#{@rmgmt_c}#{context}#{tag}\n"
    end
    return "#{@rmgmt_bs}\n#{custom_text(text)}\n#{s}\n#{@rmgmt_es}\n" if s != ''
    return nil
  end
  
  def self.write_string_tled(text_encoded, tl)
    s = ""
    text = decode_text(text_encoded)
    tl.each do |tl_text_encoded, c|
      s_tl = ""
      tl_text = decode_text(tl_text_encoded)
      if tl_text == text || tl_text == "" #tl_text never is "" if from tl_data
        c.each do |index_array|
          context = context_from_a(index_array)
          next if !context_ok?(context)
          s_tl << "#{@rmgmt_c}#{context}#{@untled_tag}\n"
        end
        s_tl << "\n" unless s_tl == ""
      else
        c.each do |index_array|
          context = context_from_a(index_array)
          next if !context_ok?(context)
          s_tl << "#{@rmgmt_c}#{context}\n"
        end
        s_tl << "#{custom_text(tl_text)}\n" unless s_tl == ""
      end
      s << s_tl unless s_tl == ""
    end
    return "#{@rmgmt_bs}\n#{custom_text(text)}\n#{s}#{@rmgmt_es}\n" unless s == ""
    return nil
  end
  
  #write patch files
  def self.get_new_patch(data_hash, dir, extension, files_text_cache)
    if !File.exist?(files_text_cache) || IGNORE_CACHE
      files_text = {}
      data_hash.each_pair do |key, value|
        path = index_arrays_to_file(value, dir, extension)
        text = write_string_untled(key, value)
        files_text[path] = "#{files_text[path]}\n#{text}" if text
      end
      File.open(files_text_cache, "wb") { |f| Marshal.dump(files_text, f)}
    else
      File.open(files_text_cache, "rb") { |f| files_text = Marshal.load(f) }
    end
    return files_text
  end

  def self.get_updated_patch(data, tl_data, c_ref_to_c, dir, extension, files_text_cache)
    if !File.exist?(files_text_cache) || IGNORE_CACHE
      files_text = {}
      index_array_tl = nil
      data.each do |text, c|
        tl = {}
        c.each do |index_array|
          text_tl = ""
          text_tl = tl_data[1][index_array_tl] if index_array_tl = c_ref_to_c[index_array]
          tl[text_tl] = tl[text_tl] ? tl[text_tl] << index_array : [index_array]
        end
        path = index_arrays_to_file(c, dir, extension)
        text = write_string_tled(text, tl)
        files_text[path] = "#{files_text[path]}\n#{text}" if text
      end
      File.open(files_text_cache, "wb") { |f| Marshal.dump(files_text, f)}
    else
      File.open(files_text_cache, "rb") { |f| files_text = Marshal.load(f) }
    end
    return files_text
  end
  
  def self.write_patch_in_dir(data_hash, dir,
    extension = @patch_extension, 
    header = @file_header,
    append = false,
    files_text_cache = "#{@patcher_cache}/files_text"
  )
    files_text = get_new_patch(data_hash, dir, extension, files_text_cache)
    files_text.each_pair  do |key, value|
      begin
        if File.exist?(key) && append == true
          File.open(key, 'a') { |f| f.puts(value.to_s) }
        else
          File.open(key, 'w') { |f| f.write(header + value.to_s) }
        end
      rescue
        next
      end
    end
  end

  def self.write_updated_patch_in_dir(data, tl_data, c_ref_to_c, var, 
    dir = patch_update_directory,
    extension = @patch_extension, 
    header = @file_header
  )
    up_files_text_cache = "#{@patcher_cache}/up_files_text"
    up_files_text = get_updated_patch(data, tl_data, c_ref_to_c,
     dir, extension, up_files_text_cache
    )
    up_files_text.each_pair  do |key, value|
      File.open(key, 'w') { |f| f.write(header + value.to_s) }
    end
  end

  def self.write_updated_translation(data, tl_data, c_ref_to_c, var)
    write_updated_patch_in_dir(data, tl_data, c_ref_to_c, var) if translation_update_mode == 0
    write_translation_log(tl_data, var)
  end
  

  def self.write_translation_log(tl_data, var)
    text = ""
    
    new_text = ""
    var["added_s"].each do |key, value|
      s = write_string_untled(key, value)
      new_text << "#{s}\n" if s && s != ""
    end
    text << "\n#Added content:\n\n#{new_text}" if new_text != ""
    
    new_text = ""
    var["similar_c"].each do |index_array1, index_array2|
      new_text << "#{@rmgmt_c}(new)#{context_from_a(index_array1)}\n" +
       "#{context_from_a(index_array2)}(reference)\n" +
       "#{decode_text(tl_data[1][index_array2])}\n"
    end
    text << "\n#Suggested translation:\n\n#{new_text}" if new_text != ""
    
    new_text = ""
    var["unmatched_c"].each do |index_array|
      new_text << "#{context_from_a(index_array)}\n"
    end
    text << "\n#Unmatched context:\n\n#{new_text}" if new_text != ""
    
    new_text = ""
    var["filtered_c"].each do |index_array|
      new_text << "#{context_from_a(index_array)}\n"
    end
    text << "\n#Filtered context:\n\n#{new_text}" if new_text != ""

    new_text = ""
    var["lost_tl_c"].each do |c|
      s = ""
      c.each do |index_array|
        s << "#{@rmgmt_c}#{context_from_a(index_array)}\n"
      end
      new_text << "#{s}#{decode_text(tl_data[1][c[0]])}\n"
    end
    text << "\n#Removed translation:\n\n#{new_text}" if new_text != ""
  
    header = "#=====update_translation_log=======\n" +
     "#Change auto_update_mode to 0 to automatically add (with exceptions) " +
      "suggested translations, current: #{auto_update_mode}\n" +
     "#Change translation_update_mode to 0 to update the #{language} patch in" +
     " #{patch_update_directory} directory (comments will get deleted), current:" +
     "#{translation_update_mode}\n"
     
    if text == ""
      text = "#{header}--Nothing to update--\n"
    else
      text = "#{header}#{text}"
    end
    log_this(text)
  end
  
  #--------------------------------------------------------------------------
  # ● Read Patch Translation (AVOID MODIFICATION)
  #--------------------------------------------------------------------------

  #Files
  def self.get_translation_from_dir(dir = '', extension = @patch_extension, header = @file_header, lang = language)
    tl_data_cache = "#{@patcher_cache}/tl_data"
    tl_data = [{},{}] #j->i, i_patch->e (i_ref -> i_patch)
    if !File.exist?(tl_data_cache) || IGNORE_CACHE
      pattern = (dir == '') ? "*#{extension}" : "#{dir}/*#{extension}"
      files = Dir.glob(pattern)
      files.each do |f|
        next unless IO.read(f, header.size, 3) == header
        lines = File.read(f, mode: 'rb', encoding: 'UTF-8').gsub("\r\n", "\n").lines
        get_translation_from_lines(lines, tl_data, lang)
      end
      File.open(tl_data_cache, 'wb') { |f| Marshal.dump(tl_data, f)}
      return tl_data
    else
      File.open(tl_data_cache, 'rb') { |f| tl_data = Marshal.load(f)}
      return tl_data
    end
  end
  
  #Lines
  def self.get_translation_from_lines(lines, tl_data, lang)
    # steps:
    # Any (begin string)      -> 1, reinitialize
    # 1   (else)              -> 2, s first line
    # 2   (else)              -> 2, s new line
    # 2+  (incorrect lang)    -> 3, add tl*
    # 2+  (correct lang)      -> 4, add tl*
    # 2   (context, dflt lang)-> 5, add context
    # 4   (context)           -> 5, add context, add tl*
    # 5   (else)              -> 6, s_tl first line
    # 6   (else)              -> 6, s_tl new line
    # Any (end string)        -> 0, add tl*
    
    step = 0; s = ''; s_tl = ''; c_s = []; c_tl = []
    #file_lines = file_text.split("\r\n", -1)
    lines.each do |p_line|
      line = p_line.chomp
      if line.start_with?(@rmgmt_bs)
        s = ''; s_tl = ''; c_s = []; c_tl = []
        step = 1
      elsif line.start_with?(@lang_tag) && step > 1
        line = line_to_context(line, @lang_tag)
        add_translation(s, c_s, c_tl, s_tl, tl_data) if step > 6
        if line == lang then step = 4 else step = 3 end  
      elsif step != 0 && line.start_with?(@rmgmt_c)
        step = 4 if step == 2 && lang == @dflt_tled_lang
        if step > 3 #ignore if incorrect language
          add_translation(s, c_s, c_tl, s_tl, tl_data) if step > 5
          index_array = index_array_from_context(line_to_context(line, @rmgmt_c))
          c_s << index_array; c_tl << index_array
          step = 5
        end
      elsif line.start_with?(@rmgmt_es)
        add_translation(s, c_s, c_tl, s_tl, tl_data)
        step = 0 #reinitialize
      elsif step != 0
        if step != 3 #not incorrect language
          line = uncomment(line)
          if    step == 5 then s_tl = line; step = 6
          elsif step == 6 then s_tl << "\n#{line}"
          elsif step == 1 then s = line; step = 2
          elsif step == 2 then s << "\n#{line}"
          end
        end
      end
    end #line
    return tl_data
  end
  
  #Util
  def self.line_to_context(line, tag = '', no_comment = true) #remove tag & comment
    p_line = line[tag.size..-1]
    p_line = uncomment(p_line) if no_comment == true
    return p_line.match(/\A[^ ]*/).to_s
  end

  def self.add_translation(text, c_text, c_translation, translation, tl_data) #util
    return if c_text == []
    if translation != ''
      text = encode_text(original_text(text))
      tl_data[0][text] = c_text #update
      translation = encode_text(original_text(translation))
      c_translation.each { |index_array| tl_data[1][index_array] = translation.dup}
    end
    translation.replace('')
    c_translation = []
  end
  
  #--------------------------------------------------------------------------
  # ● Read Patch Comments (PLACEHOLDER)
  #--------------------------------------------------------------------------

  #Files
  def self.get_comments_from_dir(dir = '', extension = @patch_extension, header = @file_header)
    #PLACEHOLDER
  end
  
  #Lines
  def self.get_comments_from_lines(lines, comments_data)
    #PLACEHOLDER
    #0: jap -> jap commented
    #1: index_array -> { language => eng commented}
  end
  
  def self.add_comments(text, c_text, c_translation, translation, language, comments_data) #util
    #PLACEHOLDER
  end
  
  #--------------------------------------------------------------------------
  # ● Update Translation
  #--------------------------------------------------------------------------

  def self.index_arrays_similarity(index_array1, index_array2)
    # #Alias me to change criteria for most similar index_array
    # score : 0 -> 100 (most similar); most similars will share their TL
    # Definively change me if you just changed the index_array syntax mid-translation
    score = 0.0
    b = true
    if index_array1 == index_array2
      return 100
    elsif (index_array1.length != index_array2.length)
      return 0
    else
      index_array1.each_with_index do |e, i|
        if e.kind_of?(String)
          if e.to_s == index_array2[i].to_s
            score = score + (50.0 / (i + 1))
          else
            b = false
          end
        elsif e.kind_of?(Numeric)
          if b == true && e.to_s == index_array2[i].to_s
            score = score + (50.0 / (i + 1))
          elsif index_array2[i].kind_of?(Numeric)
            b = false
            score = score + ((50.0 - [50,(e - index_array2[i]).abs].min)/ (i + 1))
          else
            b = false
          end
        end
      end
      return score
    end
  end

  def self.find_similar_tl(c_no_tl, c_with_tl, c_ref_to_c, var, min_score = 0)
    # #Alias me to change how to give a tl to similars index_array
    # current: all index_arrays are given a tl (min score = 0)
    #return if auto_update_mode == 2
    c_no_tl.each do |index_array_no_tl|
      score_max = -1
      best_match = nil
      c_with_tl.each do |index_array_with_tl|
        score = index_arrays_similarity(index_array_no_tl, index_array_with_tl)
        if score > score_max
          best_match = index_array_with_tl
          score_max = score
        end
      end
      if score_max >= min_score
        if !auto_update_mode_1?(index_array_no_tl)
          c_ref_to_c[index_array_no_tl] = best_match #index_array_with_tl
        end
        var["similar_c"][index_array_no_tl] = best_match
      else
        var["unmatched_c"] << index_array_no_tl
      end
    end
  end
  
  #-------------------------AVOID MODIFICATION-------------------------------

  def self.get_changes(data_ref, tl_data,
    c_ref_to_c  = {},
    var   = {}
  )
    # ┌─────────────┐              ┌ - - - - - - ┐
    # │ tl_data[0]  │-(text diff)->
    # ├ - - - - - - ┤              │   lost_c    │
    # │ same text   │-(tl unused)->
    # │index_array  │              ├─────────────┤
    # │ ├ same      │<-------------│             │
    # │ │           │  c_ref_to_c  │  data_ref   │ tl_data_updated
    # │ └ similar   │<-------------│             │  = {index_array_ref => tl}
    # └─────────────┘              ├ - - - - - - ┤
    #                              │ {tl needed} │ *obtained later during patching
    #                              └─────────────┘
    
    update_log_cache      = "#{@patcher_cache}/update_log"
    c_ref_to_c_cache      = "#{@patcher_cache}/c_ref_to_c"
    if (!File.exist?(update_log_cache)       || 
        !File.exist?(c_ref_to_c_cache)      || 
        IGNORE_CACHE
    )
      #data_ref.each do |text, c|
      #  if !tl_data[0][text] && !tl_data[0][text.gsub(/\r\n/, "\n")])
      #    msgbox(c)
      #  end
      #end
      
      var["lost_tl_c"]    = [] # translation lost (no matching text/context)
      var["filtered_c"]   = [] # conltext skipped due to filter
      var["unmatched_c"]  = [] # context lost (no similar c)
      var["similar_c"]    = {} # context lost but => similar context found
      var["text"]         = {} # context => text
      
      tl_data[0].each do |text, c|
        if (c_ref = data_ref[text]) #|| (c_ref = data_ref[text.gsub(/\n/, "\r\n")])
          get_changes_for_text(text, c, c_ref, c_ref_to_c, tl_data, var)
        else
          var["lost_tl_c"] << c
        end
      end
      File.open(update_log_cache, "wb") { |f| Marshal.dump(var, f)}
      File.open(c_ref_to_c_cache, "wb") { |f| Marshal.dump(c_ref_to_c, f)}
      var.merge!({})
      c_ref_to_c.merge!({})
      return
    else #if
      File.open(update_log_cache, "rb") { |f| var.merge!(Marshal.load(f))}
      File.open(c_ref_to_c_cache, "rb") { |f| c_ref_to_c.merge!(Marshal.load(f))}
      return
    end #if
  end #get_changes

  def self.get_changes_for_text(text, c, c_ref, c_ref_to_c,
    tl_data,
    var = {}
  )
    new_c_ref = []
    c_left = []
    
    #exact or different index_array
    c_ref.reverse_each do |index_array|
      var["text"][index_array] = text
      if !context_ok?(context_from_a(index_array))
        var["filtered_c"] << index_array if c.include?(index_array)
        next
      end
      if c.include?(index_array)
        c_ref_to_c[index_array] = index_array #exact
      else
        if auto_update_mode != 2
          c_left << index_array #find similar
        else
          var["unmatched_c"] << index_array
        end
      end
    end
    #find similar and update
    if c_left != [] #&& auto_update_tl == true
      find_similar_tl(c_left, c, c_ref_to_c, var)
    end
    find_unused_tl(c, c_ref, c_ref_to_c, tl_data, var)
  end
  
  def self.find_unused_tl(c, c_ref, c_ref_to_c, tl_data, var)
    tl = {}; new_tl = {} # 2 hash containing available translations
    c.each {|i_a| tl[tl_data[1][i_a]] = true} #fill 1 with all
    c_ref.each {|i_a| new_tl[tl_data[1][c_ref_to_c[i_a]]] = true} #2, only ref
    c.each {|i_a| var["lost_tl_c"] << [i_a] if !new_tl.include?(tl_data[1][i_a])}
  end

  def self.auto_update_mode_1?(index_array)
    return true if auto_update_mode == 1
    return true if index_array.include?("Scripts")
    return true if index_array.include?("InlineScript")
    return false
  end

  #--------------------------------------------------------------------------
  #                                  Misc
  #--------------------------------------------------------------------------
  
  #--------------------------------------------------------------------------
  # ● Ini (AVOID MODIFICATION)
  #--------------------------------------------------------------------------

  #Win32API
  GetPrivateProfileString     = Win32API.new('kernel32', 'GetPrivateProfileString'  , 'ppppip', 'i')
  WritePrivateProfileString   = Win32API.new('kernel32', 'WritePrivateProfileString', 'pppp'  , 'i')

  def self.get_option(section, key, default_value, ini = INI_FILE) #util
    ini = "./#{ini}" unless ini.include?("/")
    buffer = [].pack('x256')
    l = GetPrivateProfileString.call(section, key, default_value, buffer, buffer.size, ini)
    return buffer[0, l]
  end

  def self.set_option(section, key, value, ini = INI_FILE) #util
    ini = "./#{ini}" unless ini.include?("/")
    File.open(INI_FILE, 'w') unless File.exist?(ini)
    WritePrivateProfileString.call(section, key, value.to_s, ini)
  end

  def self.ruby_file_eval
    if !@ruby_file_eval
      @ruby_file_eval = get_option(SECTION, EVAL_PATH, "Gaijinizer/Eval/Gaijinizer.rb")
    end
    return @ruby_file_eval
  end
  
  def self.language(value = nil)
    if value
      @language = value
      set_option(SECTION, LANG, value)
    elsif !@language
      @language = get_option(SECTION, LANG, @dflt_tled_lang)
    end
    return @language
  end

  def self.patch_new_directory
    if !@patch_new_directory
      @patch_new_directory = get_option(SECTION, PATCH_NEW, "Gaijinizer/New_Patch")
      mkdir_nested(@patch_new_directory) unless File.directory?(@patch_new_directory)
    end
    return @patch_new_directory
  end
  
  def self.patch_tl_directory
    if !@patch_tl_directory
      @patch_tl_directory = get_option(SECTION, PATCH_TL, "Gaijinizer/Patch")
    end
    return @patch_tl_directory
  end
  
  def self.plugin_directory
    if !@plugin_directory
      @plugin_directory = get_option(SECTION, PLUGIN, 'Gaijinizer/Plugins')
      mkdir_nested(@plugin_directory) unless File.directory?(@plugin_directory)
    end
    return @plugin_directory
  end

  def self.patch_format(value = nil)
    if value
      @patch_format = value
      set_option(SECTION, FORMAT, value)
    elsif !@patch_format
      @patch_format = get_option(SECTION, FORMAT, "default")
    end
    return @patch_format
  end
  
  def self.on_start(value = nil)
    if value
      @on_start = value
      set_option(SECTION, START, value)
    elsif !@patch_format
      @on_start = get_option(SECTION, START, "show_ui")
    end
    return @on_start
  end
  
  def self.auto_update_mode(value = nil)
    if value
      @auto_update_mode = value
      set_option(SECTION, UP_MODE, value)
    elsif !@update_mode
      @auto_update_mode = get_option(SECTION, UP_MODE, "0").to_i
    end
    return @auto_update_mode
  end
  
  def self.translation_update_mode(value = nil)
    if value
      @translation_update_mode = value
      set_option(SECTION, TL_UP_MODE, value)
    elsif !@translation_update_mode
      @translation_update_mode = get_option(SECTION, TL_UP_MODE, "0").to_i
    end
    return @translation_update_mode
  end
  
  #Folder to translate
  def self.patch_in_directory
    if !@patch_in_directory
      @patch_in_directory = get_option(SECTION, PATCH_IN, "")
    end
    return @patch_in_directory
  end

  
  def self.patch_out_directory
    if !@patch_out_directory
      @patch_out_directory = get_option(SECTION, PATCH_OUT, "Gaijinizer/Game_#{language}")
      mkdir_nested(@patch_out_directory) unless File.directory?(@patch_out_directory)
    end
    return @patch_out_directory
  end
  
  def self.patch_update_directory
    if !@patch_update_directory
      @patch_update_directory = get_option(SECTION, PATCH_UP, "Gaijinizer/Patch_#{language}_updated")
      mkdir_nested(@patch_update_directory) unless File.directory?(@patch_update_directory)
    end
    return @patch_update_directory
  end
  
  #Pictures
  def self.pictures_in_directory
    if !@pictures_in_directory
      @pictures_in_directory = get_option(SECTION, PIC_IN, "")
    end
    return @pictures_in_directory
  end

  
  def self.pictures_out_directory
    if !@pictures_out_directory
      @pictures_out_directory = get_option(SECTION, PIC_OUT, "Gaijinizer/Pictures_#{language}")
      mkdir_nested(@pictures_out_directory) unless File.directory?(@pictures_out_directory)
    end
    return @pictures_out_directory
  end

 #--------------------------------------------------------------------------
 # ● Files (AVOID MODIFICATION)
 #--------------------------------------------------------------------------
 
  def self.mkdir_nested(dir)
    path = nil
    dir.split("/").each do |folder|
      path = path ? "#{path}/#{folder}" : folder
      Dir.mkdir(path) unless File.directory?(path)
    end
  end

  def self.remove_dir(path)
    if File.directory?(path)
      Dir.foreach(path) do |f|
        if f.to_s != "." && f.to_s != ".."
          remove_dir("#{path}/#{f}")
        end
      end
      Dir.delete(path)
    else
      File.delete(path)
    end
  end

  def self.clean_cache
		remove_dir(@patcher_cache)
		mkdir_nested(@patcher_cache)
  end
  
 #--------------------------------------------------------------------------
 # ● Filters (AVOID MODIFICATION)
 #--------------------------------------------------------------------------

  #Context Array (Filter as much as possible here if possible)
  def self.index_array_ok?(index_array)
    @context_exclude.each {|item| return false if index_array.include?(item)}
    return true if @context_include == []
    b = false
    @context_include.each {|item| b = true if index_array.include?(item)}
    return b
  end

  #Jap text (Exclude non Japanese text)
  def self.text_ok?(text)
    return false if text.to_s == ''
    return true if @text_include == []
    @text_include.each do |text_include|
      return true if text =~ text_include
    end
    return false
  end

  #Written context (Filter rest)
  def self.context_ok?(context_text)
    return false if context_text.to_s == ''
    @context_text_exclude.each do |context_excluded|
      return false if context_text =~ context_excluded
    end
    return true
  end

  #--------------------------------------------------------------------------
  # ● Dynamic replace files
  #--------------------------------------------------------------------------
  
  def self.load_data(filename)
    if language != @dflt_lang
      new_filename = update_path(filename, patch_in_directory, patch_out_directory, "", false)
      if File.exist?(new_filename)
        obj = nil
        File.open(new_filename, "rb") { |f| obj = Marshal.load(f)}
        return obj
      else
        raise 'Could not load TLed data.'
      end
    else
      raise 'Already playing correct version.'
    end
  end
  
  def self.bitmap_filename(filename)
    new_filename = update_path(filename, pictures_in_directory, pictures_out_directory, "", false)
    if !Dir.glob("#{new_filename}.*").empty?
      return new_filename
    else
      return filename
    end
  end
  
  #--------------------------------------------------------------------------
  # ● Compatibility
  #--------------------------------------------------------------------------

  def self.script_version #Check me and #Alias me if needed
    SCRIPT_VERSION
  end
  
  def self.patch_version #Check me and #Alias me if needed
    PATCH_VERSION
  end

  #-------------------------AVOID MODIFICATION-------------------------------
  
  load_encodings
  
  #Add/Alias module methods (should be last before end #Gaijinizer::Patchmaker)
  begin
    if File.exist?(ruby_file_eval)
      f = File.open(ruby_file_eval, "r")
      eval(f.read)
      f.close
    end
  rescue
    msgbox("Could not interpret ruby file #{ruby_file_eval}")
  end
  
  initialize_log

  clean_cache if @reset_cache
  
  main

end #Gaijinizer::Patchmaker

#--------------------------------------------------------------------------
# ● Dynamic file replace (AVOID MODIFICATION)
#--------------------------------------------------------------------------

#Load Data Alias
if Gaijinizer::Patchmaker::LOAD_DATA_ALT
  alias :lvl1_load_data :load_data
  def load_data(filename)
    begin
      return Gaijinizer::Patchmaker.load_data(filename)
    rescue
      return lvl1_load_data(filename)
    end
  end
end


#Bitmap.new Alias
class Bitmap
  alias :lvl1_initialize :initialize
  def initialize(*args)
    if args[1] == nil && args[0]
      lvl1_initialize(Gaijinizer::Patchmaker.bitmap_filename(args[0]))
    else
      lvl1_initialize(*args)
    end
  end
end

#--------------------------------------------------------------------------
# ● UI (AVOID MODIFICATION)
#--------------------------------------------------------------------------

if Gaijinizer::Patchmaker::show_ui? == true
  Scene_Title = Scene_Gaijinizer if Scene_Gaijinizer
end