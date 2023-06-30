require 'fastlane/action'
require_relative '../helper/browserstack_helper'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_XCTEST_STATUS ||= :BROWSERSTACK_XCTEST_STATUS
    end
    class CheckOnBrowserstackXctestAutomationStatusAction < Action
      REQUEST_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/{build_id}"
      SHARED_VALUE_NAME = "BROWSERSTACK_XCTEST_STATUS"

      def self.run(params)
        config = params.values
        config[:shared_value_name] = SHARED_VALUE_NAME

        concrete_build_api_endpoint = REQUEST_API_ENDPOINT
                                        .gsub!("{build_id}", params[:xctest_build_id])

        browserstack_xctest_status =
          Helper::BrowserstackHelper.check_xctest_automation_status(config, concrete_build_api_endpoint)

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_XCTEST_STATUS] = browserstack_xctest_status.to_s
      end

      def self.description
        "Checks XCTest automation run status on BrowserStack."
      end

      def self.authors
        ["Vasily Rudnevsky"]
      end

      def self.details
        "Checks XCTest automation run status on BrowserStack."
      end

      def self.output
        [
          ['BROWSERSTACK_XCTEST_STATUS', 'Status of automation run.']
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
          FastlaneCore::ConfigItem.new(key: :xctest_build_id,
                                       description: "BrowserStack's ID of automation run",
                                       optional: false,
                                       is_string: true),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.example_code
        [
          'check_on_browserstack_xctest_automation_status(
            browserstack_username: ENV["BROWSERSTACK_USERNAME"],
            browserstack_access_key: ENV["BROWSERSTACK_ACCESS_KEY"],
            xctest_build_id: ENV["BROWSERSTACK_XCTEST_BUILD_ID"]
           )'
        ]
      end
    end
  end
end
