class KV
  class Audit
    class Config
      VALIDATE = {
        :single_value => [
          "must be a single value",
          Proc.new { |value, node, kvdb| value.is_a?(String) }
        ],
        :multi_value => [
          "never fails; no-op for verbose schemas",
          Proc.new { |value, node, kvdb| true }
        ],
        :reference => [
          "invalid reference",
          Proc.new do |value, node, kvdb|
            res = true
            value.to_a.each do |v|
                if v[0..0] != '%'
                    res = false
                else
                    res = kvdb.node?(v[1..-1])
                end
            end # values.to_a.each
            res
          end
        ],
      }

      public
      def initialize(kv)
        @config = Hash.new do |h, k|
          h[k] = {
            :required => [],
            :optional => [],
            :validate => Hash.new { |h, k| h[k] = [] },
          }
        end
        @pattern = ".*"

        schema_file = File.join(kv.kvdb_path, "schema")
        if File.exists?(schema_file)
          instance_eval(File.read(schema_file), schema_file)
        end
      end # def initialize

      def for(node)
        node_config = {
          :required => [],
          :optional => [],
          :validate => Hash.new { |h, k| h[k] = [] },
        }

        @config.each do |pattern, config|
          next unless node.match(%r{#{pattern}})
          node_config[:required] += config[:required]
          node_config[:optional] += config[:optional]
          config[:validate].each do |k, v|
            node_config[:validate][k] += v
          end
        end

        return node_config
      end

      public
      def nodes(pattern, &block)
        @pattern = pattern
        yield
        @pattern = ".*"
      end

      public
      def required(data)
        data.each do |key, validates|
          @config[@pattern][:required] << key
          validates.each do |v|
            if VALIDATE.member?(v)
              @config[@pattern][:validate][key] << VALIDATE[v]
            else
              raise KV::Error, "unknown validation function #{v}"
            end
          end
        end
      end # def required

      public
      def optional(data)
        data.each do |key, validates|
          @config[@pattern][:optional] << key
          validates.each do |v|
            if VALIDATE.member?(v)
              @config[@pattern][:validate][key] << VALIDATE[v]
            else
              raise KV::Error, "unknown validation function #{v}"
            end
          end
        end
      end # def optional

      public
      def validate(key, reason, &block)
        @config[@pattern][:validate][key] << [reason, block]
      end # def validate
    end # class Config
  end # class Audit
end # class KV
