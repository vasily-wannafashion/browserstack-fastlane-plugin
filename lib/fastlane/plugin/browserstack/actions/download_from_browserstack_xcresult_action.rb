require 'fastlane/action'
require_relative '../helper/browserstack_helper'

module Fastlane
  module Actions
    module SharedValues
      BROWSERSTACK_XCRESULT_PATHS_LIST ||= :BROWSERSTACK_XCRESULT_PATHS_LIST
    end
    class DownloadFromBrowserstackXcresultAction < Action
      REQUEST_API_ENDPOINT = "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/{build_id}/sessions/{session_id}/resultbundle"
      SHARED_VALUE_NAME = "BROWSERSTACK_XCRESULT_PATHS_LIST"

      def self.run(params)
        config = params.values
        config[:shared_value_name] = SHARED_VALUE_NAME

        config[:build_id_key] = "{build_id}"
        config[:session_id_key] = "{session_id}"

        browserstack_xcresult_paths_list =
          Helper::BrowserstackHelper.download_xcresult_files(config, REQUEST_API_ENDPOINT)

        # Setting app id in SharedValues, which can be used by other fastlane actions.
        Actions.lane_context[SharedValues::BROWSERSTACK_XCRESULT_PATHS_LIST] = browserstack_xcresult_paths_list.to_s
      end

      def self.description
        "Downloads XCResult file (result bundle) from BrowserStack."
      end

      def self.authors
        ["Vasily Rudnevsky"]
      end

      def self.details
        "Downloads XCResult file (result bundle) from BrowserStack."
      end

      def self.output
        [
          ['BROWSERSTACK_XCRESULT_PATHS_LIST', 'Paths to XCResult files list.']
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
          FastlaneCore::ConfigItem.new(key: :xctest_sessions_list,
                                       description: "BrowserStack's IDs of automation sessions",
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :dir_path,
                                       description: "Path to the directory to save the files",
                                       optional: false,
                                       is_string: true),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.example_code
        [
          'download_from_browserstack_xcresult_action(
            browserstack_username: ENV["BROWSERSTACK_USERNAME"],
            browserstack_access_key: ENV["BROWSERSTACK_ACCESS_KEY"],
            xctest_build_id: ENV["BROWSERSTACK_XCTEST_BUILD_ID"],
            xctest_sessions_list: ENV["BROWSERSTACK_XCTEST_SESSIONS_LIST"],
            dir_path: "path_to_dir_to_save_files"
           )'
        ]
      end
    end
  end
end
