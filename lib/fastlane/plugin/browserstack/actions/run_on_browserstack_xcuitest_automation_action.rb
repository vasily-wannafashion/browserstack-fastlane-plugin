require 'fastlane/action'
require_relative '../helper/browserstack_helper'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_XCUITEST_BUILD_ID ||= :BROWSERSTACK_XCUITEST_BUILD_ID
    end
    class RunOnBrowserstackXcuitestAutomationAction < Action
      UPLOAD_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/build"
      SHARED_VALUE_NAME = "BROWSERSTACK_XCUITEST_BUILD_ID"

      def self.run(params)
        config = params.values
        config[:shared_value_name] = SHARED_VALUE_NAME

        browserstack_xcuitest_build_id =
          Helper::BrowserstackHelper.run_xcuitest_on_browserstack(config, UPLOAD_API_ENDPOINT)

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_XCUITEST_BUILD_ID] = browserstack_xcuitest_build_id.to_s
      end

      def self.description
        "Launches XCUITest automation run on BrowserStack."
      end

      def self.authors
        ["Vasily Rudnevsky"]
      end

      def self.details
        "Launches XCUITest automation run on BrowserStack."
      end

      def self.output
        [
          ['BROWSERSTACK_XCUITEST_BUILD_ID', 'ID of launched automation run.']
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
          FastlaneCore::ConfigItem.new(key: :app_url,
                                       description: "BrowserStack's url of the app under testing",
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :test_suite_url,
                                       description: "BrowserStack's url of the test suite",
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :devices,
                                       description: "Array of the devices to launch XCUITest automation run on",
                                       optional: false,
                                       is_string: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("No devices given.") if value.to_s.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :only_testing,
                                       description: "Array of the tests to execute",
                                       optional: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :skip_testing,
                                       description: "Array of the tests to skip",
                                       optional: true,
                                       is_string: false),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.example_code
        [
          'run_on_browserstack_xcuitest_automation(
            browserstack_username: ENV["BROWSERSTACK_USERNAME"],
            browserstack_access_key: ENV["BROWSERSTACK_ACCESS_KEY"],
            app_url: ENV["BROWSERSTACK_APP_ID"],
            test_suite_url: ENV["BROWSERSTACK_TEST_SUITE_ID"],
            devices: ["iPhone 14-16"],
            only_testing: ["TestClass/testMethodToRun"],
            skip_testing: ["TestClass/testMethodToSkip"]
           )'
        ]
      end
    end
  end
end
