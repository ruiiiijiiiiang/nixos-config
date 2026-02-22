/* yaml */ ''
  directives:
  default-src:
    - "'self'"
  script-src:
    - "'self'"
    - "'unsafe-inline'"
    - "'unsafe-eval'"
    - "blob:"
  style-src:
    - "'self'"
    - "'unsafe-inline'"
  img-src:
    - "'self'"
    - "data:"
    - "blob:"
    - "https://avatar.opencloud.eu"
  font-src:
    - "'self'"
    - "data:"
  connect-src:
    - "'self'"
    - "blob:"
    - "https://@OFFICE_FQDN@"
    - "https://@ID_FQDN@"
    - "wss://@ID_FQDN@"
  frame-src:
    - "'self'"
    - "blob:"
    - "https://embed.diagrams.net/"
    - "https://@OFFICE_FQDN@"
  frame-ancestors:
    - "'self'"
    - "https://@OFFICE_FQDN@"
  object-src:
    - "'self'"
  base-uri:
    - "'self'"
  form-action:
    - "'self'"
    - "https://@OFFICE_FQDN@"
''
