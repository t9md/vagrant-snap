require "colored"

module Snap
  module VBox
    class SnapShot #{{{
      @@snaps = []
      class << self
        def is_endnode?() @@current.uuid == @@snaps.last.uuid end

        def snaps() @@snaps end 

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

        def _parse(snaps, level=0)
          @@snaps << snaps.name
          # time = snaps.time_stamp.strftime  "%m%d-%H:%M"
          time = time_elapse(Time.now - snaps.time_stamp)
          result = "#{'    ' * level}+-#{snaps.name} [ #{time} ]"
          result << " #{snaps.description}" unless snaps.description.empty?
          result = result.yellow  if snaps.uuid == @@current.uuid
          result << "\n"
          snaps.children.each do |e|
            result <<  _parse(e, level+1)
          end
          result
        end
      end
    end #}}}
  end
	class Command < Vagrant::Command::GroupBase
	  register "snap","Manages a snap"

    no_tasks {
      def vmname
        @vagrant_env ||= Vagrant::Environment.new
        @instance_name ||= "#{@vagrant_env.vms[:default].vm.name}"
        @instance_name
      end
    }

	  desc "list", "list snapshot"
	  def list
      puts VBox::SnapShot.parse_tree( vmname )
	  end

	  desc "go [SNAPNAME]", "go to specified snapshot"
	  def go(snapshot_name)
      system "VBoxManage controlvm #{vmname} poweroff"
      system "VBoxManage snapshot  #{vmname} restore #{snapshot_name}"
      system "VBoxManage startvm   #{vmname} --type headless"
	  end

	  desc "back", "back to current snapshot"
	  def back
      system "VBoxManage controlvm #{vmname} poweroff"
      system "VBoxManage snapshot  #{vmname} restorecurrent"
      system "VBoxManage startvm   #{vmname} --type headless"
	  end

	  desc "take [desc]", "take snapshot"
	  def take(desc="")
      VBox::SnapShot.parse_tree( vmname )
      new_name = VBox::SnapShot.snaps.sort.reverse.first.succ
      new_name = vmname + "-01" if new_name.empty?
      system "VBoxManage snapshot #{vmname} take #{new_name} --description '#{desc}' --pause"
	  end

	  desc "delete", "delete snapshot"
	  def delete(snapshot_name)
      system "VBoxManage snapshot #{vmname} delete #{snapshot_name}"
	  end
	end
end
