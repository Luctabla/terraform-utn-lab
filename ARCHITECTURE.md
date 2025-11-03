# Architecture Diagram

## AWS Infrastructure

This diagram shows the AWS resources created by this Terraform project and how they interact:

```mermaid
graph TB
    subgraph "AWS Account"
        subgraph "SQS Service"
            SQS[SQS Queue<br/>terraform-lab-queue-{workspace}]
        end

        subgraph "Lambda Service"
            Lambda[Lambda Function<br/>terraform-lab-sqs-to-s3-{workspace}<br/>Runtime: Python 3.12]
            ESM[Event Source Mapping<br/>Batch Size: 1]
        end

        subgraph "S3 Service"
            S3[S3 Bucket<br/>terraform-lab-output-{workspace}<br/>Versioning: Enabled]
        end

        subgraph "IAM Service"
            Role[IAM Role<br/>terraform-lab-lambda-role-{workspace}]
            Policy[IAM Policy<br/>Permissions for Lambda]
        end

        subgraph "CloudWatch Logs"
            Logs[Log Group<br/>Lambda Execution Logs]
        end
    end

    %% Connections
    SQS -->|Triggers| ESM
    ESM -->|Invokes| Lambda
    Lambda -->|Writes Objects| S3
    Lambda -->|Logs| Logs
    Role -->|Attached to| Lambda
    Policy -->|Attached to| Role

    %% Policy permissions
    Policy -.->|Read/Delete Messages| SQS
    Policy -.->|Write Objects| S3
    Policy -.->|Create/Write Logs| Logs

    %% Styling
    classDef sqsStyle fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:#000
    classDef lambdaStyle fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:#000
    classDef s3Style fill:#569a31,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef iamStyle fill:#dd344c,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef logsStyle fill:#b7ca9d,stroke:#232f3e,stroke-width:2px,color:#000

    class SQS sqsStyle
    class Lambda,ESM lambdaStyle
    class S3 s3Style
    class Role,Policy iamStyle
    class Logs logsStyle
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant SQS as SQS Queue
    participant Lambda as Lambda Function
    participant S3 as S3 Bucket
    participant CW as CloudWatch Logs

    User->>SQS: Send Message
    Note over SQS: Message stored in queue

    SQS->>Lambda: Trigger (via Event Source Mapping)
    Note over Lambda: Process message

    Lambda->>S3: Write processed data
    Note over S3: Object stored with versioning

    Lambda->>CW: Write execution logs

    Lambda->>SQS: Delete message (after success)
    Note over SQS: Message removed from queue
```

## Terraform State Management

```mermaid
graph LR
    subgraph "Local Development"
        TF[Terraform CLI]
    end

    subgraph "AWS Backend Infrastructure"
        subgraph "S3 Backend"
            Bucket[S3 Bucket<br/>terraform-states-utn-demo<br/>Encryption: AES256<br/>Versioning: Enabled]

            subgraph "State Files"
                DefaultState[env:/default/terraform-lab/<br/>terraform.tfstate]
                DevState[env:/dev/terraform-lab/<br/>terraform.tfstate]
                StagingState[env:/staging/terraform-lab/<br/>terraform.tfstate]
                ProdState[env:/prod/terraform-lab/<br/>terraform.tfstate]
            end
        end

        DDB[DynamoDB Table<br/>terraform-state-locks<br/>Lock state during operations]
    end

    TF -->|Read/Write State| Bucket
    TF -->|Acquire/Release Lock| DDB
    Bucket --> DefaultState
    Bucket --> DevState
    Bucket --> StagingState
    Bucket --> ProdState

    classDef s3Style fill:#569a31,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef ddbStyle fill:#2e73b8,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef tfStyle fill:#7b42bc,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef stateStyle fill:#90ee90,stroke:#232f3e,stroke-width:1px,color:#000

    class Bucket s3Style
    class DDB ddbStyle
    class TF tfStyle
    class DefaultState,DevState,StagingState,ProdState stateStyle
```

## Workspace-based Resource Naming

