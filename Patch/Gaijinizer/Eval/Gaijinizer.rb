@new_patch_version = "1" #NEW

msgbox("Warning, Gaijinizer ver #{script_version} might not be compatible with the patch (Recommended: 0.2.*).\nPlease check and edit #{ruby_file_eval}.") unless script_version =~ /0\.2\..*/

script_regex  = %r{
	(?:(?<!.)=begin(?:[\s]|\n)+(?:|.|\n)*(?:\n=end(?:[\s]|\n))| #=begin comment =end
	(?<!\$)"(?!\$)(?:"|(?:\#{.*}|\\"|\\\\|[^"])*")| # "string"
	(?<!\$)'(?!\$)(?:'|(?:\\'|\\\\|[^'])*')| # 'string'
	(?:(?<=[,:;/\[(!=+\-])\s*|(?<=\n)|^)/(?:\#{.*}|\\/|\\\\|[^/])*/[a-zA-Z]*| # [space]/regex/modifier
	(?<!\\)\#[^\n]*) # #comment
}x

def self.check_patch_version #NEW
	version_option = "patch_version"
	previous_version = get_option(SECTION, version_option, patch_version)
	if previous_version != @new_patch_version
		#cache
		remove_dir(@patcher_cache)
		mkdir_nested(@patcher_cache)
		#patch out
		remove_dir(patch_out_directory)
		@patch_out_directory = nil
	end
	set_option(SECTION, version_option, @new_patch_version)
end

check_patch_version #NEW

def self.patch_version #MODIFIED
	@new_patch_version
end

@comment_namepop_ok = /<namepop .*>/ #NEW
@comment_namepop_regex = /<namepop (.*)>/ #NEW
@comment_choice_help_ok = /選択肢ヘルプ.*/ #NEW
@comment_choice_help_regex = /選択肢ヘルプ\n(.*)/ #NEW

def self.comment_108_ok?(line, index_array, hash) #MODIFIED
	# #Alias me to get some comments (ex: /<name_pop>.*/ )
	# Otherwise, comments shouldn't ever be used to store in game text
	#============================================================================  BEGIN MODIFIED
	return true if line =~ @comment_namepop_ok || line =~ @comment_choice_help_ok
	#============================================================================  END MODIFIED
	return false
end

def self.update_command_300(obj, index, code, hash, to_hash, index_array, var) #MODIFIED
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
    #============================================================================BEGIN MODIFIED
    elsif code == 108 && text =~ @comment_namepop_regex
      updated = update_comment_namepop_text(text, index_array, to_hash, var)
    elsif code == 108 && text =~ @comment_choice_help_regex
      updated = update_comment_choice_help_text(text, index_array, to_hash, var)
    #============================================================================END MODIFIED
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

def self.update_comment_namepop_text(text_decoded, index_array, to_hash, var) #NEW
	#modified update_command_300_text
	return false unless text_decoded =~ @comment_namepop_regex #/<name_pop (.*)>/
	#speaker
	text_name = encode_text(text_decoded)
	index_array_name = index_array.dup
	index_array_name[-1] = "NamePop"
	#update hash
	if to_hash == true
	  var[text_name] = var[text_name] ? var[text_name] << index_array_name : [index_array_name]
	else
	  #originals
	  text_name0 = text_name
	  #speaker
	  new_index_array = var[0][index_array_name]
	  if !new_index_array then
      var[2][text_name0] = var[2][text_name0] ? var[2][text_name0] << index_array_name : [index_array_name]
      return false
	  else text_name = decode_text(var[1][new_index_array])
	  end
	  #replace text
	  text_decoded.replace("<namepop #{text_name}>")
	end
	return true
end

def self.update_comment_choice_help_text(text_decoded, index_array, to_hash, var) #NEW
	#modified update_command_300_text
	return false unless text_decoded =~ @comment_choice_help_regex #/選択肢ヘルプ\n(.*)/
	#speaker
	text_help = encode_text(text_decoded)
	index_array_help = index_array.dup
	index_array_help[-1] = "ChoiceHelp"
	#update hash
	if to_hash == true
	  var[text_help] = var[text_help] ? var[text_help] << index_array_help : [index_array_help]
	else
	  #originals
	  text_help0 = text_help
	  #speaker
	  new_index_array = var[0][index_array_help]
	  if !new_index_array then
      var[2][text_help0] = var[2][text_help0] ? var[2][text_help0] << index_array_help : [index_array_help]
      return false
	  else text_help = decode_text(var[1][new_index_array])
	  end
	  #replace text
	  text_decoded.replace("選択肢ヘルプ\n#{text_help}")
	end
	return true
end

def self.update_custom(obj, index_array, to_hash, var) #MODIFIED
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
	#============================================================================  BEGIN MODIFIED
	elsif latest == 'note'
	  return update_note(obj, index_array, to_hash, var)
	#============================================================================  END MODIFIED
	end
	return nil
end
  
#--------------------------------------------------------------------------
# ● update_note (NEW)
#--------------------------------------------------------------------------

@book_attribute_start   = "<図鑑特徴:"
@book_description_start = "<図鑑説明:"
@book_attribute_regex   = /(?:#{@book_attribute_start})(.*)(?:>)/
@book_description_regex = /(?:#{@book_description_start})((?:>\r\n#{@book_description_start}|.)*)(?:>)/
@note_regex = /(?:(?:<図鑑特徴:)(?:.*)(?:>)|(?:<図鑑説明:)(?:(?:>\r\n<図鑑説明:|.)*)(?:>))/

def self.update_note(note, index_array, to_hash, var, regex = @note_regex) 
	#do_with_match = :do_with_script_match,
	#new_indew_array = :script_index_array
	updated = false
  return false if note == ""
	raw_data = []; note.scan(regex) { |m| raw_data << [m, $~.offset(0)]}
	lines = note.lines
	i = (to_hash == true) ? 0 : raw_data.length
	while i >= 0 && i <= raw_data.length
	  if raw_data[i]
		match = raw_data[i][0]
		a = note_index_array(note, index_array, raw_data, i, match)
		text = encode_text(match)
		if to_hash == true
		  var[text] = var[text] ? var[text] << a : [a]
		else
		  if !var[0][a] then
        var[2][text] = var[2][text] ? var[2][text] << a : [a] 
        tled_text = nil #doesn't exists
		  else
        tled_text = decode_text(var[1][var[0][a]]) #translated
			if a[-2] == "BookAttribute"
			  tled_text = "#{@book_attribute_start}#{tled_text}>"
			else#if a[-1] == "BookDescription"
			  tled_text = "#{@book_description_start}#{tled_text.gsub(/\n/, ">\r\n#{@book_description_start}")}>"
			end
		  end
		  note[raw_data[i][1][0]..(raw_data[i][1][1] - 1)] = tled_text if tled_text #mutating
		end
		updated = true
	  end
	  i = (to_hash == true) ? i + 1 : i - 1
	end #while
	return updated
end #update_note

  
def self.note_index_array(note, index_array, raw_data, i, match)
	# ***_index_array
  a = index_array.dup
  left = note[1..raw_data[i][1][0]]
  line_number = left.lines.count
	if match =~ @book_attribute_regex #(?:<図鑑特徴:)(.*)(?:>)
	  match.replace($1)
    a[-1] = "BookAttribute"
	  return a << line_number
	elsif match =~ @book_description_regex #(?:<図鑑説明:)((?:<図鑑説明:|>\r\n<図鑑説明:|[^\n])*)(?:>)
	  match.replace($1.gsub(/>\r\n#{@book_description_start}/,"\n"))
    a[-1] = "BookDescription"
	  return a << line_number
	end
end