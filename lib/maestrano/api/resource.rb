module Maestrano
  module API
    class Resource < Maestrano::API::Object
      def self.class_name
        self.name.split('::')[-1]
      end

      def self.url
        if self == Maestrano::API::Resource
          raise NotImplementedError.new('Maestrano::API::Resource is an abstract class.  You should perform actions on its subclasses (Bill, Customer, etc.)')
        end
        "#{CGI.escape(class_name.downcase)}s"
      end

      def url
        unless id = self['id']
          raise Maestrano::API::Error::InvalidRequestError.new("Could not determine which URL to request: #{self.class} instance has invalid ID: #{id.inspect}", 'id')
        end
        "#{self.class.url}/#{CGI.escape(id)}"
      end

      def refresh
        response, api_key = Maestrano::API::Operation::Base.request(:get, url, @api_key, @retrieve_options)
        refresh_from(response, api_key)
        self
      end

      def self.retrieve(id, api_key=nil)
        instance = self.new(id, api_key)
        instance.refresh
        instance
      end
    end
  end
end