# ArgoCD Implementation Plan

## Overview
Deploy ArgoCD via Terraform and set up GitOps for service deployments. This plan tracks the implementation phase by phase, with each service deployed one at a time.

**Services to Deploy:**
- ✅ **api-golang** (Go API service) - Port 8080
- ✅ **api-node** (Node.js API service) - Port 3000
- ✅ **client-react** (React frontend) - Port 8080
- ✅ **load-generator-python** (Python load testing)

**Environments:**
- **Staging**: Auto-sync enabled, running on EKS cluster
- **Production**: Manual sync required (to be set up)

---

## Phase 1: Deploy ArgoCD Infrastructure via Terraform

### 1.1 Create ArgoCD Terraform Module
**Location:** `terraform/modules/argocd/`

**Files to create:**
- [ ] `main.tf` - ArgoCD Helm chart deployment
- [ ] `variables.tf` - Configuration variables
- [ ] `outputs.tf` - ArgoCD server URL and credentials
- [ ] `iam.tf` - IRSA role for ArgoCD (optional)
- [ ] `versions.tf` - Provider requirements

**Key configuration:**
- Deploy via Helm chart (argo-cd v7.7.12+)
- Enable IRSA for AWS permissions
- Run on Karpenter Spot nodes for cost optimization
- Configure ALB ingress for UI access
- Enable metrics for monitoring

### 1.2 Integrate ArgoCD into Staging EKS
**Location:** `terraform/environments/staging/3-eks/`

**Changes:**
- [ ] Add ArgoCD module call to `main.tf`
- [ ] Add ArgoCD outputs to `outputs.tf`
- [ ] Run `terraform plan` to verify
- [ ] Run `terraform apply` to deploy
- [ ] Verify ArgoCD pods are running

**Validation:**
```bash
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access UI at https://localhost:8080
```

---

## Phase 2: Restructure Kubernetes Manifests for GitOps

### 2.1 Create Kustomize Base + Overlay Structure

**New directory structure:**
```
deploy/kubernetes/
├── base/                      # Shared base manifests
│   ├── api-golang/
│   ├── api-node/
│   ├── client-react/
│   └── load-generator-python/
├── overlays/
│   ├── staging/               # Staging-specific patches
│   └── production/            # Production-specific patches
└── staging/                   # DEPRECATED (keep for reference)
```

**Tasks:**
- [ ] Create base manifests for all 4 services
- [ ] Create staging overlays with current configurations
- [ ] Create production overlays (higher replicas, prod image tags)
- [ ] Create load-generator-python manifests (currently missing)
- [ ] Add kustomization.yaml files at each level
- [ ] Test with `kustomize build deploy/kubernetes/overlays/staging`

### 2.2 Environment-Specific Configuration

**Staging:**
- 1 replica per service
- Extended version tags (e.g., `1.3.3-0019-g89447fe`)
- Resource limits: 250m CPU / 512Mi memory

**Production:**
- 3+ replicas per service
- Simple version tags (e.g., `1.3.3`)
- Higher resource limits
- Manual sync only (no auto-deploy)

---

## Phase 3: Create ArgoCD Application Resources

### 3.1 Create ArgoCD Configuration Directory
**Location:** `deploy/argocd/`

**Files to create:**
- [ ] `bootstrap/root-app.yaml` - App of Apps pattern
- [ ] `applicationsets/services.yaml` - ApplicationSet for all services
- [ ] `projects/staging-project.yaml` - RBAC for staging
- [ ] `projects/production-project.yaml` - RBAC for production

### 3.2 Deploy ApplicationSet
**Strategy:** Use ApplicationSet with matrix generator

**Benefits:**
- Single YAML manages all services across environments
- Automatic propagation of new services
- Environment-specific sync policies (auto vs manual)

**Matrix generator:**
- Services: [api-golang, api-node, client-react, load-generator-python]
- Environments: [staging, production]
- Result: 8 applications (4 services × 2 environments)

---

## Phase 4: Service-by-Service Rollout (Staging)

### Service 1: client-react (Frontend)
**Why first:** No database dependencies, easiest to test

- [ ] Deploy client-react to staging via ArgoCD
- [ ] Verify health checks pass
- [ ] Test ALB routing to `/*`
- [ ] Monitor for 24 hours
- [ ] Test rollback procedure

**Validation:**
```bash
argocd app get client-react-staging
kubectl get pods -n staging -l app=client-react
curl http://<ALB-URL>/
```

