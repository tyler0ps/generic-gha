# Karpenter NodePool - Defines node provisioning behavior and limits
# This tells Karpenter HOW and WHEN to provision nodes

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}

      # AMI selector - use latest EKS-optimized AMI for AL2023
      amiSelectorTerms:
        - alias: al2023@latest

      # Subnet and security group discovery using tags
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.project}-${var.environment}
            kubernetes.io/role/internal-elb: "1"

      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.project}-${var.environment}

      # Additional tags for EC2 instances
      tags:
        Name: ${var.project}-${var.environment}-karpenter-node
        Project: ${var.project}
        Environment: ${var.environment}
        ManagedBy: Karpenter
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      # Template for nodes that Karpenter will create
      template:
        metadata:
          labels:
            workload-type: general
        spec:
          # Use the EC2NodeClass defined above
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default

          # Requirements for node selection
          requirements:
            # Architecture - x86_64 for broad compatibility
            - key: kubernetes.io/arch
              operator: In
              values: ["arm64"]

            # Operating system
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]

            # Capacity type - prioritize SPOT for cost savings (90% cheaper)
            # Karpenter will use ON_DEMAND if SPOT is unavailable
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]

            # Instance categories - focus on cost-optimized types
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r"]

            # Instance generations - use newer generations for better price/performance
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["4"]

            # Instance sizes - small to xlarge for flexibility
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["medium", "large", "xlarge"]

          # Taints - none for general workloads
          # If you want to reserve these nodes for specific workloads, add taints here

      # Limits - IMPORTANT: Prevents unlimited scaling
      limits:
        # Maximum total CPU across all Karpenter-managed nodes
        cpu: "100"
        # Maximum total memory across all Karpenter-managed nodes
        memory: "200Gi"

      # Disruption - controls how Karpenter consolidates and replaces nodes
      disruption:
        # Consolidation - automatically remove underutilized nodes
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s

        # Budget - limits how many nodes can be disrupted at once
        budgets:
          - nodes: "10%"  # Max 10% of nodes can be disrupted at once
            # schedule: "0 9 * * Mon-Fri"  # Optional: only during business hours

      # Weight - priority when multiple NodePools exist (higher = preferred)
      weight: 10
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
