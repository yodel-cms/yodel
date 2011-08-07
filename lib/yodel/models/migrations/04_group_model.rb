class GroupModelMigration < Migration
  def self.up(site)
    site.records.create_model :groups do |groups|
      add_field :name, :string, validations: {required: {}}
      add_many  :users, store: false
      groups.icon = '/admin/images/group_icon.png'
      groups.record_class_name = 'Group'
    end
    site.reload
    
    # a special singleton group representing an 'owner' of a record
    site.groups.create_model :owner_groups do |group|
      group.record_class_name = 'OwnerGroup'
    end
    site.reload
    
    # a special singleton group representing no one
    site.groups.create_model :noone_groups do |group|
      group.record_class_name = 'NooneGroup'
    end
    site.reload
    
    # a special singleton group representing 'everyone'
    site.groups.create_model :guest_groups do |group|
      group.record_class_name = 'GuestsGroup'
    end
    site.reload
    
    
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
    
    guests = site.guest_groups.new(name: 'Guests')
    guests.parent = users
    guests.save
  end
  
  def self.down(site)
    site.groups.destroy
    site.owner_groups.destroy
    site.noone_groups.destroy
    site.guest_groups.destroy
  end
end
