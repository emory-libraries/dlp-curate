Hydra::Works.default_system_virus_scanner = ::ClambyScanner

if Rails.env.production?
  Clamby.configure(
    check: false, # only used for development environment
    config_file: '/etc/clamd.d/scan.conf',
    daemonize: true,
    error_clamscan_missing: true,
    error_file_missing: true,
    error_file_virus: true,
    fdpass: true
  )
end
