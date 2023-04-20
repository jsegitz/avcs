#!/usr/bin/env ruby

require 'open3'
begin
  require 'colorize'
rescue LoadError
  # fallback for missing colorize gem
  class String
    def red;    "\e[31m#{self}\e[0m" end
    def yellow; "\e[33m#{self}\e[0m" end
    def bold;   "\e[1m#{self}\e[22m" end
  end
end

class AVCParser
  attr_accessor :stdin

  TO_PERMISSIONS = [ 'transition' ]

  def initialize( opts = {} )
    @stdin = false

    @ausearch_opts = opts
    @ausearch_opts.unshift('-i')
    @ausearch_opts.unshift('AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR')
    @ausearch_opts.unshift('-m')
    @ausearch_opts.unshift('ausearch')
  end
    
  def get_avcs_ausearch
    begin
      f = IO.popen(@ausearch_opts)
      return f.readlines.delete_if do |e| e=="----\n" end
    rescue
      puts "can't get AVCs from audit log. Do you have the necessary permissions to receive the data (e.g. root)?"
      exit 1
    end
  end

  def get_avcs_stdin
    begin
      return STDIN.readlines
    rescue
    end
  end

  def run
    avc_cache = {}
    if @stdin 
      lines = get_avcs_stdin
      puts
    else
      lines = get_avcs_ausearch
    end
    lines.each do |line|
      next if line=~/received policyload notice/
      next if line=~/apparmor/
      next if line=~/type=PROCTITLE/
      next if line=~/type=SYSCALL/
      if line=~/ ( denied  { (.*) } for  ?(.*) scontext=(\S+) tcontext=(\S+) tclass=(\S+) permissive=(\d))/
        full_avc = $1
        permissions = $2
        fields = $3
        scontext = $4
        tcontext = $5
        tclass = $6
        permissive = $7
        next if avc_cache[permissions + scontext + tcontext + tclass + permissive]
        avc_cache[permissions + scontext + tcontext + tclass + permissive] = 1

        stype = scontext.split(/:/)[2]
        ttype = tcontext.split(/:/)[2]

        print stype.yellow
        print " tried "
        print permissions.red
        if TO_PERMISSIONS.include?( permissions )
          print " to "
        else
          print " on "
        end
        print ttype.yellow
        print " (#{tclass})\n"
        print "\t#{fields}\n\n"
      else
        print "Can't parse: ".red
        puts line
      end
    end
  end
end

# can't use optparse as it doesn't allow for unkown uptions
stdin=false
if ARGV.reject! { |elem| elem=='--stdin' }
  stdin=true
end

a = AVCParser.new( ARGV )
a.stdin=stdin
a.run
