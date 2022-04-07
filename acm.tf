resource "aws_acm_certificate" "cert" {
  provider          = aws.region_master
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  validation_method = "DNS"
  tags = {
    Name = "Jenkins-cert"
  }
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.region_master
  certificate_arn         = aws_acm_certificate.cert.arn
  for_each                = aws_route53_record.cert_validation
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}