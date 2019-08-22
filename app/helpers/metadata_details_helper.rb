module MetadataDetailsHelper
  def css_class(value)
    return "missing" if value == "not configured"
    return "missing" if value.match?(/translation missing/)
  end
end