### Service 2: api-golang (Backend API)
**Why second:** Core API with database connectivity

- [ ] Run database migration job first
- [ ] Deploy api-golang to staging via ArgoCD
- [ ] Verify database connectivity
- [ ] Test API endpoints at `/api/golang/ping`
- [ ] Monitor for 24 hours
- [ ] Test rollback procedure

**Validation:**
```bash
argocd app get api-golang-staging
kubectl get pods -n staging -l app=api-golang
curl http://<ALB-URL>/api/golang/ping
```

### Service 3: api-node (Backend API)
**Why third:** Secondary API, tests inter-service communication

- [ ] Deploy api-node to staging via ArgoCD
- [ ] Verify inter-service communication
- [ ] Test API endpoints at `/api/node/health`
- [ ] Monitor for 24 hours
- [ ] Test rollback procedure

**Validation:**
```bash
argocd app get api-node-staging
kubectl get pods -n staging -l app=api-node
curl http://<ALB-URL>/api/node/health
```

### Service 4: load-generator-python (Load Testing)
**Why last:** Utility service, minimal dependencies

- [ ] Create manifests (currently missing)
- [ ] Deploy load-generator-python to staging via ArgoCD
- [ ] Run load tests against APIs
- [ ] Verify metrics collection
- [ ] Monitor for 24 hours

**Validation:**
```bash
argocd app get load-generator-python-staging
kubectl get pods -n staging -l app=load-generator-python
kubectl logs -n staging -l app=load-generator-python
```

---

## Phase 5: Production Environment Setup

### 5.1 Production Infrastructure
**Decision needed:** Same cluster or separate?

**Option A: Same cluster, different namespace**
- [ ] Create production namespace
- [ ] Deploy production overlays
- [ ] Configure separate ALB/ingress
- [ ] Update network policies

**Option B: Separate production cluster**
- [ ] Create production EKS environment
- [ ] Deploy ArgoCD to production cluster
- [ ] Set up multi-cluster management

### 5.2 Production Readiness
- [ ] Production manifests created and tested
- [ ] Secrets migrated to production
- [ ] RBAC configured for production
- [ ] Monitoring and alerts configured
- [ ] Disaster recovery plan documented
- [ ] Rollback procedures tested

---

## Phase 6: Service-by-Service Rollout (Production)

### Production Deployment Strategy
**Manual sync required for all production apps**

- [ ] **client-react-production**: Deploy, run smoke tests, monitor 48h
- [ ] **api-golang-production**: Deploy, run migrations, monitor 48h
- [ ] **api-node-production**: Deploy, verify traffic, monitor 48h
- [ ] **load-generator-python-production**: Deploy, configure schedule, monitor 48h

**Production Validation Checklist (per service):**
```bash
# Manual sync (no auto-deploy in prod)
argocd app sync <service>-production --prune

# Wait for healthy status
argocd app wait <service>-production --health

# Verify pods
kubectl get pods -n production -l app=<service>

# Test endpoints
curl http://<PROD-ALB-URL>/<service-path>

# Check logs
kubectl logs -n production -l app=<service> --tail=100
```

---

## Phase 7: CI/CD Integration

### 7.1 Update GitHub Actions Workflows
**File:** `.github/workflows/update-gitops-manifests.yaml`

**Changes:**
- [ ] Update to use `kustomize edit set image` instead of direct file edits
- [ ] Commit changes to overlay kustomization.yaml files
- [ ] Optional: Trigger ArgoCD sync via CLI after commit

### 7.2 Create ArgoCD Sync Workflow
**New file:** `.github/workflows/argocd-sync.yaml`

**Purpose:** Manual trigger for syncing specific applications

- [ ] Create workflow with service/environment selection
- [ ] Install ArgoCD CLI
- [ ] Authenticate to cluster
- [ ] Trigger sync and wait for health

---

## Phase 8: Decommission Old Deployment Process

### 8.1 Clean Up
- [ ] Archive old manifests in `deploy/kubernetes/staging/` (mark as deprecated)
- [ ] Remove manual `kubectl apply` commands from documentation
- [ ] Update README with ArgoCD instructions
- [ ] Remove or update old deployment scripts

### 8.2 Documentation
- [ ] Document ArgoCD access and credentials
- [ ] Create runbook for common operations (sync, rollback, troubleshoot)
- [ ] Update team training materials
- [ ] Document GitOps workflow (commit → auto-sync → deploy)

