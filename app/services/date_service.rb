# frozen_string_literal: true

class DateService
  include Singleton

  def human_readable_date(date)
    if date == "XXXX"
      "unknown"
    elsif date.include?("\/")
      handle_date_range(date)
    elsif date.include?("-")
      handle_ymd_format(date)
    elsif date.end_with?("X")
      handle_unspecified_digit(date)
    elsif date.end_with?("?")
      handle_uncertain_year(date)
    else
      date
    end
  end

  def handle_date_range(date)
    years = date.split("\/")
    return date if years.length > 2
    return "within the #{handle_unspecified_digit(years[0])} or #{handle_unspecified_digit(years[1])}" if date.end_with?("X")
    return "between #{years[0].tr('?', '')} and #{years[1].tr('?', '')}" if date.end_with?("?")
    return Date.edtf(date).humanize unless Date.edtf(date).nil?
    date
  end

  def handle_ymd_format(date)
    date_units = date.split("-")
    return handle_ym_format(date) if date_units.length == 2
    return Date.edtf(date).humanize unless date.start_with?("X") || Date.edtf(date).nil?
    # The edtf-humanize gem expects a valid 4-digit year when handling dates in YMD format
    placeholder_date = Date.edtf("0000-#{date_units[1]}-#{date_units[2]}")
    return placeholder_date.humanize[/[^,]+/] + ", year unknown" unless placeholder_date.nil?
    date
  end

  def handle_ym_format(date)
    if date.end_with?("~")
      placeholder_date = Date.edtf(date.tr("~", ""))
      return placeholder_date.humanize + " approx." unless placeholder_date.nil?
    end
    return Date.edtf(date).humanize unless Date.edtf(date).nil?
    date
  end

  def handle_unspecified_digit(date)
    date.gsub("X", "0s")
  end

  def handle_uncertain_year(date)
    date.gsub("?", " approx.")
  end
end
