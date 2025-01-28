# GCP Service Selection Matrix - ACE Certification

## Quick Decision Matrix

| Catégorie | Signal Mots-Clés | Service Recommandé | 🚨 Points d'Attention | ✅ Alternative |
|-----------|------------------|-------------------|---------------------|----------------|
| **Compute - Serverless** |
| | • minimal setup<br>• event-driven<br>• trigger on change<br>• automate tasks | Cloud Functions | Limité à 60min d'exécution | Cloud Run |
| | • containerized<br>• microservices<br>• Docker<br>• variable load | Cloud Run | Doit être conteneurisé | Cloud Functions |
| | • need Kubernetes<br>• container orchestration<br>• pods & clusters | GKE | Plus complexe à gérer | Cloud Run |
| | • full VM control<br>• specific OS<br>• custom hardware | Compute Engine | Plus de maintenance | GKE |

| **Storage & Database** | Signal Mots-Clés | Service Recommandé | 🚨 Points d'Attention | ✅ Alternative |
|-----------|------------------|-------------------|---------------------|----------------|
| | • files/objects<br>• static content<br>• images/videos<br>• lifecycle management | Cloud Storage | Coût varie selon classe de stockage | Filestore |
| | • ad-hoc queries<br>• data warehouse<br>• analytics<br>• large datasets | BigQuery | Coût basé sur données scannées | Cloud Spanner |
| | • high-speed reads/writes<br>• IoT data<br>• time series<br>• petabyte scale | Cloud Bigtable | Schéma doit être simple | Cloud Spanner |
| | • relational database<br>• traditional SQL<br>• structured data | Cloud SQL | Limité en scale | Cloud Spanner |

| **Networking** | Signal Mots-Clés | Service Recommandé | 🚨 Points d'Attention | ✅ Alternative |
|-----------|------------------|-------------------|---------------------|----------------|
| | • connect on-premises<br>• secure connection<br>• bridge networks | Cloud VPN | Limité par bande passante | Cloud Interconnect |
| | • distribute traffic<br>• global access<br>• high availability | Load Balancer | Configuration complexe | DNS round-robin |
| | • internal services<br>• service discovery<br>• DNS names | Cloud DNS | Coût par zone | Internal DNS |

| **Security & IAM** | Signal Mots-Clés | Service Recommandé | 🚨 Points d'Attention | ✅ Alternative |
|-----------|------------------|-------------------|---------------------|----------------|
| | • user permissions<br>• access control<br>• role management | IAM | Toujours utiliser des groupes | Service Accounts |
| | • service auth<br>• automated tasks<br>• application identity | Service Accounts | Gérer rotation des clés | Workload Identity |
| | • audit requirements<br>• track changes<br>• monitoring | Cloud Audit Logs | Coût de stockage | Cloud Logging |

| **Data Processing** | Signal Mots-Clés | Service Recommandé | 🚨 Points d'Attention | ✅ Alternative |
|-----------|------------------|-------------------|---------------------|----------------|
| | • real-time<br>• events<br>• message queue<br>• decouple services | Pub/Sub | Ordre messages non garanti | Cloud Tasks |
| | • ETL<br>• data pipeline<br>• stream processing | Dataflow | Complexe à configurer | Cloud Functions |
| | • scheduled tasks<br>• batch processing<br>• recurring jobs | Cloud Scheduler | Limites de fréquence | Compute Engine |

## Indicateurs de Décision Rapide

### 🎯 Indicateurs de Coût
- "cost-effective" → Services managés / serverless
- "minimize maintenance" → Solutions entièrement gérées
- "optimize spending" → Utiliser autoscaling
- "budget constraints" → Consider preemptible/spot VMs

### 🔧 Indicateurs de Performance
- "high performance" → Services régionaux
- "global scale" → Multi-région / Global load balancer
- "real-time" → Pub/Sub / Cloud Functions
- "high availability" → Solutions redondantes

### 🔒 Indicateurs de Sécurité
- "sensitive data" → Encryption / IAM / VPC
- "compliance" → Cloud Audit Logs
- "secure access" → IAM avec groupes
- "authentication" → Identity-Aware Proxy

### 🚀 Indicateurs de Scale
- "unpredictable load" → Autoscaling
- "global users" → Multi-région
- "growing rapidly" → Services managés
- "variable traffic" → Serverless

## Guide des Meilleures Pratiques

1. **Toujours privilégier**:
   - Groupes sur utilisateurs individuels
   - Services managés sur self-managed
   - Predefined roles sur custom roles
   - Automatisation sur actions manuelles

2. **Éviter**:
   - Basic roles (trop larges)
   - Solutions sur-mesure si solution managée existe
   - Configuration manuelle des ressources
   - Permissions individuelles

3. **Optimisation des coûts**:
   - Utiliser autoscaling
   - Implémenter lifecycle management
   - Monitorer avec budgets et alertes
   - Utiliser les classes de stockage appropriées

4. **Sécurité**:
   - Principe du moindre privilège
   - Audit logging activé
   - Encryption par défaut
   - Service accounts pour les services

## 🎯 Scénarios Communs

| Scénario | Solution Typique | Justification |
|----------|-----------------|----------------|
| Migration données (>100TB) | Transfer Appliance | Plus rapide et économique |
| Connexion on-premises | Cloud VPN | Simple et sécurisé |
| Microservices | Cloud Run | Facile à gérer, scalable |
| Analytics ad-hoc | BigQuery | Performant pour requêtes complexes |
| Event-driven automation | Cloud Functions | Simple à implémenter |
| Container orchestration | GKE | Robuste et flexible |
