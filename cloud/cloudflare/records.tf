resource "cloudflare_dns_record" "ics" {
  content = "alias.deno.net"
  name    = "ics.ruijiang.me"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "protonmail_dkim_2" {
  content = "protonmail2.domainkey.dyhk7rtmhiutup63mle4yw3jcjybsa63cns3envuqplwmgjvrmr2q.domains.proton.ch"
  name    = "protonmail2._domainkey.ruijiang.me"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "protonmail_dkim_3" {
  content = "protonmail3.domainkey.dyhk7rtmhiutup63mle4yw3jcjybsa63cns3envuqplwmgjvrmr2q.domains.proton.ch"
  name    = "protonmail3._domainkey.ruijiang.me"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "protonmail_dkim_1" {
  content = "protonmail.domainkey.dyhk7rtmhiutup63mle4yw3jcjybsa63cns3envuqplwmgjvrmr2q.domains.proton.ch"
  name    = "protonmail._domainkey.ruijiang.me"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "protonmail_mx_primary" {
  content  = "mail.protonmail.ch"
  name     = "ruijiang.me"
  priority = 10
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "MX"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}

resource "cloudflare_dns_record" "protonmail_mx_secondary" {
  content  = "mailsec.protonmail.ch"
  name     = "ruijiang.me"
  priority = 20
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "MX"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}

resource "cloudflare_dns_record" "dmarc" {
  content  = "\"v=DMARC1; p=quarantine\""
  name     = "_dmarc.ruijiang.me"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}

resource "cloudflare_dns_record" "google_site_verification" {
  content  = "\"google-site-verification=4JtDqBM2hydywVsJh8j0RoOREKzHUnYuNZA1STkz5Gc\""
  name     = "ruijiang.me"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}

resource "cloudflare_dns_record" "protonmail_verification" {
  content  = "\"protonmail-verification=f448656d2dad0d1669696a3bb68f86963880edd0\""
  name     = "ruijiang.me"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}

resource "cloudflare_dns_record" "spf" {
  content  = "\"v=spf1 include:_spf.protonmail.ch ~all\""
  name     = "ruijiang.me"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = var.cloudflare_zone_id
  settings = {}
}
