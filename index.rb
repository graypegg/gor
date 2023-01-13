# frozen_string_literal: true

require_relative './app'
require_relative './server'
require_relative './tls_context'

require_relative './config/tls'
require_relative './config/routes'

CONTROLLERS.each_value { |controller_name| require_relative "./app/#{controller_name}" }

# Start app
tls_context = TLSContext.new CERT_PATH, KEY_PATH, CHAIN_PATH
server = Server.new(tls_context)

server.start
