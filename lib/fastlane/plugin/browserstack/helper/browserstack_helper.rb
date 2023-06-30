require 'fastlane_core/ui/ui'
require 'rest-client'
require 'json'
require 'zip'

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
      # +args+::
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +custom_id+:: Custom id for file upload.
      #   +file_path+:: Path to the file to be uploaded.
      #   +artifact_type+:: Type of the uploading file (e.g. "app"/"file" etc.).
      #   +bs_product_type+:: Type of BrowserStack product (e.g. "AppLive"/"AppAutomate" etc.).
      #   +shared_value_name+:: Name of the env for store the link to the uploaded artifact.
      #   +supported_file_extensions+:: Array with extensions allowed to upload.
      #   +upload_api_endpoint+:: BrowserStack's file upload endpoint.
      def self.upload_file_to_browserstack(args)
        bs_username = args[:browserstack_username]
        bs_access_key = args[:browserstack_access_key]
        custom_id = args[:custom_id]
        file_path = args[:file_path].to_s

        artifact_type = args[:artifact_type]
        bs_product_type = args[:bs_product_type]
        shared_value_name = args[:shared_value_name]

        supported_file_extensions = args[:supported_file_extensions]
        upload_api_endpoint = args[:upload_api_endpoint]

        validate_file_path(file_path, supported_file_extensions)

        UI.message("Uploading #{artifact_type} to BrowserStack #{bs_product_type}...")
        browserstack_artifact_id = upload_file(bs_username, bs_access_key, file_path, upload_api_endpoint, custom_id)
        UI.success("Successfully uploaded #{artifact_type} #{file_path} to BrowserStack #{bs_product_type} " +
                     "with bs_url : #{browserstack_artifact_id.to_s}")

        UI.success("Setting Environment variable #{shared_value_name} = #{browserstack_artifact_id.to_s}")
        ENV[shared_value_name] = browserstack_artifact_id

        return browserstack_artifact_id
      end

      # Runs XCTest on BrowserStack
      # Params :
      # +args+::
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +app_url+:: App under testing URL on BrowserStack.
      #   +test_suite_url+:: Test suite URL on BrowserStack.
      #   +devices+:: Array of the devices to launch XCTest automation run on.
      #   +only_testing+:: Array of the tests to execute.
      #   +skip_testing+:: Array of the tests to skip.
      #   +enable_result_bundle+ :: Flag to enable/disable generating result bundles for XCTest build execution.
      #   +shared_value_name+:: Name of the env for store the link to the XCTest run.
      #   +run_xctest_api_endpoint+:: BrowserStack's endpoint for run XCTest.
      def self.run_xctest_on_browserstack(args)
        bs_username = args[:browserstack_username]
        bs_access_key = args[:browserstack_access_key]
        shared_value_name = args[:shared_value_name]
        run_xctest_api_endpoint = args[:run_xctest_api_endpoint]

        payload = {}
        payload[:app] = args[:app_url]
        payload[:testSuite] = args[:test_suite_url]
        payload[:devices] = args[:devices]
        payload["only-testing"] = args[:only_testing] unless args[:only_testing].nil?
        payload["skip-testing"] = args[:skip_testing] unless args[:skip_testing].nil?
        payload["enableResultBundle"] = args[:enable_result_bundle] unless args[:enable_result_bundle].nil?

        UI.message("Launching XCTest automation run on BrowserStack...")
        response_json = execute_request(run_xctest_api_endpoint, "post", bs_username, bs_access_key, USER_AGENT, payload)
        browserstack_artifact_id = response_json["build_id"]
        UI.success("XCTest automation run launched with app: #{payload[:app]} " +
                     "and test suite: #{payload[:testSuite]} " +
                     "on devices: #{payload[:devices]} " +
                     "on BrowserStack Automation with bs_url: #{browserstack_artifact_id.to_s} " +
                     "including tests: #{payload["only-testing"]} " +
                     "skipping tests: #{payload["skip-testing"]} ")

        UI.success("Setting Environment variable #{shared_value_name} = #{browserstack_artifact_id.to_s}")
        ENV[shared_value_name] = browserstack_artifact_id

        return browserstack_artifact_id
      end

      # Checks XCTest status on BrowserStack
      # Params :
      # +args+::
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +xctest_build_id+:: BrowserStack's ID of automation run.
      #   +shared_value_name+:: Name of the env for store status.
      #   +check_xctest_api_endpoint+:: BrowserStack's endpoint for checking XCTest run status.
      def self.check_xctest_automation_status(args)
        bs_username = args[:browserstack_username]
        bs_access_key = args[:browserstack_access_key]
        shared_value_name = args[:shared_value_name]
        check_xctest_api_endpoint = args[:check_xctest_api_endpoint]

        UI.message("Checking XCTest automation run status on BrowserStack...")
        response_json = execute_request(check_xctest_api_endpoint, "get", bs_username, bs_access_key, USER_AGENT)
        xctest_automation_status = response_json["status"].to_s

        UI.success("XCTest automation run status: #{xctest_automation_status.to_s} " +
                     "for launch ID #{args[:xctest_build_id].to_s}")

        UI.success("Setting Environment variable #{shared_value_name} = #{xctest_automation_status.to_s}")
        ENV[shared_value_name] = xctest_automation_status

        return xctest_automation_status
      end

      # Get XCTest sessions list from BrowserStack
      # Params :
      # +args+::
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +xctest_build_id+:: BrowserStack's ID of automation run.
      #   +shared_value_name+:: Name of the env for store sessions list.
      #   +xctest_api_endpoint+:: BrowserStack's XCTest API endpoint.
      def self.get_xctest_sessions_list(args)
        bs_username = args[:browserstack_username]
        bs_access_key = args[:browserstack_access_key]
        shared_value_name = args[:shared_value_name]
        xctest_api_endpoint = args[:xctest_api_endpoint]

        UI.message("Getting XCTest sessions list from BrowserStack...")
        response_json = execute_request(xctest_api_endpoint, "get", bs_username, bs_access_key, USER_AGENT)

        xctest_sessions_list = []

        xctest_devices = response_json["devices"]
        xctest_devices.each do |device|
          sessions = device["sessions"]
          sessions.each do |session|
            id = session["id"]
            xctest_sessions_list.append(id)
          end
        end

        UI.success("XCTest sessions list: #{xctest_sessions_list.to_s} " +
                     "for launch ID #{args[:xctest_build_id].to_s}")

        xctest_sessions_list_as_s = xctest_sessions_list.join(',')
        UI.success("Setting Environment variable #{shared_value_name} = #{xctest_sessions_list_as_s.to_s}")
        ENV[shared_value_name] = xctest_sessions_list_as_s

        return xctest_sessions_list
      end

      # Download XCResult files from BrowserStack
      # Params :
      # +args+::
      #   +browserstack_username+:: BrowserStack's username.
      #   +browserstack_access_key+:: BrowserStack's access key.
      #   +xctest_build_id+:: BrowserStack's ID of automation run.
      #   +xctest_sessions_list+:: BrowserStack's session IDs of results to download.
      #   +dir_path+:: Path to the directory to save the files.
      #   +build_id_key+:: Key to replace placeholder of build_id in the `download_api_endpoint`.
      #   +session_id_key+:: Key to replace placeholder of session_id in the `download_api_endpoint`.
      #   +shared_value_name+:: Name of the env for store the paths to the downloaded artifacts.
      #   +download_api_endpoint+:: BrowserStack's xcresult file download endpoint.
      def self.download_xcresult_files(args)
        bs_username = args[:browserstack_username]
        bs_access_key = args[:browserstack_access_key]
        xctest_build_id = args[:xctest_build_id]
        xctest_sessions_list = args[:xctest_sessions_list].split(",")
        dir_path = args[:dir_path]
        build_id_key = args[:build_id_key]
        session_id_key = args[:session_id_key]
        shared_value_name = args[:shared_value_name]
        download_api_endpoint = args[:download_api_endpoint]

        xcresult_paths_list = []

        xctest_sessions_list.each do |xctest_session_id|
          UI.message("Getting XCResult from BrowserStack for session ID #{xctest_session_id}...")

          concrete_build_and_session_api_endpoint = download_api_endpoint.clone
                                                      .gsub!(build_id_key, xctest_build_id)
                                                      .gsub!(session_id_key, xctest_session_id)

          concrete_xcresult_archive_filename = "#{xctest_session_id}.zip"
          concrete_xcresult_archive_path = File.join(dir_path, concrete_xcresult_archive_filename)
          concrete_xcresult_filename = "#{xctest_session_id}.xcresult"
          concrete_xcresult_path = File.join(dir_path, concrete_xcresult_filename)

          download_file_from_url(concrete_build_and_session_api_endpoint,
                                 bs_username,
                                 bs_access_key,
                                 USER_AGENT,
                                 concrete_xcresult_archive_path)

          Zip::File.open(concrete_xcresult_archive_path) do |archive|
            archive.each do |file_inside_archive|
              file_inside_archive_path_components = Pathname(file_inside_archive.name).each_filename.to_a
              file_inside_archive_path_components[0] = concrete_xcresult_path
              file_outside_archive_path = File.join(file_inside_archive_path_components)
              archive.extract(file_inside_archive, file_outside_archive_path) unless File.exist?(file_outside_archive_path)
            end
          end

          File.delete(concrete_xcresult_archive_path)

          xcresult_paths_list.append(concrete_xcresult_path)
        end

        UI.success("XCResult files list: #{xcresult_paths_list.to_s} " +
                     "for launch ID #{args[:xctest_build_id].to_s}")

        xcresult_paths_list_as_s = xcresult_paths_list.join(',')
        UI.success("Setting Environment variable #{shared_value_name} = #{xcresult_paths_list_as_s.to_s}")
        ENV[shared_value_name] = xcresult_paths_list_as_s

        return xcresult_paths_list
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

      # Downloads file from the given URL.
      # Params :
      # +url+:: download endpoint.
      # +username+:: username to access the URL.
      # +password+:: password to access the URL.
      # +user_agent+:: string that specifies the client app.
      # +file_path+:: path to place downloaded file.
      def self.download_file_from_url(url, username, password, user_agent, file_path)
        UI.message(url)
        UI.message(file_path)

        response = execute_request(url, "get", username, password, user_agent, payload = nil, expected_raw_response = true)

        if response.code == 200
          File.open(file_path, 'wb') do |file|
            file.write(response.body)
          end
          puts "File downloaded and saved to #{file_path}"
        else
          puts "Failed to download the file. Response status code: #{response.code}"
        end
      end

      # Executes the HTTP-request to the given URL.
      # Params :
      # +url+:: request endpoint.
      # +method+:: request method.
      # +username+:: username to access the URL.
      # +password+:: password to access the URL.
      # +user_agent+:: string that specifies the client app.
      # +payload+:: the hash with data to be posted.
      # +expected_raw_response+:: the flag indicating the need to download the file.
      def self.execute_request(
        url,
        method,
        username,
        password,
        user_agent,
        payload = nil,
        expected_raw_response = false
      )

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
            payload: payload,
            raw_response: expected_raw_response
          )

          return response if expected_raw_response

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
