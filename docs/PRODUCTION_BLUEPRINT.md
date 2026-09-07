# Task Manager — Production Deployment Blueprint

## 1. Objective

Transform the current Spring Boot + MySQL + Docker + Terraform project into a professional, Free-Tier-conscious AWS deployment that demonstrates practical Cloud/DevOps engineering skills without adding unnecessary managed services.

## 2. Target Architecture

```text
                         Internet
                            |
                     Route 53 / DNS
                            |
                       HTTPS :443
                            |
                         NGINX
                     (EC2 reverse proxy)
                            |
                    localhost:8080
                            |
                    Spring Boot / Docker
                            |
                         TCP 3306
                            |
                       RDS MySQL

GitHub -> GitHub Actions -> Test -> Security Scan -> Docker Build
                                      |
                                      v
                                    ECR
                                      |
                                      v
                                     EC2

EC2/RDS -> CloudWatch Logs + Metrics -> Alarms -> SNS/Email
EC2 administration -> AWS Systems Manager (SSM)
Secrets -> SSM Parameter Store / Secrets Manager as justified
```

## 3. AWS Services

| Service | Role | Priority |
|---|---|---|
| EC2 | Application host and Docker runtime | Core |
| RDS MySQL | Persistent relational database | Core |
| VPC | Network isolation | Core |
| Security Groups | Network access control | Core |
| IAM | Least-privilege access | Core |
| ECR | AWS-native container registry | Core |
| GitHub Actions | CI/CD | Core |
| NGINX | Reverse proxy and TLS termination | Core |
| CloudWatch | Logs, metrics, alarms | Core |
| SSM | Secure administration/configuration | Core |
| Route 53 | DNS, only if a domain is available | Optional |
| SNS | Alert delivery | Optional |
| Bedrock | AI task assistant feature | Phase 2/Optional |

## 4. Networking Blueprint

### VPC
- CIDR: `10.0.0.0/16`
- DNS support and hostnames enabled.

### Application subnet
- EC2 lives in a public subnet initially so the Free-Tier deployment remains simple and avoids NAT Gateway charges.
- Public access should be only through HTTP/HTTPS at the reverse proxy.

### Database subnet
- RDS must not be directly reachable from the Internet.
- Use a dedicated DB subnet group with appropriate subnet coverage supported by the selected RDS configuration.

### Security groups

EC2:
- TCP 80: public, for HTTP redirect/ACME where needed.
- TCP 443: public, application entry point.
- TCP 8080: no public ingress; application binds behind NGINX.
- TCP 22: temporary/restricted only if SSH is required during initial setup; migrate to SSM.
- Egress: required outbound access.

RDS:
- TCP 3306 only from the EC2 security group.
- No public database ingress.

## 5. Application Runtime

- Java 21 / Spring Boot 3.x.
- Docker image built with a multi-stage Dockerfile.
- Run as a non-root container user.
- Application port remains 8080 internally.
- Runtime database configuration is supplied through environment variables or secure parameter retrieval.
- Do not commit database passwords, private keys, or cloud credentials.

## 6. Database

RDS MySQL is the source of truth for persistent task data.

Production hardening goals:
- encryption at rest enabled where cost/eligibility permits;
- backup retention enabled when appropriate for the account budget;
- deletion protection considered for the final environment;
- final snapshot enabled for the final environment;
- database is not public;
- credentials are not stored in Git.

The initial learning environment may use shorter retention and simpler settings when explicitly labelled as non-production to control Free-Tier usage.

## 7. CI/CD Blueprint

### Pull request
1. Checkout.
2. Set up Java 21.
3. Compile.
4. Run unit tests.
5. Build the Docker image.
6. Run a container/image security scan.
7. Do not deploy.

### Main branch
1. Repeat validation.
2. Build Docker image.
3. Tag image with immutable Git SHA and a release tag when applicable.
4. Push to ECR.
5. Deploy the selected immutable image to EC2.
6. Perform a local health check.
7. Perform an external health check through HTTPS.
8. Roll back to the previous known-good image if verification fails.

