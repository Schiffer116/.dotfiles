# aws-dev: one NixOS instance in the default VPC. Terraform owns the AWS side only;
# everything inside the box comes from the flake (nix/hosts/aws-dev), deployed on the box.

data "aws_vpc" "default" {
  default = true
}

# The default VPC has no subnet in a Local Zone; its main route table already routes to the IGW.
resource "aws_subnet" "dev" {
  vpc_id                  = data.aws_vpc.default.id
  availability_zone       = var.zone
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # egress and Tailscale's direct path; no Elastic IP (billed while stopped)

  tags = { Name = "aws-dev" }
}

# Official NixOS AMIs (https://nixos.github.io/amis/). Only the first boot uses it;
# ignore_changes below keeps a newer AMI from replacing the instance.
data "aws_ami" "nixos" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/26.05*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# No inbound TCP: access is Tailscale (UDP below) with SSM Session Manager as break-glass.
resource "aws_security_group" "dev" {
  name        = "aws-dev"
  description = "aws-dev: Tailscale direct path only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Tailscale direct path (WireGuard, authenticated)"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.bootstrap_ssh_cidr == null ? [] : [var.bootstrap_ssh_cidr]
    content {
      description = "bootstrap SSH; remove once Tailscale works"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aws-dev" }
}

# SSM agent (enabled by NixOS's amazon-image.nix) needs this to register.
resource "aws_iam_role" "dev" {
  name = "aws-dev"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.dev.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "dev" {
  name = "aws-dev"
  role = aws_iam_role.dev.name
}

resource "aws_key_pair" "bootstrap" {
  count      = var.bootstrap_public_key == null ? 0 : 1
  key_name   = "aws-dev-bootstrap"
  public_key = var.bootstrap_public_key
}

resource "aws_instance" "dev" {
  ami                    = data.aws_ami.nixos.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.dev.id
  vpc_security_group_ids = [aws_security_group.dev.id]
  iam_instance_profile   = aws_iam_instance_profile.dev.name
  key_name               = try(aws_key_pair.bootstrap[0].key_name, null)

  # The idle-stop timer on the box (nix/hosts/aws-dev/idle-stop.nix) powers off;
  # this turns that into an EC2 stop, keeping the volume. scripts/devbox.sh start resumes.
  instance_initiated_shutdown_behavior = "stop"

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
  }

  lifecycle {
    # NixOS updates in place (nixos-rebuild on the box). The key pair only matters on
    # first boot, so dropping it later must not replace the instance either.
    ignore_changes = [ami, key_name]
  }

  tags = { Name = "aws-dev" }
}
