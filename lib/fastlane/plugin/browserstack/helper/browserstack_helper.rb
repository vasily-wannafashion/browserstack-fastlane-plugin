require 'fastlane_core/ui/ui'
require 'rest-client'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class BrowserstackHelper
      # class methods that you define here become available in your action
      # as `Helper::BrowserstackHelper.your_method`
      #

      USER_AGENT = "browserstack_fastlane_plugin"

      def self.show_message
        UI.message("Hello from the browserstack plugin helper!")
      end

      # Uploads file to BrowserStack
      # Params :
      # +config+:: BrowserStack's username.
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +custom_id+:: Custom id for file upload.
      #   +file_path+:: Path to the file to be uploaded.
      #   +artifact_type+:: Type of the uploading file (e.g. "app"/"file" etc.).
      #   +bs_product_type+:: Type of BrowserStack product (e.g. "AppLive"/"AppAutomate" etc.).
      #   +shared_value_name+:: Name of the env for store the link to the uploaded artifact.
      # +supported_file_extensions+:: Array with extensions allowed to upload.
      # +upload_api_endpoint+:: BrowserStack's file upload endpoint.
      def self.upload_file_to_browserstack(config, supported_file_extensions, upload_api_endpoint)
        bs_username = config[:browserstack_username]
        bs_access_key = config[:browserstack_access_key]
        custom_id = config[:custom_id]
        file_path = config[:file_path].to_s

        artifact_type = config[:artifact_type]
        bs_product_type = config[:bs_product_type]
        shared_value_name = config[:shared_value_name]

        validate_file_path(file_path, supported_file_extensions)

        UI.message("Uploading #{artifact_type} to BrowserStack #{bs_product_type}...")
        browserstack_artifact_id = upload_file(bs_username, bs_access_key, file_path, upload_api_endpoint, custom_id)
        UI.success("Successfully uploaded #{artifact_type} #{file_path} to BrowserStack #{bs_product_type} " +
                     "with bs_url : #{browserstack_artifact_id.to_s}")

        UI.success("Setting Environment variable #{shared_value_name} = #{browserstack_artifact_id.to_s}")
        ENV[shared_value_name] = browserstack_artifact_id

        return browserstack_artifact_id
      end

      # Uploads file to BrowserStack
      # Params :
      # +browserstack_username+:: BrowserStack's username.
      # +browserstack_access_key+:: BrowserStack's access key.
      # +file_path+:: Path to the file to be uploaded.
      # +url+:: BrowserStack's app upload endpoint.
      # +custom_id+:: Custom id for file upload.
      def self.upload_file(browserstack_username, browserstack_access_key, file_path, url, custom_id = nil)
        unless custom_id.nil?
          data = "{ \"custom_id\": \"#{custom_id}\" }"
        end

        response_json =
          upload_file_to_url(url, browserstack_username, browserstack_access_key, USER_AGENT, file_path, data)
        return response_json["custom_id"] || response_json["app_url"] || response_json["test_suite_url"]
      end

      # Uploads file to the given URL.
      # Params :
      # +url+:: upload endpoint.
      # +username+:: username to access the URL.
      # +password+:: password to access the URL.
      # +user_agent+:: string that specifies the client app.
      # +file_path+:: path to the file to be uploaded.
      # +data+:: additional data to the payload.
      def self.upload_file_to_url(url, username, password, user_agent, file_path, data = nil)
        payload = {
          multipart: true,
          file: File.new(file_path, 'rb')
        }

        unless data.nil?
          payload[:data] = data
        end

        return execute_post_request(url, username, password, user_agent, payload)
      end

      # Executes the POST-request to the given URL.
      # Params :
      # +url+:: request endpoint.
      # +username+:: username to access the URL.
      # +password+:: password to access the URL.
      # +user_agent+:: string that specifies the client app.
      # +payload+:: the hash with data to be posted.
      def self.execute_post_request(url, username, password, user_agent, payload)
        headers = {
          "User-Agent" => user_agent
        }

        begin
          response = RestClient::Request.execute(
            url: url,
            method: :post,
            user: username,
            password: password,
            headers: headers,
            payload: payload
          )

          response_json = JSON.parse(response.to_s)

          return response_json

        rescue RestClient::ExceptionWithResponse => err
          begin
            error_response = JSON.parse(err.response.to_s)["error"]
          rescue
            error_response = "Internal server error"
          end
          # Give error if request failed.
          UI.user_error!("Request failed!!! Reason : #{error_response}")
        rescue StandardError => error
          UI.user_error!("Request failed!!! Reason : #{error.message}")
        end
      end

      def self.validate_file_path(file_path, allowed_extensions)
        UI.user_error!("No file found at '#{file_path}'.") unless File.exist?(file_path)

        # Validate file extension.
        file_path_parts = file_path.split(".")
        unless file_path_parts.length > 1 && allowed_extensions.include?(file_path_parts.last)
          UI.user_error!("file_path is invalid, only files with extensions #{allowed_extensions.to_s} " +
                           "are allowed to be uploaded.")
        end
      end
    end
  end
end
