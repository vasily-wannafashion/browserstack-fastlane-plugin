require 'fastlane/action'
require_relative '../helper/browserstack_helper'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_TEST_SUITE_ID ||= :BROWSERSTACK_TEST_SUITE_ID
    end
    class UploadToBrowserstackTestSuiteAutomateAction < Action
      SUPPORTED_FILE_EXTENSIONS = ["zip"]
      UPLOAD_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/test-suite"

      ARTIFACT_TYPE = "test suite"
      BS_PRODUCT_TYPE = "AppAutomate"
      SHARED_VALUE_NAME = "BROWSERSTACK_TEST_SUITE_ID"

      def self.run(params)
        args = params.values
        args[:artifact_type] = ARTIFACT_TYPE
        args[:bs_product_type] = BS_PRODUCT_TYPE
        args[:shared_value_name] = SHARED_VALUE_NAME
        args[:supported_file_extensions] = SUPPORTED_FILE_EXTENSIONS
        args[:upload_api_endpoint] = UPLOAD_API_ENDPOINT

        browserstack_test_suite_id = Helper::BrowserstackHelper.upload_file_to_browserstack(args)

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_TEST_SUITE_ID] = browserstack_test_suite_id.to_s
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
