require 'rubygems'
include Rake::DSL

require 'echoe'
Echoe.new "vagrant-snap", File.read("./VERSION").chomp do |p|
  p.author = "t9md"
  p.email = "taqumd@gmail.com"
  p.summary = %Q{vagrant snapshot managemen plugin}
  p.project = nil
  p.url = "http://github.com/t9md/vagrant-snap"
  p.ignore_pattern = ["misc/*"]
  p.runtime_dependencies << 'vagrant'
  p.runtime_dependencies << 'colored'
end
