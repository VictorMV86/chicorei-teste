# chico-rei-teste
Teste Técnico
Configure AWS CLI: 
aws configure e adicione sua ID e Secret.
Adiciona sua chave ssh publica no key deployer.

Vou colar as partes do projeto para o exercicio referente. 
Há referencias para: tfvars.tf
1- resource "aws_default_vpc" "chicorei_vpc" {
    tags = {
        Name = "Default VPC"
    }
}

resource "aws_key_pair" "chicorei-key" {
  key_name   = "chicorei-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTTvG/7ldjFgyfwXF3EhYy21YQpuMmIVOSDE1xI4VG9 melo.victor86@gmail.com"
}

resource "aws_instance" "chico_rei_ec2" {
  ami           = "ami-04d88e4b4e0a5db46" 
  instance_type = var.instance_type
  count         = 2
  key_name      = aws_key_pair.chicorei-key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  user_data = file("user_data.sh")

  vpc_security_group_ids = [aws_security_group.ec2_sg.id,aws_security_group.allow_ssh_sg.id]

  tags = {
    Name = "instance-${count.index}"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "allow_ssh_sg" {
  name        = "allow_ssh-security-group"
  description = "Allow SSH and HTTP inbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "chicorei_s3" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "var.s3_bucket_name"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL inbound traffic from EC2"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "chicoreidb" {
  allocated_storage    = 10 
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = "chicoreidb"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true 

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "example-rds-instance"
  }
}

2- Adicionei as duas ec2 na mesma subrede, conectadas por um ALB. Como o exercicio não menciona nada sobre acesso externo, não conectei eles ao internet gateway. Utilizei a IaC lider do mercado, Terraform. Muito eficiente,de facil entendimento, com cloud próprio.

3 - Precisamos de alta disponibilidade, e recuperação de desastres. A estrategia poderia consistir em escolher uma região secundária para servir como backup. A AWS há varias serviços para isso, como Multi-AZ, replicação de ec2, de buckets, auto-scaling, etc.. Eu replicaria o RDS para uma região secundária, e usaria o Route s3 para redirecionar em caso de falha. Atualizaria o DNS com uma função Lambda que seria acionada com um alarme do Cloudwatch.

4 - resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2_cloudwatch_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2_cloudwatch_profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

Criei uma politica e um perfil para ser usado no Cloudwatch. As ec2 sao configuradas automaticamente ao serem criada, via script(user_data.sh)

5- Criei um projeto simples de node.js usando webpack e npm.Criei um workflow para acionar o github actions para criar a pipeline.

6- Eu criaria políticas de acesso, para definir as permissões dos usuários. 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::chico-rei-bucket",
        "arn:aws:s3:::chico-rei-bucket/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:userId": [
            "AROAEXEMPLOID123:*",  # IAM Role específica
            "AIDAEXEMPLOID456"     # IAM User específico
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/MinhaRoleAutorizada",
          "arn:aws:iam::123456789012:user/MeuUsuarioAutorizado"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::chico-rei-bucket",
        "arn:aws:s3:::chico-rei-bucket/*"
      ]
    }
  ]
}

7- Eu adotaria a estrategia de reduzir a carga do servidor usando uma CDZ. Seja o Cloudfront da Amazon, Cloudflare ou outro similar, eu os usaria para distribuir o conteúdo estático e reduzindo a latência.

8 - Primeiramente, analisaria a coleta de logs e métricas. Tentaria identificar o problemas também usando recursos do próprio AWS como X-Ray. Faria testes de reprodução em ambientes diferentes, e aplicaria a correção.

9 - EC2 é um serviço que fornece instancias virtuais. A boa e velha VM. Nos dá controle total no ambiente computacional, como sistema operacional, configurações de redes, etc..
Lambda é um serviço que executa um script diante de algo que aconteceu, como uma resposta. O seu principal fator é ser serverless.

10 -Principais exemplos na minha opinião é build/compilação do código, e execução de testes.
No primeiro exemplo, principal fator é eliminar erro humano na hora do build, e no segundo exemplo é garantir que o código novo não vá quebrar funções existente. Os benefícios sao inúmeros: Economia de tempo, redução de erros, escalabilidade, etc..

11- Trabalhei numa empresa de software próprio, com compra e venda de criptomoedas. Como nesse mercado o mais rapido que fizer a compra/venda importa muito, tivemos que incluir o Amazon Cloudfront para distribuir conteúdo estatico e dinâmico com latência baixa. Configuraçao foi confusa no início pois foi minha primeira vez com CDN. A plataforma de compra e venda de criptomoedas tinha uma interface web e APIs que precisavam ser acessadas com agilidade. O sistema era acessado por usuários globais, e a latência na entrega de conteúdo estático (como JavaScript, CSS e imagens) estava impactando negativamente a experiência do usuário. Além disso, as APIs precisavam responder rapidamente para garantir que as ordens fossem executadas o mais rápido possível.