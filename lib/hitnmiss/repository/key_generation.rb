module Hitnmiss
  module Repository
    module KeyGeneration
      KEY_COMPONENT_SEPARATOR = '.'.freeze
      KEY_COMPONENT_TYPE_SEPARATOR = ':'.freeze

      def self.included(mod)
        mod.extend(ClassMethods)
        mod.include(InstanceMethods)
      end

      module ClassMethods
        def keyspace
          name
        end
      end

      module InstanceMethods
        private

        def generate_key(*args)
          components = args.map do |arg|
            "#{arg.class.name}#{KEY_COMPONENT_TYPE_SEPARATOR}#{arg}"
          end
          return "#{self.class.keyspace}#{KEY_COMPONENT_SEPARATOR}" \
                 "#{components.join(KEY_COMPONENT_SEPARATOR)}"
        end
      end
    end
  end
end
