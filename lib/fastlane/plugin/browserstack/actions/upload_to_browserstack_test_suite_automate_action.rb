require 'fastlane/action'
require_relative '../helper/browserstack_helper'
require 'json'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_TEST_SUITE_ID ||= :BROWSERSTACK_TEST_SUITE_ID
    end
    class UploadToBrowserstackTestSuiteAutomateAction < Action
      SUPPORTED_FILE_EXTENSIONS = ["zip"]
      UPLOAD_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/test-suite"

      def self.run(params)
        browserstack_username = params[:browserstack_username] # Required
        browserstack_access_key = params[:browserstack_access_key] # Required
        custom_id = params[:custom_id]
        file_path = params[:file_path].to_s # Required

        validate_file_path(file_path)

        UI.message("Uploading test suite to BrowserStack AppAutomate...")
        browserstack_test_suite_id = Helper::BrowserstackHelper.upload_file(browserstack_username, browserstack_access_key, file_path, UPLOAD_API_ENDPOINT, custom_id)
        UI.success("Successfully uploaded file " + file_path + " to BrowserStack AppAutomate with bs_url : " + browserstack_test_suite_id.to_s)

        UI.success("Setting Environment variable BROWSERSTACK_TEST_SUITE_ID = " + browserstack_test_suite_id.to_s)
        # Set 'BROWSERSTACK_TEST_SUITE_ID' environment variable, if app upload was successful.
        ENV['BROWSERSTACK_TEST_SUITE_ID'] = browserstack_test_suite_id

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_TEST_SUITE_ID] = browserstack_test_suite_id.to_s
      end

      # Validate file_path.
      def self.validate_file_path(file_path)
        UI.user_error!("No file found at '#{file_path}'.") unless File.exist?(file_path)

        # Validate file extension.
        file_path_parts = file_path.split(".")
        unless file_path_parts.length > 1 && SUPPORTED_FILE_EXTENSIONS.include?(file_path_parts.last)
          UI.user_error!("file_path is invalid, only files with extensions " + SUPPORTED_FILE_EXTENSIONS.to_s + " are allowed to be uploaded.")
        end
      end

      def self.description
        "Uploads archived XCTest-runner to BrowserStack AppAutomate for running automated tests."
      end

      def self.authors
        ["Vasily Rudnevsky"]
      end

      def self.details
        "Uploads archived XCTest-runner to BrowserStack AppAutomate for running automated tests."
      end

      def self.output
        [
          ['BROWSERSTACK_TEST_SUITE_ID', 'ID of uploaded file.']
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :browserstack_username,
                                       description: "BrowserStack's username",
                                       optional: false,
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No browserstack_username given.") if value.to_s.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :browserstack_access_key,
                                       description: "BrowserStack's access key",
                                       optional: false,
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No browserstack_access_key given.") if value.to_s.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :custom_id,
                                       description: "Custom id",
                                       optional: true,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       description: "Path to the zip file",
                                       optional: false,
                                       is_string: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.example_code
        [
          'upload_to_browserstack_test_suite_automate(
            browserstack_username: ENV["BROWSERSTACK_USERNAME"],
            browserstack_access_key: ENV["BROWSERSTACK_ACCESS_KEY"],
            file_path: "path_to_zip_file"
           )'
        ]
      end
    end
  end
end
