require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('imexport', '0.1.3') do |p|
  p.description     = "Simple import from a text file generated by mysql -E ..."
  p.url             = "http://github.com/crhym3/imexport"
  p.author          = "alex"
  p.email           = "alex@digns.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
  
  # github can't sign gems, yet
  p.certificate_chain = nil
  p.private_key       = nil
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }

