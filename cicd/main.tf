module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-09ebad62096ad78b0"] #replace your SG
  subnet_id = "subnet-0ee5e97fb770a7bdc" #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t2.medium"
  vpc_security_group_ids = ["sg-09ebad62096ad78b0"]
  # convert StringList to list and get first element
  subnet_id = "subnet-0ee5e97fb770a7bdc"
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_key_pair" "tools" {
  key_name   = "tools"
  # you can paste the public key directly like this
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGxdOeeDphX2dwYkQL6lLp8gWFDbm0ZZpJPEAs+LSTp8H/nPTaGi4NAzYL8LOU608dCkaaA5/p7qPY9JLNhrys+ToGfdJZPVFmAVRfmCxDJOZzuZh1iqq4SkRjcjujwyBrZNcnKB3VhfRvbGtizPV4atnq16VJ74zpB0PWwODnBtTSrzs7XWTiDi6WFujZXXcBFheH/OOCs787cpQ4v/bNqqroIVzaFiu0Zd+a8z8dKnJkQ9dMh2YblQNFMarBJ9/yHsKUgA0OZsWSRxEQrPG9iLGZzPV1Fa8eWOp9LobNWNebJAQmaSGd1inBdGYinJE/ugjgLMg/pZ5qxTKvlORfv05Mcv/1gK1TFCmbeTIJH82X9NjvUYUfjN710Ydck4kV/39mCpiaSPO8ldX/BMu2Ee+8aeyCEuQtkhfGSfN72tXMBWEzxOuiCu+mKK8tVfHH26OQp+Yo+AHWSLhdK/0CkA1KhTc/qmLn8lw7CXWobSIZUQIrilug2Tjyn4g8nO0T1bQV3hhSDg2TkrWlwuSRrwFpi1F/PatCU2u9bhWSD8JhQeuqB3vM0AQD1QMZgE7zM3yDviUOTl7DVwHtIDSSx+0Iya8NYTL9n/z+sZKAqAk8fG8R6MdoB3JML3ylbByhWIcl0FzUqZW6CZ/4Wnde1wzmqgQf7BbddB6j2M2leQ== USER@DESKTOP-6JUN8UM"

  #public_key = file("/c/devops-78s/devops-78s.pub")
  # ~ means windows home directory
}

module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t2.medium"
  vpc_security_group_ids = ["sg-09ebad62096ad78b0"]
  # convert StringList to list and get first element
  subnet_id = "subnet-0ee5e97fb770a7bdc"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      records = [
        module.nexus.private_ip
      ]
    }
  ]

}