```mermaid
graph TB
    subgraph "Terraform Workspaces"
        WS[Workspace Name<br/>dev / staging / prod]
    end

    subgraph "Resource Naming Pattern"
        Pattern["{project_name}-{resource}-{workspace}"]
    end

    subgraph "Example: dev workspace"
        Lambda1[terraform-lab-sqs-to-s3-dev]
        S3_1[terraform-lab-output-dev]
        SQS1[terraform-lab-queue-dev]
        Role1[terraform-lab-lambda-role-dev]
    end

    subgraph "Example: prod workspace"
        Lambda2[terraform-lab-sqs-to-s3-prod]
        S3_2[terraform-lab-output-prod]
        SQS2[terraform-lab-queue-prod]
        Role2[terraform-lab-lambda-role-prod]
    end

    WS --> Pattern
    Pattern --> Lambda1
    Pattern --> S3_1
    Pattern --> SQS1
    Pattern --> Role1
    Pattern --> Lambda2
    Pattern --> S3_2
    Pattern --> SQS2
    Pattern --> Role2

    classDef wsStyle fill:#7b42bc,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef devStyle fill:#4a90e2,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef prodStyle fill:#e24a4a,stroke:#232f3e,stroke-width:2px,color:#fff

    class WS,Pattern wsStyle
    class Lambda1,S3_1,SQS1,Role1 devStyle
    class Lambda2,S3_2,SQS2,Role2 prodStyle
```

## IAM Permissions Flow

```mermaid
graph TB
    subgraph "Lambda Function"
        LambdaFunc[Lambda Function<br/>terraform-lab-sqs-to-s3-{workspace}]
    end

    subgraph "IAM Role"
        LambdaRole[IAM Role<br/>terraform-lab-lambda-role-{workspace}]

        subgraph "Attached Policy"
            Policy[IAM Policy<br/>terraform-lab-lambda-policy]

            subgraph "Permissions"
                LogsPerm[CloudWatch Logs<br/>CreateLogGroup<br/>CreateLogStream<br/>PutLogEvents]

                SQSPerm[SQS Queue<br/>ReceiveMessage<br/>DeleteMessage<br/>GetQueueAttributes]

                S3Perm[S3 Bucket<br/>PutObject<br/>PutObjectAcl]
            end
        end
    end

    subgraph "AWS Services"
        CWLogs[CloudWatch Logs]
        SQSQueue[SQS Queue]
        S3Bucket[S3 Bucket]
    end

    LambdaFunc -->|Assumes| LambdaRole
    LambdaRole -->|Has| Policy
    Policy --> LogsPerm
    Policy --> SQSPerm
    Policy --> S3Perm

    LogsPerm -.->|Allows Access| CWLogs
    SQSPerm -.->|Allows Access| SQSQueue
    S3Perm -.->|Allows Access| S3Bucket

    classDef lambdaStyle fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:#000
    classDef iamStyle fill:#dd344c,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef permStyle fill:#ffd700,stroke:#232f3e,stroke-width:1px,color:#000
    classDef serviceStyle fill:#232f3e,stroke:#ff9900,stroke-width:2px,color:#fff

    class LambdaFunc lambdaStyle
    class LambdaRole,Policy iamStyle
    class LogsPerm,SQSPerm,S3Perm permStyle
    class CWLogs,SQSQueue,S3Bucket serviceStyle
```

## Key Features

### Security
- **S3 Bucket Versioning**: Enabled for output bucket to track object history
- **State Encryption**: S3 backend uses AES256 encryption
- **State Locking**: DynamoDB prevents concurrent modifications
- **IAM Least Privilege**: Lambda has only necessary permissions

### Multi-Environment Support
- **Workspaces**: Separate state files per environment (dev, staging, prod)
- **Dynamic Naming**: Resources automatically named based on workspace
- **Isolated Resources**: Each workspace creates independent AWS resources

### Observability
- **CloudWatch Logs**: Automatic logging of Lambda executions
- **SQS Metrics**: Built-in monitoring for queue depth and message age
- **S3 Access Logs**: Can be enabled for audit trails

## Resource Specifications

| Resource | Name Pattern | Configuration |
|----------|-------------|---------------|
| Lambda Function | `{project}-sqs-to-s3-{workspace}` | Runtime: Python 3.12, Timeout: 60s |
| S3 Bucket | `{project}-output-{workspace}` | Versioning: Enabled |
| SQS Queue | `{project}-queue-{workspace}` | Visibility: 300s, Retention: 24h |
| IAM Role | `{project}-lambda-role-{workspace}` | Service: lambda.amazonaws.com |
| Event Source Mapping | N/A | Batch Size: 1, Enabled: true |

## Prerequisites Infrastructure

The backend infrastructure must be deployed first:

| Resource | Name | Purpose |
|----------|------|---------|
| S3 Bucket | `terraform-states-utn-demo` | Store Terraform state files |
| DynamoDB Table | `terraform-state-locks` | Manage state locking |

These are deployed separately using the `prerequisites/` directory and only need to be created once.
