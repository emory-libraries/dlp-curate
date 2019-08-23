class LogFormatter
  def call(severity, time, progname, msg = '')
    return '' if msg.blank?

    return "timestamp='#{time}' level=#{severity} progname='#{progname}' message='#{msg}'}\n" if progname.present?

    "timestamp='#{time}' level=#{severity} message='#{msg}'\n"
  end
end
