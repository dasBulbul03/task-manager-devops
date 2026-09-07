# Task Manager — Operations Runbook

## Deployment

1. Merge only validated changes to `main`.
2. GitHub Actions builds/tests/scans the application.
3. CI publishes an immutable container image to ECR.
4. Deployment updates EC2 to the new image.
5. Health checks must pass before the deployment is considered successful.

## Health Checks

Local on EC2:

```bash
curl -fsS http://127.0.0.1:8080/actuator/health
```

Public after HTTPS is configured:

```bash
curl -fsS https://<domain>/actuator/health
```

The public actuator surface must be reviewed before exposing it through NGINX.

## Container Inspection

```bash
docker ps
docker logs --tail 200 task-app
docker inspect task-app
```

## Deployment Failure

1. Check GitHub Actions logs.
2. Check the EC2 container status.
3. Check application logs.
4. Check RDS connectivity/security group rules.
5. If the new image is unhealthy, restore the previous immutable image.
6. Re-run health checks.

## Database Failure

1. Confirm RDS status in AWS.
2. Confirm EC2-to-RDS security group access on TCP 3306.
3. Confirm runtime DB environment/parameter values without printing secrets.
4. Review application logs for connection errors.
5. Do not make RDS public as a troubleshooting shortcut.

## Rollback

The deployment process must retain the previous image identifier.

```text
new version -> health check fails -> stop/remove new container -> start previous version -> verify health
```

Rollback should use an immutable tag/digest, never `latest`.

## EC2 Access

Preferred operational access:

```text
AWS Systems Manager Session Manager -> EC2
```

SSH is temporary during initial bootstrap only and should be restricted or removed once SSM access is confirmed.

## Cost Incident

If AWS usage unexpectedly increases:

1. Stop nonessential EC2 workloads.
2. Inspect RDS/EC2/ECR/CloudWatch usage.
3. Check for NAT Gateway, load balancer, provisioned capacity, snapshots, or other unexpected resources.
4. Review Billing and Free Tier dashboards.
5. Destroy nonessential infrastructure only after confirming data/backups requirements.

## Security Incident

If a secret is exposed:

1. Rotate/revoke the credential immediately.
2. Remove it from active configuration.
3. Review Git history and CI logs.
4. Replace the credential in the secure store.
5. Review IAM and access logs.

Never paste credentials into an issue, PR, README, or chat.

## Recovery

A complete rebuild should be possible from:
- Git repository;
- Terraform configuration;
- secure runtime parameters;
- RDS backup/snapshot;
- container image in ECR.

The recovery process should be tested before calling the environment production-ready.