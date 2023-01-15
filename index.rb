# frozen_string_literal: true

require_relative './framework/app'
require_relative './framework/controller'
require_relative './framework/server'
require_relative './framework/persistent'
require_relative './framework/tls_context'

require_relative './config/tls'
require_relative './config/routes'

Dir['./app/persistent/*.rb'].sort.each { |file| require file }
CONTROLLERS.each_value { |controller_name| require_relative "./app/#{controller_name}" }

# Start app
tls_context = TLSContext.new CERT_PATH, KEY_PATH, CHAIN_PATH
server = Server.new(tls_context)

server.start
