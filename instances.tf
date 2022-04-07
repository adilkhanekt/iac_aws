data "aws_ssm_parameter" "ubuntu_ami" {
  provider = aws.region_master
  name     = "/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_ssm_parameter" "ubuntu_ami_oregon" {
  provider = aws.region_worker
  name     = "/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_key_pair" "master_key" {
  provider   = aws.region_master
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_key_pair" "worker_key" {
  provider   = aws.region_worker
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "jenkins_master" {
  provider                    = aws.region_master
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.master_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.subnet_1.id
  tags = {
    Name = "jenkins_master"
  }
  depends_on = [aws_main_route_table_association.set_master_default_rt_association]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_master} --instance-ids ${self.id} && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ./ansible_templates/install_jenkins.yaml"
  }
}

resource "aws_instance" "jenkins_worker" {
  provider                    = aws.region_worker
  count                       = var.workers_count
  ami                         = data.aws_ssm_parameter.ubuntu_ami_oregon.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.worker_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_oregon.id]
  subnet_id                   = aws_subnet.subnet_1_oregon.id
  tags = {
    Name = join("_", ["jenkins_worker", count.index + 1])
    ip   = aws_instance.jenkins_master.private_ip
  }
  depends_on = [aws_main_route_table_association.set_worker_default_rt_association, aws_instance.jenkins_master]

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "java -jar /home/ubuntu/jenkins-cli.jar -auth @/home/ubuntu/jenkins_auth -s http://${self.tags.ip}:8080 -auth @/home/ubuntu/jenkins_auth delete-node ${self.private_ip}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_worker} --instance-ids ${self.id} && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${aws_instance.jenkins_master.private_ip}' ./ansible_templates/install_worker.yaml"
  }
}