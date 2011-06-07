require "colored"

module Snap
  module VBox
    class SnapShot #{{{
      class << self
        def snapnames()
          @@snapnames ||= []
        end

        def parse_tree(vmname)
          vm = VirtualBox::VM.find( vmname )
          @@current = vm.current_snapshot
          return unless @@current
          _parse(vm.root_snapshot)
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

        ## [TODO] darty hack, should be written more simply
        def _parse(snapshot, guide = "")
          snapnames << snapshot.name
          time      = time_elapse(Time.now - snapshot.time_stamp)
          snapinfo  = "#{snapshot.name} [ #{time} ]"
          snapinfo  = snapinfo.yellow  if snapshot.uuid == @@current.uuid
          result    = "#{guide} #{snapinfo}"
          result    << " #{snapshot.description}" unless snapshot.description.empty?
          result    << "\n"

          last_child_idx = snapshot.children.size - 1
          snapshot.children.each_with_index do |e, idx|
            tmp = guide.chop.chop.sub("`", " ") + "    "
            tmp << "#{last_child_idx == idx ? '`' : '|'}" << "--"
            result <<  _parse(e, "#{tmp}")
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
        result = VBox::SnapShot.parse_tree( vmname )
        puts result ? result : "no snapshot"
      end
	  end

	  desc "go SNAP_NAME", "go to specified snapshot"
	  def go(snapshot_name, target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        system "VBoxManage controlvm #{vmname} poweroff"
        system "VBoxManage snapshot  #{vmname} restore #{snapshot_name}"
        system "VBoxManage startvm   #{vmname} --type headless"
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
        new_name = options.name if options.name
        unless new_name
          last_name = VBox::SnapShot.snapnames.sort.reverse.first
          new_name = last_name.nil? ? "001" : last_name.succ
        end
        desc = options.desc ? " --description '#{options.desc}'" : ""
        system "VBoxManage snapshot #{vmname} take #{new_name} #{desc} --pause"
      end
	  end

	  desc "delete SNAP_NAME", "delete snapshot"
	  def delete(snapshot_name, target=nil)
      with_target(target) do |vmname, vagvmname|
        puts "[#{vagvmname}]"
        system "VBoxManage snapshot #{vmname} delete #{snapshot_name}"
      end
	  end
	end
end
