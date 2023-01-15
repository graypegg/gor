# frozen_string_literal: true

require 'bundler/setup'

require_relative './framework/app'
require_relative './framework/controller'
require_relative './framework/server'
require_relative './framework/persistent'
require_relative './framework/tls_context'

require_relative './config/tls'
require_relative './config/routes'

Dir['./app/persistent/*.rb'].sort.each { |file| require file }
Dir['./app/*_controller.rb'].sort.each { |file| require file }
CONTROLLERS = ROUTES.inject({}) do |controllers, route_pair|
  controllers.merge({ route_pair[0] => Kernel.const_get(route_pair[1]) })
end

# Start app
tls_context = TLSContext.new CERT_PATH, KEY_PATH, CHAIN_PATH
server = Server.new(tls_context)

server.start
