# GitHub Actions - Terraform Pipeline

Este pipeline de GitHub Actions automatiza el despliegue de infraestructura usando Terraform con soporte para múltiples ambientes mediante workspaces.

## Ejecución Manual

Puedes ejecutar el workflow manualmente desde GitHub:

1. Ve a tu repositorio en GitHub
2. Click en la pestaña **Actions**
3. Selecciona el workflow **Terraform Deploy**
4. Click en **Run workflow**
5. Selecciona:
   - **Workspace**: prod, qa, o dev
   - **Apply changes after plan?**:
     - ✅ Marcado: Ejecuta plan Y aplica los cambios
     - ❌ Desmarcado (default): Solo ejecuta el plan (seguro)

El workflow **SIEMPRE ejecuta el plan** para que puedas ver qué cambios se harán. El apply es completamente opcional.

Esto te permite ejecutar Terraform en cualquier workspace sin necesidad de hacer push a una rama específica.

## Configuración

### Secrets Requeridos

Debes configurar los siguientes secrets en tu repositorio de GitHub (Settings > Secrets and variables > Actions):

- `AWS_ACCESS_KEY_ID`: Access Key ID de AWS
- `AWS_SECRET_ACCESS_KEY`: Secret Access Key de AWS

### Workspaces

El pipeline utiliza workspaces de Terraform para gestionar diferentes ambientes:

- **rama `main`** → workspace `prod`
- **rama `qa`** → workspace `qa`

## Funcionamiento

### Pull Requests

Cuando creas un PR hacia `main` o `qa`:
1. Se ejecuta `terraform init`
2. Se selecciona/crea el workspace correspondiente
3. Se valida la configuración
4. Se genera un plan (sin aplicar cambios)
5. El plan se comenta automáticamente en el PR

### Push a main o qa

Cuando haces push directo o se mergea un PR:
1. Ejecuta todos los pasos anteriores
2. **Aplica automáticamente los cambios** con `terraform apply`
3. Guarda los outputs como artifacts

## Artefactos Generados

El pipeline genera los siguientes artifacts:

- `tfplan-{workspace}`: Plan de Terraform (retención: 5 días)
- `terraform-outputs-{workspace}`: Outputs de Terraform en JSON (retención: 30 días)

## Notas Importantes

- El workflow requiere que el backend de S3 esté configurado correctamente
- Los credentials de AWS deben tener los permisos necesarios para crear los recursos
- El apply se ejecuta automáticamente en push a main/qa (sin aprobación manual)
- El formato del código se verifica pero no bloquea el pipeline

## Configuración del Backend

Asegúrate de que tu `backend.tf` esté configurado para usar workspaces:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-states-utn-demo"
    key            = "terraform-lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

## Mejoras Futuras

Posibles mejoras al pipeline:

1. Agregar aprobación manual antes del apply en producción
2. Implementar tests de seguridad (tfsec, checkov)
3. Agregar notificaciones a Slack/Email
4. Implementar drift detection
5. Agregar cost estimation con Infracost
