require 'fileutils'
require 'yaml'

module LsbInit

	USAGE = <<-END
USAGE:

    lsb_init_ruby command service_name

  commands:
    e - generate rc script (with disabling and removing of existing one), for project and places it into lsb_init folder.
    r - disable and remove script
	END

  class ProjectIsNotUnderBundler < Exception
    def note
      <<-END

      Please run `lsb_init_ruby` from directory (or tree) containing Gemfile

      END
    end

    def message
      "Cannot find proper project's root directory"
    end
  end

  class InappropriateServiceName < Exception

    def message
      "Cannot generate service with name <#{@service_name}>"
    end

    def note
      <<-END

      Try to generate script with another service name:
        lsb_init_ruby g <another_service_name>

      END
    end
  end

  class BadArgumentPassed < Exception
    def message
      'Incorrect call'
    end
    def note
      USAGE
    end
  end

  class Configurator

    def initialize(args)
      # defining @project_root, @service_name
      raise BadArgumentPassed.new if args.length < 1
      find_project
      cmd = args.shift
      define_name args.shift
      cmd(cmd)
    rescue ProjectIsNotUnderBundler, BadArgumentPassed, InappropriateServiceName => e
      puts "ERROR: #{e.message}"
      puts e.note
    end

    def cmd(command)
      @command = command
      case command
        when 'g'
          cleanup
          generate
        when 'd'
          cleanup
        else
          puts USAGE
      end
    end

    def cleanup
      if Dir.exists?(@lsb_init_dir) && Dir.exists?((_="#{@lsb_init_dir}/runner")) && Dir.entries(_).length==1
          puts 'Removing old runner script'
          runner_name = Dir.entries(_).first
          `sudo rm /etc/init.d/#{runner_name}`
          `sudo update-rc.d #{runner_name} remove`
      end

      puts "Removing project's lsb_init_ruby directory"
      `rm -rf #{@lsb_init_dir}` if Dir.exists?(@lsb_init_dir)
    end

    def generate
      gem_dir = File.expand_path('../..', File.expand_path(__FILE__))
      puts "Preparing project's lsb_init folder"

      [@lsb_init_dir].each{|d| Dir.mkdir d}

      puts 'Generating scripts'
      Dir.mkdir "#{@lsb_init_dir}/runner" unless Dir.exists?("#{@lsb_init_dir}/runner")
      rc_filename = "#{@lsb_init_dir}/runner/#{@service_name}"
      rc_file = File.new rc_filename, 'w'

      rc_script = script_text

      rc_file.write rc_script
      rc_file.close

      `cp #{gem_dir}/lsb_init/main.rb #{@lsb_init_dir}/main.rb`
      `cp #{gem_dir}/daemon #{@lsb_init_dir}/daemon`

      `chmod 755 #{rc_filename}`
      `sudo chown root:root #{rc_filename}`
      `sudo cp #{rc_filename} /etc/init.d/#{@service_name}`
      `sudo update-rc.d #{@service_name} defaults`
    end
    
    def find_project
      dir = Dir.pwd
      while !File.exists?("#{dir}/Gemfile") do
        dir = File.expand_path '..', dir
        raise ProjectIsNotUnderBundler.new if dir.eql? '/'
      end
      @project_root = dir
      @lsb_init_dir = "#{dir}/lsb_init"
      @pidfile_path = "#{@lsb_init_dir}/pidfile"
      puts "Used project's root: #{@project_root}"
      puts "Used project's rc folder: #{@lsb_init_dir}"
    end

    def define_name(opts)
      if !opts.nil?
        @service_name = opts
      elsif Dir.exists?(@lsb_init_dir) && Dir.exists?("#{@lsb_init_dir}/runner") && (_=Dir.entries("#{@lsb_init_dir}/runner")).length==1
        @service_name = _[0]
      else
        @service_name = @project_root.split('/').last
      end

      raise InappropriateServiceName.new if @service_name.nil? || `which #{@service_name}`.length > 0
    end
    
    def script_text
    	text = <<-END
#!/bin/bash

### BEGIN INIT INFO
# Provides:          #{@service_name}
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Should-Start:      $time
# Should-Stop:       $time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start and stop the service #{@service_name}
# Description:       Controls the starting and stopping daemon #{@service_name}
#
### END INIT INFO

## Copyright: LAKSHMANAN GANAPATHY on MARCH 16, 2012 
# Access: http://www.thegeekstuff.com/2012/03/lsbinit-script/
##

# Using the lsb functions to perform the operations.
. /lib/lsb/init-functions
# Process name ( For display )
NAME=#{@service_name}
# Daemon name, where is the actual executable
DAEMON=#{@lsb_init_dir}/daemon
# pid file for the daemon
PIDFILE=#{@pidfile_path}

# If the daemon is not there, then exit.
test -x $DAEMON || exit 5

case $1 in
 start)
  # Checked the PID file exists and check the actual status of process
  if [ -e $PIDFILE ]; then
   status_of_proc -p $PIDFILE $DAEMON "$NAME process" && status="0" || status="$?"
   # If the status is SUCCESS then don't need to start again.
   if [ $status = "0" ]; then
    exit # Exit
   fi
  fi
  # Start the daemon.
  log_daemon_msg "Starting the process" "$NAME"
  # Start the daemon with the help of start-stop-daemon
  # Log the message appropriately
  if start-stop-daemon --start --quiet #{('--chuid '+Process.uid.to_s+':'+Process.gid.to_s) if Process.uid!=0 } --oknodo --pidfile $PIDFILE --exec $DAEMON ; then
   log_end_msg 0
  else
   log_end_msg 1
  fi
  ;;
 stop)
  # Stop the daemon.
  if [ -e $PIDFILE ]; then
   status_of_proc -p $PIDFILE $DAEMON "Stoppping the $NAME process" && status="0" || status="$?"
   if [ "$status" = 0 ]; then
    start-stop-daemon --stop #{('--user '+Process.uid.to_s) if Process.uid!=0 } --quiet --oknodo --pidfile $PIDFILE
#    /bin/rm -rf $PIDFILE
   fi
  else
   log_daemon_msg "$NAME process is not running"
   log_end_msg 0
  fi
  ;;
 restart)
  # Restart the daemon.
  $0 stop && sleep 2 && $0 start
  ;;
 status)
  # Check the status of the process.
  if [ -e $PIDFILE ]; then
   status_of_proc -p $PIDFILE $DAEMON "$NAME process" && exit 0 || exit $?
  else
   log_daemon_msg "$NAME Process is not running"
   log_end_msg 0
  fi
  ;;
 reload)
  # Reload the process. Basically sending some signal to a daemon to reload
  # it configurations.
  if [ -e $PIDFILE ]; then
   start-stop-daemon --stop --signal USR1 --quiet --pidfile $PIDFILE --name $NAME
   log_success_msg "$NAME process reloaded successfully"
  else
   log_failure_msg "$PIDFILE does not exists"
  fi
  ;;
 *)
  # For invalid arguments, print the usage message.
  echo "Usage: $0 {start|stop|restart|reload|status}"
  exit 2
  ;;
esac
END
    end

  end

end
