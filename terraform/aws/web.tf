data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content = templatefile(var.site_installer_file, {
      ssh_public_key = tls_private_key.emonstack_ssh.public_key_openssh
      admin_user     = var.admin_user
    })
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
locals {
  aznames = data.aws_availability_zones.available.names
}

#create EC2 instance
resource "aws_instance" "emonstack_web_instance" {
  availability_zone = local.aznames[0]
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t3.micro"
  key_name          = "emonstack-key"
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
  }
  # make sure you have your_private_ket.pem file
  vpc_security_group_ids = [
  aws_security_group.web_security_group.id]
  subnet_id = aws_subnet.emonstack_vpc_public_subnet.id
  tags = {
    Name = "emonstack_web_instance-${local.aznames[0]}"
  }
  volume_tags = {
    Name = "emonstack_web_instance_volume-${local.aznames[0]}"
  }
  user_data_base64 = data.cloudinit_config.config.rendered
}


# create security group for web
resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.emonstack_vpc.id
  tags = {
    Name = "emonstack_vpc_web_security_group"
  }
}

# create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
  count    = length(var.web_ports)
  type     = "ingress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}

# create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
  count    = length(var.web_ports)
  type     = "egress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}
