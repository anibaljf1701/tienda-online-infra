# Infraestructura de Tienda Online

Infraestructura como código con Terraform y Terragrunt para una tienda online de demostración. Usa **MiniStack** como emulador local de AWS en `localhost:4566`.

Provisiona alojamiento web estático en S3, colas de pedidos en SQS, alertas en SNS, una tabla de productos en DynamoDB y secretos en Secrets Manager. Cada entorno se mantiene aislado y el estado remoto se almacena en el S3 de MiniStack.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                   MiniStack (localhost:4566)             │
│                                                         │
│  ┌──────────┐    ┌─────────┐    ┌───────────────────┐  │
│  │ Sitio web│    │   SNS   │───▶│   Pedidos SQS     │  │
│  │ estático │    │ Alertas │    │ Cola + DLQ        │  │
│  └──────────┘    └─────────┘    └───────────────────┘  │
│                                                         │
│  ┌──────────────────┐    ┌─────────────────────────┐   │
│  │  DynamoDB        │    │  Secrets Manager        │   │
│  │ Tabla productos  │    │ Secreto db_password     │   │
│  └──────────────────┘    └─────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

Cada entorno (`dev`, `stg`, `prod`) tiene sus propios recursos y archivos de estado de Terraform, almacenados en `tienda-tfstate`.

## Inicio rápido

Clona el repositorio y sigue estos pasos para levantar la infraestructura local.

```bash
# 1. Clonar el repositorio
git clone https://github.com/YOUR_USERNAME/tienda-online-infra.git
cd tienda-online-infra

# 2. Iniciar MiniStack
docker run --rm -d --name ministack -p 4566:4566 ministackorg/ministack

# 3. Crear el bucket para el estado remoto
aws --profile local s3 mb s3://tienda-tfstate

# 4. Desplegar el entorno dev
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply

# 5. Abrir el catálogo de productos
# http://localhost:4566/tienda-dev-static/index.html
```

> **Nota:** Revisa el resultado del plan antes de aplicarlo. No uses aprobación automática en el primer despliegue ni para cambios en producción.

## Tecnologías

| Herramienta | Versión | Uso |
|------|---------|---------|
| Terraform | >= 1.6.0 | Aprovisionamiento de infraestructura |
| Terragrunt | >= 1.1.0 | Configuración compartida, estado remoto y dependencias |
| AWS Provider | ~> 6.54.0 | Administración de recursos AWS |
| MiniStack | 1.4.x | Emulador local de AWS |

## ¿Por qué Terragrunt?

Los entornos `dev`, `stg` y `prod` reutilizan los mismos módulos de Terraform. Terragrunt concentra la configuración por entorno y las dependencias entre stacks:

- **`root.hcl`**: configuración compartida del estado remoto, generación del provider, etiquetas e inputs comunes.
- **`env.hcl`**: un archivo por entorno que declara `environment = "dev"`, `"stg"` o `"prod"`.
- **`terragrunt.hcl` de cada stack**: declara el módulo y sus dependencias; hereda la configuración común de `root.hcl`.

## Estructura de directorios

```
tienda_online/
├── .gitignore
├── README.md
└── terraform/
    ├── root.hcl                    ← backend, provider e inputs compartidos
    ├── modules/                    ← módulos Terraform reutilizables, independientes de Terragrunt
    │   ├── s3_website/
    │   │   ├── versions.tf
    │   │   ├── variables.tf
    │   │   ├── locals.tf
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── templates/
    │   │       ├── index.html.tftpl
    │   │       └── error.html
    │   ├── sqs_orders/
    │   ├── sns_alerts/
    │   ├── dynamodb_products/
    │   └── secrets/
    └── live/                       ← configuración Terragrunt por entorno
        ├── dev/
        │   ├── env.hcl             ← environment = "dev"
        │   ├── s3_website/
        │   │   └── terragrunt.hcl
        │   ├── sqs_orders/
        │   │   └── terragrunt.hcl
        │   ├── sns_alerts/
        │   │   └── terragrunt.hcl
        │   ├── dynamodb_products/
        │   │   └── terragrunt.hcl
        │   └── secrets/
        │       └── terragrunt.hcl
        ├── stg/
        │   ├── env.hcl             ← environment = "stg"
        │   ├── s3_website/terragrunt.hcl
        │   ├── sqs_orders/terragrunt.hcl
        │   ├── sns_alerts/terragrunt.hcl
        │   ├── dynamodb_products/terragrunt.hcl
        │   └── secrets/terragrunt.hcl
        └── prod/
            ├── env.hcl             ← environment = "prod"
            ├── s3_website/
            │   └── terragrunt.hcl
            ├── sqs_orders/
            │   └── terragrunt.hcl
            ├── sns_alerts/
            │   └── terragrunt.hcl
            ├── dynamodb_products/
            │   └── terragrunt.hcl
            └── secrets/
                └── terragrunt.hcl
```

