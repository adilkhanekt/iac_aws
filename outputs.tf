output "vpc_master_id" {
  description = "ID of the master VPC"
  value       = aws_vpc.vpc_master.id
}

output "vpc_worker_id" {
  description = "ID of the worker VPC"
  value       = aws_vpc.vpc_worker.id
}

output "vpc_peering_id" {
  description = "ID of the VPC peering"
  value       = aws_vpc_peering_connection.useast1_uswest2.id
}

output "master_jenkins_instance_public_ip" {
  description = "Public IP of the master Jenkins instance"
  value       = aws_instance.jenkins_master.public_ip
}

output "worker_jenkins_instances_public_ip" {
  description = "Public IPs of the worker Jenkins instances"
  value = { for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}

output "lb_dns_name" {
  description = "DNS name of LB"
  value       = aws_lb.alb.dns_name
}

output "service_url" {
  description = "URL"
  value       = aws_route53_record.a_record.fqdn
}