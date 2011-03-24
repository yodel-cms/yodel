module Yodel
  class Migration
    def self.remaining_migrations
      Yodel::Site.all.each_with_object(Hash.new([])) do |site, remaining|
        each_migration do |migration, file|
          if migration.nil?
            remaining[site] <<= "Invalid migration file: #{file}"
          elsif !site.migrations.include?(migration.name)
            remaining[site] <<= "#{migration.name}: #{file}"
          end
        end
      end
    end
    
    def self.run_migrations(site)
      each_migration do |migration, file|
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
          raise Yodel::MissingMigration.new(file)
        end
      end
      
      Yodel.config.logger.info "Migrations complete"
    end
    
    # As migration files are require'd this method will be triggered so
    # we have a reference to the 'current' migration class being run
    def self.inherited(child)
      @migration = child
    end
    
    
    private  
      # Iterate over every migration and yield the migration class
      # to the supplied block. Incorrect migration files may result
      # in nil being yielded. The caller can respond appropriately.
      # The current file (a string path) is also provided.
      def self.each_migration
        Yodel.config.migration_directories.each do |dir|
          next unless dir.directory?
          Dir[dir.join('*.rb')].sort.each do |file|
            @migration = nil
            load file
            yield @migration, file
            Object.send(:remove_const, @migration.name.to_sym) if @migration
          end
        end
      end
  end
end
