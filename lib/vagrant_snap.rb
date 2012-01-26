require "virtualbox"
require "colored"
require "pp"

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
          vm = ::VirtualBox::VM.find( vmname )
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

        def next_available_snapname
          if lastname.nil?
            "0"
          else
            n = lastname.succ
            n = n.succ while VBox::SnapShot.include? n
            n
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
    def help
      puts <<-EOS
Usage: vagrant snap <subcommand> [options...]

 subcommands are..
    vagrant snap list
    vagrant snap back
    vagrant snap go <snapshot> [boxname]
    vagrant snap take [TARGET] [-n SNAP_NAME] [-d DESC]"
    vagrant snap delete <snapshot> [boxname]"
    
      EOS
    end
    def execute# {{{
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(@argv)
      # p [@main_args, @sub_command, @sub_args]

      # sub_list = %w(list go back take delete test)
      sub_list = %w(list go back take delete)
      unless @sub_command
        help
        exit
      end
      if sub_list.include? @sub_command
        send(@sub_command)
      else
        ui.warn "unkown command '#{@sub_command}'"
        help
        exit
      end
    end# }}}

    private
    # def env
    # @_env ||= Vagrant::Environment.new
    # end

    def ui# {{{
      @ui ||= ::Vagrant::UI::Colored.new("vagrant")
    end# }}}
    def safe_with_target_vms(target, &blk)# {{{
      with_target_vms(target) do |vm|
        unless vm.created?
          @logger.info("not created yet: #{vm.name}")
          next
        end
        puts "[#{vm.name}]"
        blk.call(vm)
      end
    end# }}}
    def target_vmname# {{{
      target = @sub_args.empty? ? nil : @sub_args.last.to_s
    end# }}}
    def exe(cmd)# {{{
      puts "# exe: #{cmd}" if @exe_verbose
      system cmd
    end# }}}

    def list# {{{
      # options = {}
      # opts = OptionParser.new { |opts| opts.banner = "vagrant snap list" }
      # argv = parse_options(opts)
      # # p argv
      safe_with_target_vms(target_vmname) do |vm|
        VBox::SnapShot.parse_tree( vm.uuid )
        puts VBox::SnapShot.tree ? VBox::SnapShot.show : "no snapshot"
      end
    end# }}}
    def go # {{{
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: vagrant snapt go <snapshot> [boxname]"
      end
      snapshot, target = *@sub_args
      unless snapshot
        puts opts.help
        return
      end
      safe_with_target_vms(target) do |vm|
        VBox::SnapShot.parse_tree( vm.uuid )
        if VBox::SnapShot.include?( snapshot )
          exe "VBoxManage controlvm '#{vm.uuid}' poweroff"
          exe "VBoxManage snapshot  '#{vm.uuid}' restore '#{snapshot}'"
          exe "VBoxManage startvm   '#{vm.uuid}' --type headless"
        else
          ui.warn "'#{snapshot}' is not exist"
        end
      end
    end# }}}
    def back# {{{
      safe_with_target_vms(target_vmname) do |vm|
        exe "VBoxManage controlvm '#{vm.uuid}' poweroff"
        exe "VBoxManage snapshot  '#{vm.uuid}' restorecurrent"
        exe "VBoxManage startvm   '#{vm.uuid}' --type headless"
      end
    end# }}}
    def take# {{{
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: vagrant snap take [TARGET] [-n SNAP_NAME] [-d DESC]"
        opts.on("-n", "--name STR", "Name of snapshot"       ){ |v| options[:name] = v }
        opts.on("-d", "--desc STR", "Description of snapshot"){ |v| options[:desc] = v }
      end

      begin
        argv =  parse_options(opts)
      rescue OptionParser::MissingArgument
        raise ::Vagrant::Errors::CLIInvalidOptions, :help => opts.help.chomp
      end
      return if !argv
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
      # p @sub_args
      # return
      # snapshot, target = *@sub_args
      safe_with_target_vms(target_vmname) do |vm|
        VBox::SnapShot.parse_tree( vm.uuid )
        if options[:name] and VBox::SnapShot.include? options[:name]
          ui.warn "'#{options[:name]}' is already exist"
          next
        end
        snapshot = options[:name] ? options[:name] : VBox::SnapShot.next_available_snapname
        cmd = "VBoxManage snapshot '#{vm.uuid}' take '#{snapshot}' --pause"
        if options[:desc]
          cmd << " --description '#{options[:desc]}'"
        end
        exe cmd
      end
    end# }}}

    def delete# {{{
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "vagrant snap delete <snapshot> [boxname]"
      end
      snapshot, target = *@sub_args
      unless snapshot
        puts opts.help
        return
      end
      snapshot, target = *@sub_args
      safe_with_target_vms(target) do |vm|
        VBox::SnapShot.parse_tree( vm.uuid )
        if VBox::SnapShot.include?( snapshot )
          exe "VBoxManage snapshot '#{vm.uuid}' delete '#{snapshot}'"
        else
          ui.warn "'#{snapshot}' is not exist"
        end
      end
    end# }}}
  end
end
Vagrant.commands.register(:snap) { ::Snap::Snap }
