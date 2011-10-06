class Migration
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
      each_migration(site.migrations_directory.join(Yodel::YODEL_MIGRATIONS_DIRECTORY_NAME), &block)
      each_migration(site.migrations_directory.join(Yodel::EXTENSION_MIGRATIONS_DIRECTORY_NAME), &block)
      each_migration(site.migrations_directory.join(Yodel::SITE_MIGRATIONS_DIRECTORY_NAME), &block)
    end
    
    # Iterate over every migration and yield the migration class
    # to the supplied block. Incorrect migration files may result
    # in nil being yielded. The caller can respond appropriately.
    # The current file (a string path) is also provided.
    def self.each_migration(directory)
      Dir[directory.join('**/*.rb')].sort.each do |file|
        @migration = nil
        load file
        yield @migration, file
        Object.send(:remove_const, @migration.name.to_sym) if @migration
      end
    end
end
