check "public_mail_mx" {
  data "dns_mx_record_set" "mail" {
    domain = cloudflare_dns_record.protonmail_mx_primary.name
  }

  assert {
    condition = toset([
      for record in data.dns_mx_record_set.mail.mx :
      "${record.preference} ${lower(trimsuffix(record.exchange, "."))}"
      ]) == toset([
      for record in [cloudflare_dns_record.protonmail_mx_primary, cloudflare_dns_record.protonmail_mx_secondary] :
      "${record.priority} ${lower(trimsuffix(record.content, "."))}"
    ])
    error_message = "Public MX records do not match the configured Proton Mail servers and priorities."
  }
}

check "public_mail_spf" {
  data "dns_txt_record_set" "spf" {
    host = cloudflare_dns_record.spf.name
  }

  assert {
    condition = toset([
      for record in data.dns_txt_record_set.spf.records : record
      if startswith(lower(record), "v=spf1")
    ]) == toset([trim(cloudflare_dns_record.spf.content, "\"")])
    error_message = "Public DNS must publish exactly the configured SPF policy."
  }
}

check "public_mail_dmarc" {
  data "dns_txt_record_set" "dmarc" {
    host = cloudflare_dns_record.dmarc.name
  }

  assert {
    condition = toset([
      for record in data.dns_txt_record_set.dmarc.records : record
      if startswith(lower(record), "v=dmarc1")
    ]) == toset([trim(cloudflare_dns_record.dmarc.content, "\"")])
    error_message = "Public DNS must publish exactly the configured DMARC policy."
  }
}

check "public_mail_dkim_1" {
  data "dns_cname_record_set" "dkim_1" {
    host = cloudflare_dns_record.protonmail_dkim_1.name
  }

  assert {
    condition     = lower(trimsuffix(data.dns_cname_record_set.dkim_1.cname, ".")) == lower(trimsuffix(cloudflare_dns_record.protonmail_dkim_1.content, "."))
    error_message = "The first public DKIM alias does not match the configured Proton Mail target."
  }
}

check "public_mail_dkim_2" {
  data "dns_cname_record_set" "dkim_2" {
    host = cloudflare_dns_record.protonmail_dkim_2.name
  }

  assert {
    condition     = lower(trimsuffix(data.dns_cname_record_set.dkim_2.cname, ".")) == lower(trimsuffix(cloudflare_dns_record.protonmail_dkim_2.content, "."))
    error_message = "The second public DKIM alias does not match the configured Proton Mail target."
  }
}

check "public_mail_dkim_3" {
  data "dns_cname_record_set" "dkim_3" {
    host = cloudflare_dns_record.protonmail_dkim_3.name
  }

  assert {
    condition     = lower(trimsuffix(data.dns_cname_record_set.dkim_3.cname, ".")) == lower(trimsuffix(cloudflare_dns_record.protonmail_dkim_3.content, "."))
    error_message = "The third public DKIM alias does not match the configured Proton Mail target."
  }
}