---

## Progress Tracking

### Overall Status
- [ ] Phase 1: ArgoCD Infrastructure ⏳
- [ ] Phase 2: Manifest Restructuring ⏳
- [ ] Phase 3: ArgoCD Applications ⏳
- [ ] Phase 4: Staging Rollout ⏳
- [ ] Phase 5: Production Setup ⏳
- [ ] Phase 6: Production Rollout ⏳
- [ ] Phase 7: CI/CD Integration ⏳
- [ ] Phase 8: Decommission Old Process ⏳

### Service Deployment Status

| Service | Staging | Production | Notes |
|---------|---------|------------|-------|
| client-react | ⏳ Not deployed | ⏳ Not deployed | Deploy first |
| api-golang | ⏳ Not deployed | ⏳ Not deployed | Requires DB migration |
| api-node | ⏳ Not deployed | ⏳ Not deployed | - |
| load-generator-python | ⏳ Not deployed | ⏳ Not deployed | Manifests need creation |

Legend: ⏳ Not Started | 🔄 In Progress | ✅ Completed | ❌ Failed

---

## Rollback Procedures

### Quick Rollback via ArgoCD
```bash
# View deployment history
argocd app history <app-name>

# Rollback to previous version
argocd app rollback <app-name> <revision-id>

# Sync and wait
argocd app sync <app-name>
argocd app wait <app-name> --health
```

### Emergency Rollback via Git
```bash
# Revert commit with bad image tag
git revert <commit-sha>
git push origin main

# ArgoCD will auto-sync (staging) or manual sync (production)
argocd app sync <app-name>
```

---

## Cost Optimization

### Estimated Costs
- **ArgoCD components**: ~750m CPU, 1.5Gi memory
- **Expected node**: 1x t3.small Spot (~$7/month)
- **Karpenter consolidation**: Removes idle nodes after 30s
- **Spot instances**: 60-70% cost savings vs On-Demand

### Monitoring
- [ ] Set up CloudWatch alarms for unexpected node scaling
- [ ] Monitor ArgoCD metrics via Prometheus
- [ ] Review monthly AWS costs for EKS cluster

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| ArgoCD failure | Cannot deploy | Run on stable nodes, enable HA, document manual kubectl apply |
| Wrong image in prod | Service outage | Manual sync only, approval gates, staging testing |
| Manifest syntax error | Deployment fails | CI validation with kustomize build, dry-run |
| Secret exposure | Security breach | RBAC, audit logs, External Secrets (future) |
| Cost spike | Budget overrun | Karpenter limits, Spot instances, monitoring |

---

## Success Criteria

### Technical Metrics
- ✅ All services deployed via ArgoCD in staging
- ✅ ArgoCD UI accessible and functional
- ✅ Auto-sync working in staging (< 3 min sync time)
- ✅ Manual sync working in production
- ✅ Zero downtime during rollout
- ✅ Rollback procedures tested and documented

### Business Metrics
- 🎯 Deployment frequency: Increase to 10+ per day
- 🎯 Mean time to recovery (MTTR): < 5 minutes
- 🎯 Failed deployment rate: < 1%
- 🎯 Infrastructure cost: Reduce by 30%

---

## Future Enhancements

### Post-Implementation (Optional)
1. **Argo Rollouts**: Progressive delivery (canary, blue-green)
2. **External Secrets Operator**: AWS Secrets Manager integration
3. **Argo CD Image Updater**: Automatic image tag updates
4. **Multi-cluster setup**: Separate production cluster
5. **Service Mesh**: Istio/Linkerd for advanced routing
6. **Policy as Code**: OPA/Gatekeeper for admission control

---

## Support and Resources

### ArgoCD Documentation
- Official docs: https://argo-cd.readthedocs.io/
- Getting started: https://argo-cd.readthedocs.io/en/stable/getting_started/

### Useful Commands
```bash
# Login to ArgoCD
argocd login <server> --username admin --password <password>

# List all applications
argocd app list

# Get application details
argocd app get <app-name>

# Sync application
argocd app sync <app-name>

# View logs
argocd app logs <app-name>

# Delete application (careful!)
argocd app delete <app-name>
```

### Team Contacts
- Infrastructure Lead: [Name]
- DevOps Lead: [Name]
- On-call rotation: [Link]

---

**Last Updated:** 2026-01-22
**Status:** Planning Phase
**Next Milestone:** Deploy ArgoCD via Terraform
