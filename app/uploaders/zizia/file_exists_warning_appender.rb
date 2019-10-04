module Zizia
  class FileExistsWarningAppender < WarningAppender
    attr_accessor :index, :filepath
    def initialize(index:, filepath:, warnings:)
      @index = index
      @filepath = filepath
      @warnings = warnings
    end

    def check
      warnings << message unless condition
    end

    private

      def message
        "row #{@index + 1}: Unable to find #{filepath}"
      end

      def condition
        File.exist?(filepath)
      end
  end
end
