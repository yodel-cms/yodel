class GroupModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'Group', inherits: 'Record' do |model|
      model.add_field :name, String, required: true
      model.add_field :users, Many, of: 'User', foreign_key: 'groups'
      model.icon = '/admin/images/group_icon.png'
      model.klass = 'Yodel::Group'
    end
    
    # a special singleton group representing an 'owner' of a record
    site.models.create_model 'OwnerGroup', inherits: 'Group' do |model|
      model.klass = 'Yodel::OwnerGroup'
    end
    
    # a special singleton group representing no one
    site.models.create_model 'NooneGroup', inherits: 'Group' do |model|
      model.klass = 'Yodel::NooneGroup'
    end
    
    # a special singleton group representing 'everyone'
    site.models.create_model 'GuestsGroup', inherits: 'Group' do |model|
      model.klass = 'Yodel::GuestsGroup'
    end
    
    
    # permissions are based on a hierarchy of groups. branches are permitted.
    noone = site.noone_groups.new(name: 'No One')
    noone.save
    
    devs = site.groups.new(name: 'Developers')
    devs.parent = noone
    devs.save
    
    admins = site.groups.new(name: 'Administrators')
    admins.parent = devs
    admins.save
    
    owner = site.owner_groups.new(name: 'Owner')
    owner.parent = admins
    owner.save
    
    users = site.groups.new(name: 'Users')
    users.parent = owner
    users.save
    
    guests = site.guests_groups.new(name: 'Guests')
    guests.parent = users
    guests.save
    
    
    # add fields to track permissions per page; these fields can be overriden
    # to have defaults so you don't need to set them manually each instance
    site.records.modify do |model|
      model.add_field :view_group, Reference, to: 'Group', default: nil
      model.add_field :create_group, Reference, to: 'Group', default: nil
      model.add_field :update_group, Reference, to: 'Group', default: nil
      model.add_field :delete_group, Reference, to: 'Group', default: nil
    end
  end
  
  def self.down(site)
    site.groups.destroy
    site.owner_groups.destroy
  end
end
