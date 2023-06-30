require 'fastlane/action'
require_relative '../helper/browserstack_helper'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_XCTEST_SESSIONS_LIST ||= :BROWSERSTACK_XCTEST_SESSIONS_LIST
    end
    class GetFromBrowserstackXctestSessionsListAction < Action
      REQUEST_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/{build_id}"
      SHARED_VALUE_NAME = "BROWSERSTACK_XCTEST_SESSIONS_LIST"

      def self.run(params)
        config = params.values
        config[:shared_value_name] = SHARED_VALUE_NAME

        concrete_build_api_endpoint = REQUEST_API_ENDPOINT
                                        .gsub!("{build_id}", params[:xctest_build_id])

        browserstack_xctest_sessions_list =
          Helper::BrowserstackHelper.get_xctest_sessions_list(config, concrete_build_api_endpoint)

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_XCTEST_STATUS] = browserstack_xctest_sessions_list.to_s
      end

      def self.description
        "Gets XCTest automation sessions list from BrowserStack."
      end

      def self.authors
        ["Vasily Rudnevsky"]
      end

      def self.details
        "Gets XCTest automation sessions list from BrowserStack."
      end

      def self.output
        [
          ['BROWSERSTACK_XCTEST_SESSIONS_LIST', 'Sessions list.']
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
          'get_from_browserstack_xctest_sessions_list(
            browserstack_username: ENV["BROWSERSTACK_USERNAME"],
            browserstack_access_key: ENV["BROWSERSTACK_ACCESS_KEY"],
            xctest_build_id: ENV["BROWSERSTACK_XCTEST_BUILD_ID"]
           )'
        ]
      end
    end
  end
end
