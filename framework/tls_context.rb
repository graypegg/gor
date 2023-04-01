# frozen_string_literal: true

class TLSContext
  attr_reader :context

  def initialize(cert_path, key_path, chain_path)
    @context = OpenSSL::SSL::SSLContext.new
    @context.cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    @context.key = OpenSSL::PKey::RSA.new(File.read(key_path))
    # @context.extra_chain_cert = [OpenSSL::X509::Certificate.new(File.read(chain_path))] if chain_path
  end
end
