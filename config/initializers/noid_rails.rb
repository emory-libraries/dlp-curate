# frozen_string_literal: true

# This is a fix for a bug in Hyrax where under certain circumstances the minter
# stops issuing new IDs, preventing new objects from being created.
# See https://github.com/samvera/hyrax/issues/3128 for more details.
::Noid::Rails.configure do |config|
  config.minter_class = Noid::Rails::Minter::Db
end

::Noid::Rails.configure do |config|
  config.template = 'cor-.rdddeeeeeee'
end

::Noid::Rails.config.identifier_in_use = lambda do |id|
  ActiveFedora::Base.exists?(id) || ActiveFedora::Base.gone?(id)
end
