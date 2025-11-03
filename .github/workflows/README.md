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

El workflow está dividido en dos jobs: **Plan** y **Apply**

### Job 1: Plan (Siempre se ejecuta)

Este job se ejecuta en todos los casos (PR, push, manual):
1. Empaqueta la función Lambda
2. Se ejecuta `terraform init`
3. Se selecciona/crea el workspace correspondiente
4. Se valida la configuración
5. Se genera un plan
6. El plan se guarda como artifact
7. En PRs, comenta el plan automáticamente

### Job 2: Apply (Requiere Aprobación Manual)

Este job solo se ejecuta en push a `main`/`qa` o ejecución manual con apply marcado:
1. **Espera aprobación manual** del environment correspondiente
2. Descarga el plan del job anterior
3. Ejecuta `terraform apply` con el plan aprobado
4. Guarda los outputs como artifacts

### Pull Requests

Cuando creas un PR hacia `main` o `qa`:
- Solo ejecuta el job **Plan**
- No aplica cambios
- Comenta el plan en el PR automáticamente

### Push a main o qa

Cuando haces push directo o se mergea un PR:
1. Ejecuta el job **Plan**
2. **Pausa y espera aprobación manual**
3. Después de aprobar, ejecuta el job **Apply**

## Artefactos Generados

El pipeline genera los siguientes artifacts:

- `tfplan-{workspace}`: Plan de Terraform (retención: 5 días)
- `terraform-outputs-{workspace}`: Outputs de Terraform en JSON (retención: 30 días)

## Configuración de Environments (Aprobación Manual)

Para habilitar la aprobación manual, debes configurar los environments en GitHub:

1. Ve a tu repositorio en GitHub
2. Settings → Environments
3. Crea los siguientes environments:
   - `prod`
   - `qa`
   - `dev` (opcional)
4. Para cada environment:
   - Click en el environment
   - Marca **Required reviewers**
   - Agrega los usuarios que pueden aprobar (tú o tu equipo)
   - Opcionalmente configura **Wait timer** para retrasos adicionales

Una vez configurado, el job **Apply** se pausará y esperará aprobación antes de aplicar cambios.

## Notas Importantes

- El workflow requiere que el backend de S3 esté configurado correctamente
- Los credentials de AWS deben tener los permisos necesarios para crear los recursos
- **El apply requiere aprobación manual** configurando los environments en GitHub
- El formato del código se verifica pero no bloquea el pipeline
- El plan siempre se ejecuta primero, permitiéndote revisar los cambios antes de aprobar

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

1. ✅ ~~Agregar aprobación manual antes del apply en producción~~ (Implementado)
2. Implementar tests de seguridad (tfsec, checkov)
3. Agregar notificaciones a Slack/Email
4. Implementar drift detection
5. Agregar cost estimation con Infracost
