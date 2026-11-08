# Домашнє завдання: Terraform-інфраструктура AWS

Проєкт у директорії `lesson-5` описує інфраструктуру AWS у регіоні `us-west-2`: S3 backend для Terraform state, DynamoDB для блокування, VPC із шістьма підмережами та ECR для Docker images.

## Реалізація вимог

| Вимога | Реалізація |
| --- | --- |
| Збереження state у S3 | Backend із ключем `lesson-5/terraform.tfstate` та `encrypt = true`. |
| Історія state | Версіонування S3-бакета ввімкнене; ownership — `BucketOwnerEnforced`. |
| Блокування state | DynamoDB table `terraform-locks`, partition key `LockID` типу `S`, billing mode `PAY_PER_REQUEST`. |
| Мережа | VPC `10.0.0.0/16`, DNS support і DNS hostnames увімкнені. |
| Підмережі | 3 public і 3 private subnets у трьох Availability Zones. |
| Публічна маршрутизація | Internet Gateway, public route table і маршрут `0.0.0.0/0` через IGW. |
| Приватна маршрутизація | Один NAT Gateway із Elastic IP, private route table і маршрут `0.0.0.0/0` через NAT. |
| Container registry | ECR repository `lesson-5-ecr` із `scan_on_push = true` та repository policy для push/pull. |
| Вихідні дані | Root outputs виводять S3 URL, назву DynamoDB, ID мережевих ресурсів і ECR URL. |

## Структура проєкту

```text
lesson-5/
├── main.tf                 # Підключення трьох модулів
├── providers.tf            # AWS provider і регіон
├── variables.tf            # Обов'язкова змінна bucket_name
├── backend.tf              # S3 backend і DynamoDB locking
├── outputs.tf              # Загальні вихідні дані
├── .terraform.lock.hcl      # Зафіксована версія provider та checksums
├── README.md
└── modules/
    ├── s3-backend/
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecr/
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

### Модулі та прийняті рішення

**`s3-backend`** створює S3-бакет і DynamoDB table. Активний backend посилається на bucket `goit-tfstate-412930559924-lesson-5`. Його назва передається модулю через `bucket_name`, а в backend записана явно: backend не підтримує посилання на input variables. DynamoDB locking збережено за вимогою завдання, хоча цей спосіб позначений як deprecated у [документації HashiCorp](https://developer.hashicorp.com/terraform/language/backend/s3).

**`vpc`** створює мережу та маршрутизацію. Підмережі розподілено так:

| Availability Zone | Public subnet | Private subnet |
| --- | --- | --- |
| `us-west-2a` | `10.0.1.0/24` | `10.0.4.0/24` |
| `us-west-2b` | `10.0.2.0/24` | `10.0.5.0/24` |
| `us-west-2c` | `10.0.3.0/24` | `10.0.6.0/24` |

Public subnets прив'язані до public route table; автоматичне призначення public IPv4 для запущених у них instances увімкнене. Private subnets прив'язані до private route table. Один NAT Gateway розміщений у першій public subnet і забезпечує вихідний доступ для всіх private subnets. Це спрощений навчальний варіант без multi-AZ high availability. Значення `vpc_name = "vpc"` збережено з попереднього етапу; Name tag VPC — `vpc-vpc`.

**`ecr`** створює repository з автоматичним скануванням після push. Repository policy явно надає push/pull permissions IAM user `arn:aws:iam::412930559924:user/terraform-student`. Список дій обмежено отриманням і завантаженням образів. Інші IAM policies також можуть надавати доступ; repository policy не забороняє адміністративний доступ через них. `force_delete` не ввімкнений: repository з образами перед видаленням потрібно очистити.

## Передумови запуску

- Terraform CLI сумісний із `>= 1.0, < 2.0`; для використаного способу `aws login` у цьому проєкті застосовується Terraform CLI `1.17.1`.
- AWS CLI із підтримкою `aws login`, налаштований profile `goit` та чинна login session.
- AWS provider `>= 6.23.0, < 7.0.0`; конкретну версію фіксує `.terraform.lock.hcl`.
- Доступ до AWS account `412930559924` і регіону `us-west-2`.

Для запуску в іншому account необхідно змінити bucket name у `backend.tf` і значення `TF_VAR_bucket_name`, а також `allowed_principal_arn` у блоці ECR у `main.tf`. Назва S3-бакета має бути глобально унікальною. Наявні ресурси іншого account не переносяться автоматично.

### IAM permissions

Для навчального IAM user `terraform-student` використовується такий набір AWS managed policies:

| Policy | Призначення |
| --- | --- |
| [AmazonS3FullAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonS3FullAccess.html) | Керування bucket, версіонуванням, ownership controls і state objects. |
| [AmazonDynamoDBFullAccess_v2](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonDynamoDBFullAccess_v2.html) | Керування таблицею та записами блокування state. |
| [AmazonVPCFullAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonVPCFullAccess.html) | Керування VPC, subnets, IGW, NAT Gateway, EIP і маршрутизацією. |
| [AmazonEC2ContainerRegistryFullAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEC2ContainerRegistryFullAccess.html) | Керування ECR repository, scanning, repository policy, Docker login і push/pull. |
| [SignInLocalDevelopmentAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/SignInLocalDevelopmentAccess.html) | Отримання тимчасових credentials через `aws login`. |

Policies призначає адміністратор через **IAM → Users → terraform-student → Permissions → Add permissions → Attach policies directly**. Terraform-код проєкту не створює IAM user і не призначає ці policies. Це широкі дозволи для навчального account; `AdministratorAccess` не потрібна. Permissions boundary, SCP та explicit deny можуть додатково обмежувати доступ.

Додатково потрібна inline policy `TerraformEipReadAttributes`: AWS provider читає атрибути EIP через `ec2:DescribeAddressesAttribute`, якої немає в наведеній версії `AmazonVPCFullAccess` (вона містить окрему дію `ec2:DescribeAddresses`). Без цього дозволу можливий `403 UnauthorizedOperation` під час обробки `module.vpc.aws_eip.nat`.

Адміністратор додає policy через **IAM → Users → terraform-student → Permissions → Add permissions → Create inline policy → JSON**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadElasticIpAttributes",
      "Effect": "Allow",
      "Action": "ec2:DescribeAddressesAttribute",
      "Resource": "*"
    }
  ]
}
```

