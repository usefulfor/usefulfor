#!/usr/bin/env ruby
# = Meta
# x509.rb - OpenSSL-based X509 generation
#   Daniel Martin Gomez <daniel@ngssoftware.com>
#
# = Desc
# X509 will let you generate a certificate controlling pretty much every field.
#
# = License
# This file may be used under the terms of the GNU General Public
# License version 2.0 as published by the Free Software Foundation
# and appearing in the file LICENSE.txt included in the packaging of
# this file.


require 'openssl'
require 'optparse'


class X509
  X509::OPTS = {
    :ca_country => 'UK',
    :ca_state => 'Surrey',
    :ca_location => 'Sutton',
    :ca_organisation => 'NGSSoftware',
    :ca_organisational_unit => 'Consultancy',
    :ca_common_name => 'localhost',
    :ca_email => 'daniel@ngssoftware.com',
    :cert_country => 'UK',
    :cert_state => 'Surrey',
    :cert_location => 'Sutton',
    :cert_organisation => 'NGSSoftware',
    :cert_organisational_unit => 'Consultancy',
    :cert_common_name => 'localhost',
    :cert_email => 'daniel@ngssoftware.com',
    :key_length => 1024,
    :cert_version => 2,
    :cert_serial => 0x007
  }

  def X509::generate(params={})

    params.replace( X509::OPTS.merge(params) )

    issuer = ''
    [ 
      ['/C', :ca_country], 
      ['/ST', :ca_state],
      ['/L', :ca_location],
      ['/O', :ca_organisation],
      ['/OU', :ca_organisational_unit],
      ['/CN', :ca_common_name],
      ['/emailAddress', :ca_email]
    ].each do |tag, key|
      issuer << tag
      issuer << '='
      issuer << params[key] 
    end

    subject = ''
    [ 
      ['/C', :cert_country], 
      ['/ST', :cert_state],
      ['/L', :cert_location],
      ['/O', :cert_organisation],
      ['/OU', :cert_organisational_unit],
      ['/CN', :cert_common_name],
      ['/emailAddress', :cert_email]
    ].each do |tag, key|
      subject << tag
      subject << '='
      subject << params[key] 
    end

    p issuer
    p subject

    key = OpenSSL::PKey::RSA.generate( params[:key_length].to_i )
    ca = OpenSSL::X509::Name.parse(subject)
    issuer = OpenSSL::X509::Name.parse(issuer)

    cert = OpenSSL::X509::Certificate.new
    cert.version = params[:cert_version]
    cert.serial = params[:cert_serial]
    cert.subject = ca
    cert.issuer = issuer 
    cert.public_key = key.public_key
    # Offset to GMT-10
    cert.not_before = params.fetch(:not_before, Time.now - 60 * 60 * 10)
    # Valid for a year from now
    #cert.not_after = params.fetch(:not_after, Time.now + 60 * 60 * 24 * 265)
    cert.not_after = params.fetch(:not_after, Time.now + 60 * 60 * 24 * 265)

    return cert, key
  end
end


if __FILE__ == $0
  #---------------------------------- parse command line 
  options = {} 
  opts = OptionParser.new
  opts.banner = "x509 certificate generation tool\n\n"
  opts.banner << "Usage: x509.rb [OPTIONS]"
  opts.version = [0,1] 
  opts.summary_indent = '    '

  # cert options
  opts.separator ' '
  opts.separator '  Certificate options:'
  opts.on('-k LENGTH', '--key-length LENGTH', Integer, 'Certificate key length') { |length| options[:key_length] = length }
  opts.on('--not-before TIME', String, 'Certificate start date') { |not_before| 
    # TODO:// not implemented
  }
  opts.on('--not-after TIME', String, 'Certificate expiration date') { |not_after| 
    # TODO:// not implemented
  }
  opts.on('--cert-version LENGTH', Integer, 'Certificate version (i.e. 1, 2, 3...)') { |version| options[:cert_version] = version }
  opts.on('--cert-serial NUM', OptionParser::OctalInteger, 'Certificate serial number (i.e. 0xBEEF)') { |serial| options[:cert_serial] = serial }
  opts.on('--cert-country NAME', String, 'Certificate Country of origin (i.e. UK)'){ |c| options[:cert_country] = c }
  opts.on('--cert-state NAME', String, 'Certificate State (i.e. Surrey)'){ |st| options[:cert_state] = st }
  opts.on('--cert-location NAME', String, 'Certificate Location (i.e. Suttong)'){ |l| options[:cert_location] = l }
  opts.on('--cert-organisation NAME', String, 'Certificate Organisation (i.e. NGSSoftware)'){ |o| options[:cert_organisation] = o }
  opts.on('--cert-organisational-unit NAME', String, 'Certificate Organisational Unit (i.e. Consultancy)'){ |ou| options[:cert_organisational_unit] = ou }
  opts.on('--cert-common-name NAME', String, 'Certificate Common Name (i.e. localhost)'){ |cn| options[:cert_common_name] = cn }
  opts.on('--cert-email NAME', String, 'Certificate Admin. Email (i.e. daniel@ngssoftware.com)'){ |e| options[:cert_email] = e }

  # ca options
  opts.separator ' '
  opts.separator '  Certificate Authority options:'
  opts.on('--ca-country NAME', String, 'CA Country of origin (i.e. UK)'){ |c| options[:ca_country] = c }
  opts.on('--ca-state NAME', String, 'CA State (i.e. Surrey)'){ |st| options[:ca_state] = st }
  opts.on('--ca-location NAME', String, 'CA Location (i.e. Suttong)'){ |l| options[:ca_location] = l }
  opts.on('--ca-organisation NAME', String, 'CA Organisation (i.e. NGSSoftware)'){ |o| options[:ca_organisation] = o }
  opts.on('--ca-organisational-unit NAME', String, 'CA Organisational Unit (i.e. Consultancy)'){ |ou| options[:ca_organisational_unit] = ou }
  opts.on('--ca-common-name NAME', String, 'CA Common Name (i.e. localhost)'){ |cn| options[:ca_common_name] = cn }
  opts.on('--ca-email NAME', String, 'CA Admin. Email (i.e. daniel@ngssoftware.com)'){ |e| options[:ca_email] = e }

  # misc. options
  opts.separator ' '
  opts.separator "  Misc. options:"
  opts.on('-f FILE', '--file FILE', 'Output the PEM encoded certificate to FILE') { |filename| options[:to_file] = filename }
  opts.on('-h', '--help', 'Display this message'){
    puts opts
    exit
  }
  begin
    opts.parse(ARGV) 
  rescue SystemExit
    raise
  rescue Exception =>e 
    puts e
    puts opts
    exit
  end

  cert, key = X509::generate(options)
  if options.key?(:to_file)
    File.open(options[:to_file], 'wb'){ |f| 
      f.write key.to_pem
      f.write cert.to_pem 
    } 
  else
    puts key
    puts cert
  end
end # __FILE__ == $0
