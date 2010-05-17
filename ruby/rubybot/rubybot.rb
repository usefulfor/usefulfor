#!/usr/bin/ruby
=begin
**
** rubybot.rb
** 18/Apr/2007
** ETD-Software
**  - Daniel Martin Gomez <etd[-at-]nomejortu.com>
**
** Desc:
**   Ruby script to process incoming email. Plugin support to handle different
** types of email requests. Ruby on Rails's ActionMailer is required.
**  
** For each email processed three actions are taken:
**   0.- get email from standard input
**   1.- process incoming mail (using ActionMailer)
**   2.- handle the request to the specific plugin
**   3.- notify the administrator of the process
**
** Version:
**  v1.0 [18/Apr/2007]: first released
**  v1.1 [16/May/2010]: adapt to ActionMailer 2.3.5
**
** License:
**   This file may be used under the terms of the GNU General Public
** License version 2.0 as published by the Free Software Foundation
** available at http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
**
**
=end

#--------------------------------------- config
$options = {
  :myself => 'rubybot@yourdomain.com',
  :admin => 'admin@yourdomain.com',
  :subject => '[rubybot] notificacion:',
  :plugins_dir => './rbplugins',
  :pluginopt => { 
    :tmpdir => './tmp',
    :logger => nil
  }
}
#--------------------------------------- /config

require 'rubygems'
require 'action_mailer'
require 'ftools'

#wrapper of RoR ActionMailer
class RubyBot < ActionMailer::Base
  def receive(email)
    return email
  end

  def notification(msg, out, log)
    recipients $options[:admin]
    subject "#{$options[:subject]} #{msg.subject}"
    from $options[:myself]
    content_type 'multipart/alternative'
    
    commands = 'empty'
    if (msg.parts.empty?)
      commands = msg.body
    else
      commands = msg.parts[0].body
    end


    contents =<<EOF
    ------------------------------------
    Rubybot:: message received
    From: #{msg.from}
    Subject: #{msg.subject}
    Date: #{msg.date}
    Body:
      #{commands}
    Output: 
      #{out} 
    ------------------------------------
EOF
      
    body contents

    attachment :content_type => 'text/plain', :body => File.readlines(log).join("\n")
  end
end


#log = Logger.new(STDERR)
logfile = $options[:plugins_dir]+'/msg.log'
File.rm_f(logfile) if File.exist?(logfile)
log = Logger.new(logfile)

log.level = Logger::DEBUG
#log.level = Logger::INFO
#log.level = Logger::FATAL
$options[:pluginopt][:logger] = log
 

#0.- get email from standard input
email = ''
while gets
  email << $_
end

#1.- process incoming mail
msg = RubyBot.receive(email)

#2.- process the command (from email's subject)
module_name = msg.subject.split[0]
module_file = $options[:plugins_dir] + '/' + module_name + '.rb'
if (FileTest.exists?(module_file))
  log.info{ "valid plugin found: #{module_name}" }
  begin
    load module_file
    plugin = Kernel.const_get(module_name.capitalize + 'Plugin').new
    output = plugin.process(msg, $options[:pluginopt])
  rescue
    log.error{ "error while processing command: #{$!}" }
    log.debug{ $!.backtrace.join("\n") }
    output = "error while processing command: #{$!}"
  end
else
  log.error {"module not found in plugins dir (#{$options[:plugins_dir]})"}
end

log.close

#3.- notify admin
RubyBot.deliver_notification(msg, output, logfile).to_s
