module Hyrax
  module Actors
    class FilesActor
      attr_reader :file_set, :user

      def initialize(file_set, user)
        @file_set = file_set
        @user = user
      end

      def create_content(file, relation = :original_file)
        IngestJob.perform_now(wrapper!(file: file, relation: relation))
      end

      private

        def wrapper!(file:, relation:)
          JobIoWrapper.create_with_varied_file_handling!(user: user, file: file, relation: relation, file_set: file_set)
        end
    end
  end
end
