# Future Enhancements

- OpenTofu 1.10.x: Migrate to S3 lock files
- Centralize configuration (account IDs, regions)
- Pre-commit hooks (fmt, validate, tflint, checkov, gitleaks)
- Documentation: Architecture diagrams
- Atlantis Integration: Deploy Atlantis web server for manual apply approval (prod environments)
- Hybrid workflow: GitHub Actions (validation) + Atlantis (apply)
- Enhanced Testing: Terratest (unit tests), Trivy (security scan), Infracost (cost estimation)
- Compliance scanning: Checkov, tfsec
- Multi-Region Support: Cross-region state replication.
- Disaster recovery, region failover
- Audit: CloudTrail integration, CloudWatch dashboards
- Notifications: Slack/Teams channel: Apply results, drift alerts, failures
- Drift Detection: Daily scheduled checks, Auto-remediation options
