# Task Manager — Production Implementation Plan

## Phase 0 — Baseline and safety

**Goal:** freeze the current working state before infrastructure changes.

- Record the current main-branch commit.
- Keep production work on the `production-blueprint` branch until reviewed.
- Confirm AWS region and Free Tier eligibility.
- Confirm no secrets are tracked by Git.
- Record current Docker image/repository details.

**Exit criteria:** baseline is reproducible and no secret is exposed.

## Phase 1 — Application production profile

Files expected to change:
- `src/main/resources/application.properties`
- optionally add `application-mysql.properties` or an environment-specific profile.

Tasks:
- make MySQL configuration environment-driven;
- disable H2 console outside local development;
- change JPA schema strategy deliberately for production;
- configure actuator health safely;
- review logging;
- verify startup with a local MySQL container.

**Exit criteria:** application starts locally against MySQL using only environment variables.

## Phase 2 — Container hardening

Files expected to change:
- `Dockerfile`
- `.dockerignore`
- optional `compose.yml` for local development.

Tasks:
- preserve multi-stage build;
- use non-root runtime user;
- minimize runtime image;
- add/verify health check;
- avoid embedding secrets;
- test clean startup and shutdown.

**Exit criteria:** immutable image starts successfully and passes health checks.

## Phase 3 — Terraform networking and security

Files expected to change:
- `terraform/main.tf`
- `terraform/variables.tf`
- `terraform/outputs.tf`
- optional `terraform/versions.tf`.

Tasks:
- remove public 8080 ingress;
- restrict SSH or prepare SSM migration;
- separate application and database network concerns;
- keep RDS inaccessible from the Internet;
- add consistent tags;
- avoid paid networking components such as NAT Gateway;
- replace hard-coded region-specific AMI values with a safer lookup where practical.

**Exit criteria:** `terraform validate` and `terraform plan` show only intended resources and network paths.

## Phase 4 — EC2 bootstrap

Tasks:
- install Docker reproducibly;
- configure Docker to start at boot;
- configure application directories;
- configure NGINX;
- install/configure CloudWatch logging/agent as needed;
- attach least-privilege IAM role;
- prepare SSM access.

**Exit criteria:** a fresh EC2 instance can be prepared without undocumented manual steps.

## Phase 5 — RDS hardening

Tasks:
- use a supported Free-Tier-conscious MySQL class;
- verify subnet-group/network requirements;
- enable encryption where appropriate;
- set backup retention appropriate to the budget;
- ensure DB security group accepts only EC2 traffic;
- document restore procedure.

**Exit criteria:** application can connect to RDS while direct public access fails.

## Phase 6 — ECR and CI/CD

Replace Docker Hub as the primary AWS deployment registry.

Workflow design:

```text
PR -> Build -> Test -> Docker Build -> Security Scan -> No Deploy

main -> Build -> Test -> Scan -> ECR Push -> EC2 Deploy -> Health Check
                                                  |
                                               failure
                                                  |
                                               Rollback
```

Tasks:
- create ECR repository through Terraform;
- use immutable Git SHA tags;
- prefer GitHub OIDC for AWS authentication;
- keep deployment credentials out of source;
- add concurrency control so deployments do not overlap;
- deploy by immutable image digest/tag;
- preserve previous version for rollback.

**Exit criteria:** a merge to main automatically deploys a known image and verifies health.

## Phase 7 — HTTPS and DNS

Tasks:
- obtain/use a domain if available;
- configure DNS;
- configure NGINX;
- obtain TLS certificate using an appropriate ACME/Let's Encrypt flow;
- redirect HTTP to HTTPS;
- verify certificate renewal.

**Exit criteria:** application is accessible through HTTPS without exposing port 8080.

## Phase 8 — Observability

Tasks:
- centralize application/container logs;
- create useful CloudWatch log groups;
- monitor EC2 and RDS metrics;
- add alarms for sustained CPU/storage/health issues;
- optionally send alarms through SNS email.

**Exit criteria:** an operator can diagnose a failed deployment or unhealthy application from logs/metrics.

## Phase 9 — Backup, rollback, and recovery

Tasks:
- document RDS backup policy;
- document restore steps;
- test rollback to previous container image;
- document what is and is not recovered by an RDS snapshot;
- create a disaster/rebuild checklist.

**Exit criteria:** failure is a documented operational procedure, not an ad-hoc fix.

## Phase 10 — Documentation and portfolio polish

Update README with:
- architecture diagram;
- AWS services;
- deployment flow;
- environment variables;
- CI/CD workflow;
- monitoring;
- security controls;
- rollback;
- cost controls;
- screenshots only where useful.

Add:
- `docs/PRODUCTION_BLUEPRINT.md`
- `docs/IMPLEMENTATION_PLAN.md`
- optionally `docs/OPERATIONS_RUNBOOK.md`

**Exit criteria:** another engineer can understand and reproduce the system from the repository.

## Phase 11 — Optional Bedrock feature

Only after V1 production deployment is stable.

Candidate endpoint:

```text
POST /ai/task-plan
        |
        v
Spring Boot service
        |
        v
Amazon Bedrock
        |
        v
Model response
```

Guardrails:
- AI endpoint is separate from core CRUD;
- no task data sent unnecessarily;
- enforce request size/time limits;
- handle Bedrock failures gracefully;
- monitor model usage/cost.

## Suggested Execution Order

1. Baseline/safety
2. Application profile
3. Docker hardening
4. Terraform networking/security
5. EC2 bootstrap
6. RDS hardening
7. ECR + CI/CD
8. HTTPS/DNS
9. CloudWatch
10. Rollback/recovery
11. Documentation
12. Optional Bedrock

## Stop Conditions

Stop and review before applying infrastructure if:
- Terraform proposes an unexpected paid service;
- an RDS/EC2 class is not Free-Tier eligible for this account;
- a secret would be committed;
- port 3306 or 8080 would become public;
- a deployment would remove the only known-good application version;
- a new AWS service is being added without a concrete requirement.

## First Implementation Milestone

The first code milestone is **not an AWS apply**. It is a reviewed production branch containing:

- production blueprint;
- implementation plan;
- application configuration changes;
- Docker hardening;
- Terraform security/network changes;
- CI/CD redesign;
- validation commands and expected results.

Only after that review should infrastructure be applied to the AWS account.