data "aws_route53_zone" "dns" {
  provider = aws.region_master
  name     = var.dns_name
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.region_master
  for_each = {
    for val in aws_acm_certificate.cert.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.dns.zone_id
}

resource "aws_route53_record" "a_record" {
  provider = aws.region_master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  type     = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}