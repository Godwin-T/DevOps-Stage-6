locals {
  common_tags = merge({
    Project = "devops-stage6"
  }, var.tags)
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "app" {
  key_name   = "devops-stage6-${var.base_domain}"
  public_key = var.ssh_public_key
  tags       = local.common_tags
}

resource "aws_security_group" "app" {
  name        = "devops-stage6-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = aws_key_pair.app.key_name
  associate_public_ip_address = true
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "devops-stage6-app"
  })
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id
  tags     = local.common_tags
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    public_ip            = aws_eip.app.public_ip
    ansible_user         = var.ansible_user
    ssh_private_key_path = var.ssh_private_key_path
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}

resource "local_file" "ansible_extra_vars" {
  content = jsonencode({
    app_repo_url       = var.app_repo_url
    app_repo_version   = var.app_repo_version
    base_domain        = var.base_domain
    api_base_path      = var.api_base_path
    traefik_acme_email = var.traefik_acme_email
    zipkin_subdomain   = var.zipkin_subdomain
    auth_jwt_secret    = var.auth_jwt_secret
    todos_jwt_secret   = var.todos_jwt_secret
    users_jwt_secret   = var.users_jwt_secret
    redis_host         = var.redis_host
    redis_port         = var.redis_port
    redis_channel      = var.redis_channel
    zipkin_url         = var.zipkin_url
  })
  filename = "${path.module}/../ansible/inventory/extra-vars.json"
}

resource "null_resource" "ansible_deploy" {
  triggers = {
    instance_id  = aws_instance.app.id
    repo_version = var.app_repo_version
  }

  depends_on = [local_file.ansible_inventory, local_file.ansible_extra_vars]

  provisioner "local-exec" {
    working_dir = path.module
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = <<EOT
ansible-playbook \
  -i ../ansible/inventory/hosts.ini \
  ../ansible/site.yml \
  --extra-vars @../ansible/inventory/extra-vars.json
EOT
  }
}
