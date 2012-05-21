require "rubygems"
require "kv/audit/config"
require "kv/util"

class KV
  class Audit
    attr_reader :config
    attr_reader :messages

    public
    def initialize(kv)
      @kv = kv
      @config = KV::Audit::Config.new(@kv)
    end # def initialize

    public
    def audit
      @messages = Hash.new { |h, k| h[k] = [] }

      @kv.nodes.each do |node_name|
        node_config = @config.for(node_name)
        node = @kv.node(node_name)

        audit_required(node, node_config)
        audit_validations(node, node_config)
      end

      return @messages
    end # def audit


    private
    def audit_required(node, config)
      config[:required].each do |key|
        if ! node[key]
          @messages[node.name] << "#{key}: missing required key"
        end
      end
    end # def audit_required

    private
    def audit_validations(node, config)
      config[:validate].each do |key, validations|
        validations.each do |reason, test|
          value = node[key]
          next unless value
          if ! test.call(value, node, @kv)
            @messages[node.name] << "#{key}: #{value.inspect}: #{reason}"
          end
        end # validations.each
      end # config[:validate].each
    end # # def audit_validations
  end # class Audit
end # class KV