## 8. Deployment Strategy

The first production-capable strategy will be a controlled single-host rolling replacement:

```text
Current container
      |
Pull new immutable image
      |
Start replacement
      |
Health check
   /       \
 PASS      FAIL
  |          |
Keep       Restore
new        previous
```

Because this is a single EC2 learning environment, this is not true zero-downtime HA. High availability is intentionally out of scope to control cost.

## 9. Observability

CloudWatch goals:
- EC2 CPU and status monitoring.
- RDS CPU, connections, and storage monitoring.
- Application/container logs.
- Health endpoint monitoring.
- Alarm for sustained resource pressure.
- Optional SNS email notification.

Application logs should be structured enough to identify timestamp, severity, component, and request/error context without leaking secrets.

## 10. Security Blueprint

- Least-privilege IAM roles.
- No long-lived AWS keys on EC2.
- GitHub secrets only for values that cannot use OIDC/role-based access.
- Prefer GitHub OIDC for AWS authentication where practical.
- No database credentials in source control.
- No public RDS.
- No public application port 8080.
- Restrict or remove SSH after SSM is working.
- HTTPS for the public application.
- Regular dependency and image security scanning.

## 11. Infrastructure as Code

Terraform remains the source of truth for AWS infrastructure.

Expected modules/resources:
- provider/version constraints;
- VPC and networking;
- security groups;
- EC2 instance and IAM role/profile;
- RDS instance/subnet group;
- ECR repository;
- optional CloudWatch resources;
- optional Route 53 records.

State must not be committed with secrets. A remote Terraform backend is a later enhancement; avoid adding S3/DynamoDB solely for the learning environment unless the account/cost model is confirmed first.

## 12. Cost Guardrails

Before every `terraform apply`:
- review `terraform plan`;
- verify region;
- verify instance classes;
- verify no NAT Gateway, ALB, Fargate, provisioned throughput, or other unexpected paid resource is being created;
- check AWS Billing/Free Tier dashboards.

Do not add services merely to make the architecture diagram larger.

## 13. Explicitly Out of Scope for V1

- EKS/Kubernetes.
- ECS/Fargate.
- NAT Gateway.
- Application Load Balancer.
- Multi-region deployment.
- ElastiCache.
- OpenSearch.
- Kafka/MSK.
- Multi-AZ application compute.

These can be studied separately after the Free-Tier deployment is stable.

## 14. Optional AI Extension

Amazon Bedrock should be added only after the core platform is stable.

Potential feature:
- summarize unfinished tasks;
- prioritize tasks from natural-language input;
- generate a daily task plan.

The AI feature must remain isolated from the core CRUD path so that the application remains functional if Bedrock is unavailable.

## 15. Definition of Done

The project is considered production-capable for portfolio purposes when:

- [ ] Terraform creates the required AWS infrastructure.
- [ ] RDS is private/restricted to EC2.
- [ ] EC2 does not publicly expose 8080.
- [ ] Docker image is hardened and versioned immutably.
- [ ] ECR stores release images.
- [ ] GitHub Actions validates pull requests.
- [ ] Main branch automatically deploys.
- [ ] Deployment verifies application health.
- [ ] Failed deployment can restore the previous image.
- [ ] HTTPS works.
- [ ] Logs are available in CloudWatch.
- [ ] Basic CloudWatch alarms exist.
- [ ] Secrets are outside Git history.
- [ ] SSM administration works or SSH is tightly restricted.
- [ ] RDS backup/recovery procedure is documented.
- [ ] README documents architecture, deployment, operations, rollback, and troubleshooting.
- [ ] AWS cost/free-tier usage has been reviewed.

## 16. Engineering Principle

The target is not "maximum AWS services." The target is a small system with clear boundaries, repeatable infrastructure, automated delivery, controlled security, observable runtime behavior, recoverability, and documented operations.