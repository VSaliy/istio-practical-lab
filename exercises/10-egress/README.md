# Exercise 10: Egress

## Difficulty
Intermediate

## Estimated effort
90-180 minutes

## Learning objectives
- Understand module architecture and failure modes

## Architectural context
This module builds on previous exercises and contributes to production-style Istio operations.

## Prerequisites
- Previous exercises completed
- Access to lab cluster

## Files used
- Module-specific manifests under istio/, kubernetes/, applications/, and scripts/

## Environment checks
- Verify kubectl can reach the cluster
- Verify namespace/workload readiness

## Implementation steps
1. Follow documented script/manifests sequence.
2. Apply resources incrementally.
3. Validate expected behavior after each step.

## Commands
Use explicit kubectl and istioctl commands listed for this module as they are implemented.

## Expected output
Command outputs should show successful resource creation and healthy pod status.

## Verification
Perform explicit kubectl and istioctl checks tied to the module goals.

## Failure experiments
Introduce one controlled fault and observe control/data-plane behavior.

## Troubleshooting
Use diagnostics collectors in scripts/diagnostics and docs/troubleshooting.md.

## Cleanup
Remove module-specific resources and restore baseline.

## Architectural lessons
Capture trade-offs observed between reliability, security, and operational complexity.

## Production considerations
Translate lab choices to production-safe patterns.

## Self-assessment questions
1. What failure mode was observed?
2. How was it diagnosed?
3. What policy/configuration fixed it?

## Milestone status
Detailed implementation for advanced modules is tracked as TODO for subsequent milestones.
