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

  class Snap < Vagrant::Command::Base
    # def initialize(argv, env)
      # super
      # @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
    # end
    def execute
      # p @argv
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(@argv)
      p [@main_args, @sub_command, @sub_args]

      sub_list = %w(list go back take delete test)
      if sub_list.include? @sub_command 
        send(@sub_command)
      end

      # when /list/ then list
      # when /list/
        # list
      # puts "HELLO!"
    end

    private
    def list(target=nil)
      # next if vm.vm.nil?    # not yet created
      with_target_vms(target) do |vm|
        puts "[#{vm.name}]"

        unless vm.created?
          @logger.info("not created yet: #{vm.name}")
          next
        end

        p vm.class
        # VBox::SnapShot.parse_tree( vm.vm.name )
        # if VBox::SnapShot.tree
          # result = VBox::SnapShot.show
        # else
          # result = "no snapshot"
        # end
        # puts result
      end
      # puts "list: list snapshot"
    end
    def test(target=nil)
      @env.vms.each do |name, vm|
        p vm.vm
        p name
      end
    end

    def go
      puts "go SNAP_NAME: go to specified snapshot"
    end

    def back
      puts "back: back to current snapshot"
    end

    def take
      puts "take [TARGET] [-n SNAP_NAME] [-d DESC]: take snapshot"
    end

    def delete
      puts "delete SNAP_NAME: delete snapshot"
    end

  end
end
Vagrant.commands.register(:snap) { ::Snap::Snap }