Після збереження permissions повторіть `terraform plan`, перевірте залишкові зміни й виконайте `terraform apply`. Попередній невдалий `apply` міг уже створити частину ресурсів; не видаляйте state чи EIP для повторного запуску.

`ecr:GetAuthorizationToken` для Docker login входить до `AmazonEC2ContainerRegistryFullAccess`; цю дію не додають до repository policy. IAM permissions для створення repository та його policy потрібні ще до `apply`. [Документація ECR permissions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html).

## Порядок запуску

Команди виконуються з кореня `lesson-5`. Credentials не записуються у Terraform-файли.

### 1. Автентифікація

```bash
aws login --profile goit --region us-west-2
export AWS_PROFILE="goit"
export TF_VAR_bucket_name="goit-tfstate-412930559924-lesson-5"
aws sts get-caller-identity
```

Перевірте account та ARN користувача. Якщо login session закінчилася, повторіть `aws login`.

### 2. Backend

Для звичайного запуску bucket і таблиця вже мають існувати. `backend.tf` у репозиторії ввімкнений; не коментуйте його, якщо актуальний state уже зберігається в S3.

Для першого розгортання в новому account:

1. Тимчасово закоментуйте S3 backend у `backend.tf`.
2. Виконайте `terraform init`, перегляньте `terraform plan -target=module.s3_backend` і створіть лише backend resources командою `terraform apply -target=module.s3_backend`.
3. Збережіть копію локального `terraform.tfstate` поза репозиторієм.
4. Увімкніть S3 backend із назвою створеного bucket і виконайте `terraform init -migrate-state`, підтвердивши копіювання state.
5. Перевірте state object у S3 перед переходом до повного плану.

Targeting тут потрібен лише для початкового створення backend. При першому підключенні S3 після стандартного локального state звичайний `terraform init` також може запропонувати перенесення. Параметр `-migrate-state` явно задає намір міграції; `-reconfigure` його не замінює. [Документація init](https://developer.hashicorp.com/terraform/cli/commands/init).

### 3. Перевірка та застосування

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Перед підтвердженням `yes` перевірте запропоновані зміни. Для вже створених S3/DynamoDB/VPC доповнення має додати NAT/EIP, приватну маршрутизацію та ECR без заміни наявних ресурсів. Фактичний план залежить від поточного state.

