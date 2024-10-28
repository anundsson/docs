# RBAC Model for AKS Cluster 'CaaS'

| Persona       | Tier                    | Role in Azure RBAC     | Scope in Kubernetes   | Cluster Read Access (Azure RBAC)   |
|:--------------|:------------------------|:-----------------------|:----------------------|:-----------------------------------|
| Operator SPN  | SPN                     | Cluster Admin (Static) | Cluster-Wide          | No                                 |
| Operators     | Tier 0 - Break Glass    | Cluster Admin (PIM)    | Cluster-Wide          | Yes                                |
| Operators     | Tier 1 - Day-to-Day     | Edit Role (PIM)        | Cluster-Wide          | Yes                                |
| Operators     | Tier 2 - Read Only      | View Role (Static)     | Cluster-Wide          | Yes                                |
| Developers    | Tier 1 - Namespace Edit | Edit Role (PIM)        | Namespace-Specific    | Yes                                |
| Developers    | Tier 2 - Read Only      | View Role (Static)     | Namespace-Specific    | Yes                                |
| Developer SPN | SPN                     | Edit Role (Static)     | Namespace-Specific    | Yes                                |