`terraform/live` es la única raíz de despliegue soportada. No ejecutes Terraform directamente desde un directorio de módulo ni mantengas otras raíces por entorno.

## Requisitos previos

| Herramienta | Versión | Instalación |
|------|---------|---------|
| Docker | >= 24 | [Documentación de Docker](https://docs.docker.com/engine/install/) |
| MiniStack | 1.4.x | `docker pull ministackorg/ministack` |
| Terraform | >= 1.6.0 | [Instalación de Terraform](https://developer.hashicorp.com/terraform/install) |
| Terragrunt | >= 1.1.0 | Ver instrucciones más abajo |
| AWS CLI | v2 | Ejecutar `sudo /tmp/aws/install` después de descargarlo |

### Iniciar MiniStack

MiniStack es el emulador local de AWS. Inícialo antes de ejecutar comandos de Terragrunt:

```bash
docker run --rm -d \
  --name ministack \
  -p 4566:4566 \
  ministackorg/ministack
```

Comprueba que esté disponible:

```bash
curl -s http://localhost:4566/_ministack/health | python3 -m json.tool | grep '"dynamodb"'
# Resultado esperado: "dynamodb": "available"
```

`/_ministack/health` es el endpoint de salud documentado por MiniStack. También acepta `/_localstack/health` para mantener compatibilidad con LocalStack.

### Instalar Terraform (Linux)

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
terraform -version
```

### Instalar Terragrunt (Linux)

```bash
# Descargar la última versión
TGVERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest \
  | grep tag_name | cut -d '"' -f 4)

curl -Lo /tmp/terragrunt \
  "https://github.com/gruntwork-io/terragrunt/releases/download/${TGVERSION}/terragrunt_linux_amd64"

chmod +x /tmp/terragrunt
sudo mv /tmp/terragrunt /usr/local/bin/terragrunt

terragrunt --version
```

### Instalar AWS CLI v2 (Linux)

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp/
sudo /tmp/aws/install --update
aws --version  # debe mostrar aws-cli/2.x.x
```

### Configurar el perfil local de AWS CLI

Agrega lo siguiente a los archivos de configuración de AWS (créelos si todavía no existen):

```bash
# ~/.aws/credentials
[local]
aws_access_key_id = test
aws_secret_access_key = test

# ~/.aws/config
[profile local]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
```

Comprueba que el perfil funcione:

```bash
aws --profile local s3 ls
# Devuelve una lista vacía si MiniStack está activo y todavía no hay buckets
```

## Flujo de trabajo local

### Comprobar que MiniStack está activo

```bash
docker ps | grep ministack
```

### Crear el bucket de estado remoto (solo la primera vez)

```bash
aws --profile local s3 mb s3://tienda-tfstate
```

### Desplegar un solo stack

```bash
cd terraform/live/dev/dynamodb_products
terragrunt init
terragrunt plan
terragrunt apply
```

### Desplegar todos los stacks de un entorno

```bash
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply
```

Terragrunt resuelve automáticamente el orden de dependencias: aplica SQS antes que SNS.

### Desplegar todos los entornos (solo MiniStack local)

```bash
cd terraform/live
terragrunt run --all plan
terragrunt run --all apply
```

Este comando aplica `dev`, `stg` y `prod`. En AWS, despliega un entorno por vez.

## Estado remoto

Cada stack almacena su estado en el S3 de MiniStack, usando una ruta derivada de la estructura de directorios:

| Stack | Clave de estado |
|-------|-----------|
| dev/s3_website | `live/dev/s3_website/terraform.tfstate` |
| dev/sqs_orders | `live/dev/sqs_orders/terraform.tfstate` |
| dev/sns_alerts | `live/dev/sns_alerts/terraform.tfstate` |
| dev/dynamodb_products | `live/dev/dynamodb_products/terraform.tfstate` |
| dev/secrets | `live/dev/secrets/terraform.tfstate` |
| stg/... | `live/stg/.../terraform.tfstate` |
| prod/... | `live/prod/.../terraform.tfstate` |

Lista los archivos de estado:

```bash
aws --profile local s3 ls s3://tienda-tfstate --recursive
```

## Dependencias entre stacks

El stack SNS depende de SQS porque necesita el ARN y la URL de la cola para crear la suscripción y la política de la cola. La dependencia es unidireccional, no hay un ciclo:

```
sns_alerts  ──depends_on──▶  sqs_orders (needs queue_arn and queue_url)
```

Terragrunt aplica SQS antes que SNS y pasa los outputs reales de la cola al stack SNS. `mock_outputs` se usan únicamente en `validate` o `plan` cuando la dependencia todavía no está desplegada; no se usan en `apply`.

## Comandos de verificación

Después de ejecutar `terragrunt run --all apply` en `live/dev/`:

```bash
# Sitio web estático en S3
aws --profile local s3 ls
aws --profile local s3api get-bucket-website --bucket tienda-dev-static

# Abrir el catálogo de productos
# http://localhost:4566/tienda-dev-static/index.html

# SQS
aws --profile local sqs list-queues

# SNS
aws --profile local sns list-topics

# DynamoDB
aws --profile local dynamodb list-tables
aws --profile local dynamodb scan --table-name tienda-dev-products

# Secrets Manager
aws --profile local secretsmanager list-secrets

# Estado remoto
aws --profile local s3 ls s3://tienda-tfstate --recursive
```

## Diferencias entre entornos

La única fuente de configuración específica de cada entorno es `env.hcl`:

```hcl
# live/dev/env.hcl
locals {
  environment = "dev"
}

# live/stg/env.hcl
locals {
  environment = "stg"
}

# live/prod/env.hcl
locals {
  environment = "prod"
}
```

Ese valor lo lee `root.hcl` y se propaga al provider de cada stack, los nombres de recursos (`tienda-dev-*`, `tienda-stg-*`, `tienda-prod-*`), las etiquetas y las rutas de estado. Los tres entornos usan los mismos módulos y stacks de Terragrunt en `terraform/live`. No hay raíces Terraform separadas: `live` es la fuente de verdad.

## Despliegue en AWS (`dev`, `stg`, `prod`)

La configuración actual es únicamente para MiniStack y se mantiene para el uso local. No la apuntes directamente a AWS: el provider y el backend S3 usan `localhost:4566` y credenciales de prueba, y el módulo del sitio web permite lectura pública de objetos. Antes de desplegar en AWS, aplica los siguientes cambios en una configuración o rama específica para AWS. Nunca mezcles el estado ni las credenciales de MiniStack con los de AWS.

### Cambios de configuración necesarios

1. **Usa credenciales y configuración de provider de AWS.** Mantén `terraform/root.hcl` para MiniStack. Para AWS, crea una configuración raíz separada y haz que los stacks live la incluyan en el flujo de despliegue para AWS. En el bloque del provider AWS elimina `access_key`, `secret_key`, `skip_credentials_validation`, `skip_metadata_api_check`, `skip_requesting_account_id` y todo el bloque `endpoints`. Usa credenciales de AWS CLI con SSO localmente o un rol IAM/OIDC en CI; nunca guardes credenciales en el repositorio. Define explícitamente la región de AWS para cada entorno. El provider debe usar la cadena normal de credenciales, por ejemplo:

   ```hcl
   provider "aws" {
     region = "us-east-1"

     default_tags {
       tags = {
         Project     = "tienda"
         Environment = "dev"
         ManagedBy   = "Terraform"
       }
     }
   }
   ```

2. **Usa un bucket de estado remoto exclusivo para AWS.** Créalo fuera de estos stacks de aplicación y en la cuenta AWS de destino. Habilita versionado, cifrado del lado del servidor, bloqueo de acceso público y acceso de mínimo privilegio para los roles de despliegue. Usa un nombre de bucket globalmente único y, cuando sea posible, una cuenta o bucket separado para producción. En `remote_state.config` de AWS elimina `endpoint`, las credenciales de prueba `access_key`/`secret_key`, todas las opciones `skip_*` y `force_path_style`; configura el bucket, la región, el cifrado y una clave única por entorno y stack. Habilita el bloqueo de archivos S3 con `use_lockfile = true` y aumenta a `>= 1.10.0` la versión mínima de Terraform en todos los módulos. Nunca uses el bucket MiniStack `tienda-tfstate` ni reutilices el estado local para AWS.
3. **Despliega el entorno `stg` existente.** `terraform/live/stg` ya contiene `env.hcl` y los cinco archivos de configuración de stacks. Está habilitado en las validaciones de entorno de los módulos y tiene nombres de recursos y claves de estado aislados. Inclúyelo en los planes de CI y despliega desde ese directorio, igual que `dev` y `prod`.
4. **Mantén el S3 público para uso local y cámbialo para AWS.** El módulo S3 desactiva intencionalmente las cuatro opciones de bloqueo de acceso público y agrega una política que concede `s3:GetObject` a `Principal = "*"`. Déjalo así para el demo local de MiniStack. En AWS, activa las cuatro opciones de bloqueo, elimina esa política pública y mantén el bucket privado. Agrega una distribución CloudFront con el endpoint REST de S3 (no el endpoint de sitio web), configura Origin Access Control (OAC) y agrega una política de bucket que permita `s3:GetObject` únicamente a `cloudfront.amazonaws.com`, condicionada al ARN específico de la distribución. Configura TLS y DNS según sea necesario. Implementa estas opciones como inputs o recursos específicos de AWS para mantener MiniStack solo en local; revisa el plan y la política resultante antes de aplicar.
5. **Revisa los controles de producción.** Usa cuentas AWS separadas o límites claros entre roles de `dev`, `stg` y `prod`; define permisos de despliegue de mínimo privilegio; revisa retención, visibilidad y redrive de SQS, entrega de SNS y alarmas, respaldos/PITR y cifrado de DynamoDB, y rotación/acceso a Secrets Manager. El estado y los planes pueden contener datos sensibles: limita su acceso, cífralos y no imprimas secretos en los logs de CI. Despliega un entorno por vez y exige aprobación para producción.

### Flujo de despliegue sugerido en AWS

Después de crear la configuración raíz, el provider y el backend específicos de AWS, y de poner el sitio S3 privado detrás de CloudFront, configura el acceso mediante SSO/roles de AWS y verifica la cuenta y la región activas antes de cada despliegue. Despliega cada entorno por separado, revisa el plan y aplica únicamente los cambios aprobados:

```bash
aws sts get-caller-identity --profile tienda-dev
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply
```

Repite el proceso con el perfil y directorio correspondientes a `stg` y `prod`. Usa aprobaciones de producción en CI/CD. No ejecutes `terragrunt run --all apply` desde `terraform/live` contra AWS, porque aplicaría todos los entornos en una sola operación.

### Notas del proyecto

- `price` y `stock` son atributos de tipo Number en DynamoDB. `stock` representa unidades disponibles: el catálogo indica agotado cuando es cero y pocas unidades cuando es cinco o menos. Al actualizar una instalación existente, revisa el plan para confirmar el cambio de tipo de los productos iniciales; los registros administrados manualmente requieren su propia migración.
- La ruta de salud documentada por MiniStack es `/_ministack/health`. También acepta `/_localstack/health` como alias compatible con LocalStack.
- El proyecto aprovisiona servicios básicos para una demostración, no una plataforma de comercio completa para producción. Autenticación, checkout/pagos, ejecución de la aplicación, observabilidad, respaldos y CDN/dominio están fuera del alcance de los módulos actuales.
