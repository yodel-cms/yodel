class Attachment
  attr_accessor :field, :record, :name, :mime
  
  def initialize(value, record, field)
    @field = field
    @record = record
    value ||= {}
    @name = value['name']
    @mime = value['mime']
  end
  
  def to_hash
    {'name' => name, 'mime' => mime}
  end
    
  def url
    @url ||= Pathname.new('/').join(Yodel::ATTACHMENTS_DIRECTORY_NAME, relative_path)
  end
  
  def relative_path
    @relative_path ||= File.join(relative_directory_path, @name)
  end
  
  def relative_directory_path
    @relative_directory_path ||= File.join(@field.name, @record.id.to_s)
  end
  
  def path
    @path ||= File.join(@record.site.attachments_directory, relative_path)
  end
  
  def directory_path
    @directory_path ||= File.join(@record.site.attachments_directory, relative_directory_path)
  end
  
  def exist?
    return false if @name.nil?
    File.exist?(path)
  end
  
  def remove_files
    FileUtils.rm_r directory_path if exist?
  end
  
  def reset_memoised_values
    @url = @relative_path = @relative_directory_path = @path = @directory_path = nil
  end
  
  def set_file(file)
    # delete the old file and reset memoised paths
    unless @record.new?
      remove_files
      reset_memoised_values
    end

    # reset the name and mime type of the attachment
    @name = file[:filename]
    @mime = file[:type]
    temp  = file[:tempfile]
    temp_path = temp.path
    temp.close
    
    # for simplicity we move the uploaded file (from /tmp) rather than copying
    FileUtils.mkpath directory_path
    FileUtils.mv(temp_path, path)
    FileUtils.chmod(0664, path) # (owner: rw, group: rw, other: r)
  end
  
  def length
    return 0 unless self.exist?
    return File.size(path)
  end
end
