# frozen_string_literal: true

##
# This is used on a Work that does not already have members.
#
# Pass in the Work and the FileSet and put the logic for
# their arrangement/oredering in the arrange method.
#
# This is intended to be used in the FileSetActor in the
# attach_to_work method to ensure that importer files are
# not attached in random order.
class FileArranger
  def initialize(work:, file_set:)
    @work = work
    @file_set = file_set
  end

  def arrange
    case @file_set.title.first
    when 'Front'
      @work.ordered_members.insert_at(0, @file_set)
      # Front or the first item should always be the
      # thumbnail
      @work.representative = @file_set
      @work.thumbnail = @file_set
    when 'Back'
      # There may not be a Front so make the Back first
      if @work.ordered_members.to_a.empty?
        @work.ordered_members.insert_at(0, @file_set)
      else
        @work.ordered_members.insert_at(1, @file_set)
      end
    else
      @work.ordered_members << @file_set
    end
  end
end
