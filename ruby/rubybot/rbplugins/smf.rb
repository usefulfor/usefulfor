=begin
**
** smf.rb
** 16/May/2007
**
** Desc:
**   Plugin for Rubybot to help fight Simple Machines Forum (SMF) spam.
** Implements a @delete_user@ command that deletes an account given by it's 
** database id. This is done using Mechanize to emulate the series of actions
** that a forum administrator would have to perform manually.
**
** This file can be invoked directly outside the Rubybot framework:
**   ruby smf.rb <user id>
**
** License:
**   This file is released under the terms of the Rubybot license. 
** See ../rubybot.rb for details.
**
=end
require 'rbplugins/plugin'
require 'rubygems'
require 'mechanize'

class SmfPlugin
  include Plugin

  protected
#--------------------------------------- config
  CONF = {
    # SMF URL, no trailing slash
    :url => 'http://yourdomain.com/forum',
    :user => 'admin',
    :password => 'password',
    :pages => {
      :login => '/index.php?action=login',
      :delete => '/index.php?action=profile;sa=deleteAccount;u='
    }
  }
#--------------------------------------- /config

  def url_for(page)
    CONF[:url] + CONF[:pages][page]
  end

  public
  def initialize
    @agent = Mechanize.new do |agent|
      agent.user_agent = 'SMF Spam Control'
    end
  end

  def delete_user(*args)  

    return 'Please provide a user id' if args.size.zero?

    args.each do |user|
      page_title = ''

      @log.debug{ "Deleting user #{user}" }
      @log.debug{ 'Loading login page.' }
      @agent.get( url_for(:login) ) do |page|

        page.form_with(:action => /action=login2/) do |login|
          login.user = CONF[:user]
          login.passwrd = CONF[:password]
        end.submit

        @log.debug{ 'Logged in.' }

        @agent.get( url_for(:delete) + user ) do |delete|
          page_title = delete.title
          if (page_title =~ /Delete this account/ )
            delete.form_with(:action => /action=profile2/) do |profile|
              profile.remove_type = 'topics'
              profile.checkbox_with(:name => /deleteAccount/).check
            end.submit
            @log.debug{ 'User deleted.' }
          else
            @log.debug{ 'User not found.' }
          end

          begin
            delete.link_with( :href => /action=logout/).click
            @log.debug{ 'Logged out.' }
          rescue
            @log.error{ 'Error logging out' }
          end
        end
      end
    end

    return "good to go: #{args.join('|')}"
  end
end


# You can run this script from the command line:
# ruby rbplugins/smf <user id>
if __FILE__ == $0
  require 'logger'
  smf = SmfPlugin.new()
  smf.instance_variable_set('@log', Logger.new(STDERR))
  smf.delete_user ARGV[0]
end
