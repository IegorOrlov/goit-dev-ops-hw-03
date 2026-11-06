# Terraform: S3 backend і DynamoDB

Проєкт створює S3-бакет із версіонуванням та таблицю DynamoDB для блокування Terraform state у регіоні `us-west-2`.

## Структура

```text
lesson-5/
├── main.tf
├── providers.tf
├── variables.tf
├── backend.tf
├── outputs.tf
└── modules/s3-backend/
    ├── s3.tf
    ├── dynamodb.tf
    ├── variables.tf
    └── outputs.tf
```

## Виправлення після лекції

- Узгоджено назву середовища та ключ state: `lesson-5`.
- Додано AWS provider із регіоном `us-west-2` і версією `~> 5.81.0`, відповідною до прикладу лекції; Terraform: `>= 1.0, < 2.0`.
- Назва бакета передається обов'язковою змінною `bucket_name`, оскільки вона має бути глобально унікальною в AWS.
- S3 backend залишено закоментованим до створення його ресурсів: початковий state буде локальним.
- Локальні state, параметри та службові файли виключено з Git. Файл `.terraform.lock.hcl` після ініціалізації слід зберігати в Git.

Блокування через DynamoDB збережено відповідно до лекції. У поточній [документації S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) цей спосіб позначено як deprecated.

## Підготовка

Потрібні встановлений Terraform сумісної версії, AWS account, налаштовані AWS credentials і IAM permissions для створення та керування S3-бакетом і таблицею DynamoDB, читання/запису state та роботи з блокуванням. Credentials налаштовуйте через AWS profile або стандартні змінні середовища AWS; не записуйте їх у файли проєкту.

Усі команди нижче призначені для майбутнього ручного запуску з кореня `lesson-5`. Під час підготовки проєкту Terraform-команди не виконувалися, ресурси AWS не створювалися, реальна інтеграція з AWS не перевірялася.

## Початкове створення з локальним state

1. Залиште S3 backend у `backend.tf` закоментованим.
2. Оберіть власну вільну назву бакета відповідно до правил AWS та задайте її замість прикладу:

   ```bash
   export TF_VAR_bucket_name="your-globally-unique-bucket-name"
   ```

   Використовуйте це саме значення під час усіх подальших запусків для цього проєкту.

3. Ініціалізуйте проєкт, перевірте конфігурацію та перегляньте план:

   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

4. Переконайтеся, що план створює очікувані ресурси у потрібному account і регіоні, потім застосуйте його та підтвердьте створення:

   ```bash
   terraform apply
   ```

## Перенесення state в S3

1. Переконайтеся, що бакет і таблиця `terraform-locks` вже створені в `us-west-2`. Збережіть резервну копію локального `terraform.tfstate` поза репозиторієм; state може містити чутливі дані.
2. У `backend.tf` замініть `REPLACE_WITH_YOUR_UNIQUE_BUCKET_NAME` **точним значенням** `TF_VAR_bucket_name` і розкоментуйте блок `terraform`. Backend не може читати `var.bucket_name`, тому назва вказується явно. Регіон і таблиця повинні відповідати створеним ресурсам; ключ state — `lesson-5/terraform.tfstate`.
3. Перенесіть наявний локальний state, підтвердивши копіювання, коли Terraform запитає:

   ```bash
   terraform init -migrate-state
   ```

   Не замінюйте цю команду на `-reconfigure`: цей параметр не виконує міграцію state. Деталі — у [документації terraform init](https://developer.hashicorp.com/terraform/cli/commands/init).

4. Перевірте список керованих ресурсів і наявність об'єкта `lesson-5/terraform.tfstate` у вашому бакеті через S3 console:

   ```bash
   terraform state list
   ```

До успішного завершення та перевірки міграції не видаляйте `.terraform/`, локальні state або резервну копію. Повторний `apply` лише через міграцію не потрібен. Зберігайте конфігурацію backend увімкненою для подальшої роботи з цим state.
