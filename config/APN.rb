require 'houston'

APN = Houston::Client.development
APN.certificate = File.read("#{File.dirname(__FILE__)}/pushcert.pem")
