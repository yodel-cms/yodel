class UniqueAttachment < Attachment
  def relative_directory_path
    @relative_directory_path ||= File.join(record.site.identifier)
  end
  
  def remove_files
    FileUtils.rm path if exist?
  end
end
