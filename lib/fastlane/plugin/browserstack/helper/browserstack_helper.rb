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

      # Runs XCUITest on BrowserStack
      # Params :
      # +config+:: BrowserStack's username.
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +app_url+:: App under testing URL on BrowserStack.
      #   +test_suite_url+:: Test suite URL on BrowserStack.
      #   +devices+:: Array of the devices to launch XCUITest automation run on.
      #   +only_testing+:: Array of the tests to execute.
      #   +skip_testing+:: Array of the tests to skip.
      #   +shared_value_name+:: Name of the env for store the link to the uploaded artifact.
      # +supported_file_extensions+:: Array with extensions allowed to upload.
      # +upload_api_endpoint+:: BrowserStack's file upload endpoint.
      def self.run_xcuitest_on_browserstack(config, run_xcuitest_api_endpoint)
        bs_username = config[:browserstack_username]
        bs_access_key = config[:browserstack_access_key]

        payload = {}
        payload[:app] = config[:app_url]
        payload[:testSuite] = config[:test_suite_url]
        payload[:devices] = config[:devices]
        payload["only-testing"] = config[:only_testing] unless config[:only_testing].nil?
        payload["skip-testing"] = config[:skip_testing] unless config[:skip_testing].nil?

        shared_value_name = config[:shared_value_name]

        UI.message("Launching XCUITest automation run on BrowserStack...")
        response_json = execute_request(run_xcuitest_api_endpoint, "post", bs_username, bs_access_key, USER_AGENT, payload)
        browserstack_artifact_id = response_json["build_id"]
        UI.success("XCUITest automation run launched with app: #{payload[:app]} " +
                     "and test suite: #{payload[:testSuite]} " +
                     "on devices: #{payload[:devices]} " +
                     "on BrowserStack Automation with bs_url: #{browserstack_artifact_id.to_s}" +
                     "including tests: #{payload["only-testing"]}" +
                     "skipping tests: #{payload["skip-testing"]}")

        UI.success("Setting Environment variable #{shared_value_name} = #{browserstack_artifact_id.to_s}")
        ENV[shared_value_name] = browserstack_artifact_id

        return browserstack_artifact_id
      end

      # Checks XCUITest status on BrowserStack
      # Params :
      # +config+:: BrowserStack's username.
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +xctest_build_id+:: BrowserStack's ID of automation run.
      #   +shared_value_name+:: Name of the env for store the link to the uploaded artifact.
      # +supported_file_extensions+:: Array with extensions allowed to upload.
      # +upload_api_endpoint+:: BrowserStack's file upload endpoint.
      def self.check_xcuitest_automation_status(config, check_xcuitest_api_endpoint)
        bs_username = config[:browserstack_username]
        bs_access_key = config[:browserstack_access_key]
        shared_value_name = config[:shared_value_name]

        UI.message("Checking XCUITest automation run status on BrowserStack...")
        response_json = execute_request(check_xcuitest_api_endpoint, "get", bs_username, bs_access_key, USER_AGENT)
        xcuitest_automation_status = response_json["status"].to_s

        UI.success("XCUITest automation run status: #{xcuitest_automation_status} " +
                     "for launch ID #{config[:xctest_build_id].to_s}")

        UI.success("Setting Environment variable #{shared_value_name} = #{xcuitest_automation_status.to_s}")
        ENV[shared_value_name] = xcuitest_automation_status

        return xcuitest_automation_status
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

        return execute_request(url, "post", username, password, user_agent, payload)
      end

      # Executes the HTTP-request to the given URL.
      # Params :
      # +url+:: request endpoint.
      # +method+:: request method.
      # +username+:: username to access the URL.
      # +password+:: password to access the URL.
      # +user_agent+:: string that specifies the client app.
      # +payload+:: the hash with data to be posted.
      def self.execute_request(url, method, username, password, user_agent, payload = nil)
        headers = {
          "User-Agent" => user_agent
        }

        begin
          response = RestClient::Request.execute(
            url: url,
            method: method,
            user: username,
            password: password,
            headers: headers,
            payload: payload
          )

          response_json = JSON.parse(response.to_s)

          return response_json

        rescue RestClient::ExceptionWithResponse => err
          process_response_error(err)
        rescue StandardError => error
          process_error(error.message)
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

      def self.process_response_error(error)
        begin
          error_response = JSON.parse(error.response.to_s)["error"]
        rescue
          error_response = "Internal server error"
        end
        # Give error if request failed.
        process_error(error_response)
      end

      def self.process_error(reason)
        UI.user_error!("Request failed!!! Reason : #{reason}")
      end
    end
  end
end
