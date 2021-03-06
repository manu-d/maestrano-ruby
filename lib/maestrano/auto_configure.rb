module Maestrano
  module AutoConfigure
    def self.get_marketplace_configurations(config_file_path = nil)
      devpl_config = dev_platform_config(config_file_path)

      begin
        request = RestClient::Request.new(
          method: :get,
          url: "#{devpl_config[:host]}#{devpl_config[:api_path]}",
          user: devpl_config[:env_api_key],
          password: devpl_config[:env_api_secret],
          headers: {accept: :json, content_type: :json}
        )
        response = request.execute
        hash = JSON.parse(response.to_s)
      rescue => e
        raise "No or bad response received from dev platform: #{e}"
      end

      hash['marketplaces'].each do |marketplace|
        Maestrano[marketplace['marketplace']].configure do |config|
          config.environment = marketplace['marketplace']

          [:app, :sso, :api, :webhook, :connec].each do |s|
            (marketplace[s.to_s] || {}).each do |k, v|
              config.send(s).send("#{k}=", v)
            end
          end
        end
      end
    end

    def self.dev_platform_config(config_file_path = nil)
      begin
        if config_file_path
          yaml_config = YAML.load_file("#{Dir.pwd}/#{config_file_path}")
        else
          yaml_config = {'dev_platform' => {}, 'environment' => {}}
        end
      rescue
        yaml_config = {'dev_platform' => {}, 'environment' => {}}
      end

      devpl_config = {}
      devpl_config[:host] = ENV['MNO_DEVPL_HOST'] || yaml_config['dev_platform']['host']
      devpl_config[:api_path] = ENV['MNO_DEVPL_API_PATH'] || yaml_config['dev_platform']['api_path']

      devpl_config[:env_name] = ENV['MNO_DEVPL_ENV_NAME'] || yaml_config['environment']['name']
      devpl_config[:env_api_key] = ENV['MNO_DEVPL_ENV_KEY'] || yaml_config['environment']['api_key']
      devpl_config[:env_api_secret] = ENV['MNO_DEVPL_ENV_SECRET'] || yaml_config['environment']['api_secret']

      raise "Missing configuration: #{devpl_config.select{|k,v| v.nil? || v.empty?}.map{|k,_| k}}" if devpl_config.values.any? { |v| v.nil? || v.empty? }

      devpl_config
    end
  end
end
