
# Climate X Operations Challenge

## Quickstart

- Fork this repo
- Select one challenge from the list below
- Complete it within a week, spending 2 to 3 hours on it
- Include a README.md with any required setup instructions
- Include a NOTES.md (feel free to choose a different name) documenting potential extensions or work-in-progress items
- Get in touch with your hiring representative to schedule a review
- Share your solution with us (this can be a public repository, a private repository, a signed S3 URL, or other solutions. Please do not email a zip file)


## Details

This repo contains 3 potential challenges for a DevOps/SRE/Platform Engineer role. These challenges are taken from our own history, and represent real-world problems we've seen and solved.

The candidate is expected to pick only ONE of these challenges to address and prepare a solution. The candidate does not need to submit this solution somewhere; instead we will review it during the live technical session. We will either make recommendations and suggestions to implement to form the live development task, or we will start from one of the not-attempted challenges; whichever option the interviewer feels best demonstartes the skills of the candidate.

It is strongly recommended that the candidate has a way to execute the solution they provide, maybe by preparing an environment ahead of the session.

## Challenges

### Challenge 1: Multi-Environment Terraform State Management

A developer accidentally ran `terraform apply` in the wrong environment directory, causing production resources to be modified when they intended to modify staging. This incident highlighted a critical gap in our infrastructure management process.

**Your Task**: Design and implement a solution to prevent cross-environment state corruption and accidental modifications to production infrastructure. The solution should:

- Prevent developers from accidentally applying changes to the wrong environment
- Provide clear feedback when incorrect state files are accessed
- Work seamlessly with existing CI/CD pipelines
- Be maintainable and not overly restrictive for legitimate operations

**Deliverables**:
- A detailed design document explaining your approach
- Implementation code (Terraform, scripts, CI/CD configurations, etc.)
- Documentation on how to use and maintain the solution
- Testing strategy to validate the safeguards work correctly

---

### Challenge 2: Observability Pipeline for New Service

A new microservice needs to be integrated into our existing Grafana Cloud observability stack. The service currently has no instrumentation and needs to send metrics, traces, and logs through our Alloy gateway collector to Grafana Cloud.

**Your Task**: Create a complete observability setup for a new service including:

- OpenTelemetry instrumentation configuration for the service
- Alloy collector configuration updates to receive telemetry from the new service
- Grafana dashboards for key service metrics (request rate, latency, error rate, etc.)
- Alerting rules for common failure scenarios (high error rate, latency spikes, service unavailable)
- Documentation explaining the setup and how to interpret the dashboards

**Deliverables**:
- Instrumentation code/configuration for the service
- Updated Alloy configuration
- Grafana dashboard JSON files
- Alerting rule definitions
- Setup and usage documentation

**Note**: You can use a simple example service (e.g., a basic HTTP API) to demonstrate the instrumentation.

---

### Challenge 3: Database Connection Pooling and Failover

Our Aurora PostgreSQL cluster is experiencing connection exhaustion during peak loads. Multiple services are unable to establish database connections, causing timeouts and service degradation. The cluster serves multiple services across different VPCs (as configured in our security groups).

**Your Task**: Design and implement a solution that:

- Implements connection pooling to efficiently manage database connections
- Handles Aurora failover scenarios gracefully without service disruption
- Provides monitoring and alerting for connection pool health
- Works across multiple VPCs (as our current Aurora setup requires)
- Includes documentation on configuration, monitoring, and troubleshooting

**Deliverables**:
- Architecture design document
- Infrastructure code (Terraform modules, configuration files)
- Monitoring dashboards and alerting rules
- Documentation covering setup, configuration, and operational procedures
- Testing strategy for failover scenarios

**Considerations**: You may choose between solutions like RDS Proxy, PgBouncer, or application-level connection pooling. Justify your choice based on the requirements.
