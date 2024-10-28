### RBAC Escalation Process for CaaS Operators

In a Kubernetes-based Container-as-a-Service (CaaS) environment, operators require different access levels to perform their roles securely and efficiently. This RBAC escalation model enforces minimal access by default, with controlled, elevated permissions only when necessary. This approach enhances security by restricting unauthorized changes and ensuring that critical operations are performed only with the appropriate approvals.

This model defines three levels of operator roles, with **Kubernetes Read Role** required as the baseline for access and activated through **Privileged Identity Management (PIM)**. This ensures access is granted securely and on demand:

1. **T2 (Read-Only Access)**: Assigned by default for general visibility, allowing observation without modification.
2. **T1 (Day-to-Day Operations)**: Activated through PIM groups for operators performing regular platform management tasks.
3. **T0 (Cluster Admin / Break-the-Glass)**: Requires peer-reviewed activation through PIM, granting full administrative privileges for urgent, critical scenarios.

The escalation from T2 to T0 follows a carefully controlled process. Key principles include:

- **Minimal Access by Default**: All users start with T2 (Read-Only Access), providing baseline visibility without modification rights.
- **Controlled Operational Access**: T1 (Day-to-Day Operations) is available for operators who need to perform standard tasks. This access level is granted through PIM group activation.
- **Break-the-Glass for Critical Incidents**: T0 (Cluster Admin) access is reserved for problem and incident management, requiring peer-reviewed approval through PIM. Only trusted personnel can assume full administrative control for urgent actions.

### Role Breakdown

```mermaid
flowchart TD
    T2["T2: Read-Only Access"] --> T1["T1: Day-to-Day Operations"]
    T1 --> T0["T0: Cluster Admin (Break-the-Glass)"]

    T2 -- "Default access for cluster visibility; read-only permissions" --> T2Info["Use for: Observing cluster health and resource states without modification rights"]
    T1 -- "Activated via PIM groups; enables workload and platform management" --> T1Info["Use for: Routine operations, such as scaling applications and updating configurations, excluding access to secrets"]
    T0 -- "Break-the-glass access; requires peer-reviewed activation in PIM" --> T0Info["Use for: High-priority problem or incident management, with full admin access for urgent cluster-wide tasks"]

    subgraph PIM ["Privileged Identity Management (PIM)"]
        T1Role["Kubernetes Read Role Activation Required"]
        T2Role["Kubernetes Read Role Activation Required"]
    end
    
    T2Role --> T2
    T1Role --> T1

    style T2 fill:#BBE1FA,stroke:#333,stroke-width:2px
    style T1 fill:#3282B8,stroke:#333,stroke-width:2px
    style T0 fill:#1B262C,stroke:#333,stroke-width:2px
    style PIM fill:#EEEEEE,stroke:#888,stroke-width:1px,stroke-dasharray: 5 5