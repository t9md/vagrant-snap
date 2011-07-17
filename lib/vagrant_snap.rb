require "colored"

module Snap
  module VBox
    class SnapShot #{{{
      class << self
        def tree
          @@tree
        end
        
        Snap = Struct.new(:name, :time_stamp, :description, :uuid, :current)
        
        def init
          @@current = nil
          @@tree = nil
        end

        def parse_tree(vmname)
          init
          vm = VirtualBox::VM.find( vmname )
          @@current = vm.current_snapshot
          return unless @@current
          @@tree = _parse(vm.root_snapshot)
        end

        # [TODO] need refactoring
        def time_elapse(time)
          _sec  = 1
          _min  = _sec * 60
          _hour = _min * 60
          _day  = _hour * 24

          sec = time.to_i
          min = sec / _min
          hour = sec / _hour
          day  = sec / _day

          case
          when day  > 0 then "#{day} day#{day == 1 ? '' : 's'}"
          when hour > 0 then "#{hour} hour#{hour == 1 ? '' : 's'}"
          when min  > 0 then "#{min} minute#{min == 1 ? '' : 's'}"
          when sec  > 0 then "#{sec} second#{sec == 1 ? '' : 's'}"
          end
        end

        def _parse(s)
          tree = [ Snap.new(s.name , s.time_stamp, s.description, s.uuid, s.uuid == @@current.uuid) ]
          s.children.each do |c|
            tree.concat [_parse(c)]
          end
          tree
        end

        def format(guide, s)
          time     = time_elapse(Time.now - s.time_stamp)
          snapinfo = "#{s.name} [ #{time} ]"
          snapinfo  = snapinfo.yellow  if s.current
          result   = "#{guide} #{snapinfo}"
          result  << " #{s.description}" unless s.description.empty?
          result  << "\n"
        end

        def lastname
          if tree
            tree.flatten.sort_by(&:time_stamp).last.name
          else
            nil
          end
        end

        def include?(name)
          return false unless tree
          tree.flatten.map(&:name).include? name
        end

        def show(t=tree, guide="")
          result = ""
          t.each_with_index do |v, idx|
            case v
            when Array
              tmp = guide.dup.chop.chop.sub("`", " ") << "    "
              tmp << "#{t.size == idx + 1 ? '`' : '|'}" << "--"
              result << show(v, tmp)
            else
              result << format(guide, v)
            end
          end
          result
        end
      end
    end #}}}
  end

	class Command < Vagrant::Command::GroupBase
	  register "snap","Manages a snap"

    no_tasks {
      def env
        @_env ||= Vagrant::Environment.new
      end

      def with_target(target, &blk)
        target_found = false
        env.vms.each do |name, vm|
          vagvmname = vm.name
          vmname    = vm.vm.name

          if target.nil? or target.to_sym == vagvmname
            blk.call(vmname, vagvmname)
            target_found = true
          end
        end
        warn "A VM by the name of `#{target}' was not found".red unless target_found
      end
    }

	  desc "list", "list snapshot"
	  def list(target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        VBox::SnapShot.parse_tree( vmname )
        if VBox::SnapShot.tree
          result = VBox::SnapShot.show
        else
          result = "no snapshot"
        end
        puts result
      end
	  end

	  desc "go SNAP_NAME", "go to specified snapshot"
	  def go(snapshot_name, target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        VBox::SnapShot.parse_tree( vmname )
        if VBox::SnapShot.include?( snapshot_name )
          system "VBoxManage controlvm #{vmname} poweroff"
          system "VBoxManage snapshot  #{vmname} restore #{snapshot_name}"
          system "VBoxManage startvm   #{vmname} --type headless"
        else
          warn "#{snapshot_name} is not exist".red
        end
      end
	  end

	  desc "back", "back to current snapshot"
	  def back(target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        system "VBoxManage controlvm #{vmname} poweroff"
        system "VBoxManage snapshot  #{vmname} restorecurrent"
        system "VBoxManage startvm   #{vmname} --type headless"
      end
	  end

	  desc "take [TARGET] [-n SNAP_NAME] [-d DESC]", "take snapshot"
    method_option :desc, :type => :string, :aliases => "-d"
    method_option :name, :type => :string, :aliases => "-n"
	  def take(target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        VBox::SnapShot.parse_tree( vmname )
        if options.name
          if VBox::SnapShot.include? options.name
            warn "#{options.name} is already exist".red
            next
          else
            new_name = options.name
          end
        end
        unless new_name
          lastname = VBox::SnapShot.lastname
          new_name = if lastname.nil?
                       "001"
                     else
                       n = lastname.succ
                       n = n.succ while VBox::SnapShot.include? n
                       n
                     end
        end
        desc = options.desc ? " --description '#{options.desc}'" : ""
        system "VBoxManage snapshot #{vmname} take #{new_name} #{desc} --pause"
      end
	  end

	  desc "delete SNAP_NAME", "delete snapshot"
	  def delete(snapshot_name, target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        VBox::SnapShot.parse_tree( vmname )
        if VBox::SnapShot.include?( snapshot_name )
          system "VBoxManage snapshot #{vmname} delete #{snapshot_name}"
        else
          warn "#{snapshot_name} is not exist".red
        end
      end
	  end
	end
end
