class Migration
  def self.copy_missing_migrations_for_all_sites
    Site.all.each do |site|
      next if site.name == 'yodel'
      copy_missing_migrations_for_site(site)
    end
  end
  
  def self.copy_missing_migrations_for_site(site)
    # core yodel migrations
    site_yodel_migrations_dir = File.join(site.migrations_directory, Yodel::YODEL_MIGRATIONS_DIRECTORY_NAME)
    sync_migration_directories(Yodel.config.yodel_migration_directory, site_yodel_migrations_dir)

    # extension migrations
    extension_migrations_dir = File.join(site.root_directory, Yodel::MIGRATIONS_DIRECTORY_NAME, Yodel::EXTENSION_MIGRATIONS_DIRECTORY_NAME)
    Yodel.config.extensions.each do |extension|
      sync_migration_directories(extension.migrations_dir, File.join(extension_migrations_dir, extension.name))
    end
  end
  
  def self.run_migrations_for_all_sites
    Site.all.each do |site|
      run_migrations(site)
    end
  end
  
  def self.run_migrations(site)
    Yodel.config.logger.info "Migrating #{site.name}"
    
    each_migration_for(site) do |migration, file|
      unless migration.nil?
        next if site.migrations.include?(migration.name)
        migration.up(site)
      
        # newly created models are incomplete; reload the site
        # to force complete versions to be generated for use
        site.migrations << migration.name
        site.save
        site.reload
      
        Yodel.config.logger.info "Migrated #{migration.name}"
      else
        raise MissingMigration.new(file)
      end
    end
    
    Yodel.config.logger.info "Migrations for #{site.name} complete"
  end
  
  # As migration files are require'd this method will be triggered so
  # we have a reference to the 'current' migration class being run
  def self.inherited(child)
    @migration = child
  end
  
  
  private
    def self.each_migration_for(site, &block)
      each_migration(File.join(site.migrations_directory, Yodel::YODEL_MIGRATIONS_DIRECTORY_NAME), &block)
      each_migration(File.join(site.migrations_directory, Yodel::EXTENSION_MIGRATIONS_DIRECTORY_NAME), &block)
      each_migration(File.join(site.migrations_directory, Yodel::SITE_MIGRATIONS_DIRECTORY_NAME), &block)
    end
    
    # Iterate over every migration and yield the migration class
    # to the supplied block. Incorrect migration files may result
    # in nil being yielded. The caller can respond appropriately.
    # The current file (a string path) is also provided.
    def self.each_migration(directory)
      return unless File.directory?(directory)
      Dir[File.join(directory, '**/*.rb')].sort.each do |file|
        @migration = nil
        load file
        yield @migration, file
        Object.send(:remove_const, @migration.name.to_sym) if @migration
      end
    end
    
    def self.sync_migration_directories(authoritative_folder, site_folder)
      if File.exist?(site_folder)
        Dir[File.join(authoritative_folder, '**/*.rb')].each do |file|
          destination = File.join(site_folder, File.basename(file))
          unless File.exist?(destination)
            FileUtils.cp(file, destination)
          end
        end
      else
        FileUtils.cp_r(authoritative_folder, site_folder)
      end
    end
end
