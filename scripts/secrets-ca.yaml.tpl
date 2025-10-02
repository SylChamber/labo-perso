# Gabarit de secrets pour la gestion de certificats avec step-ca
---
# Source: step-certificates/templates/secrets.yaml
# Mot de passe du CA intermédiaire
apiVersion: v1
kind: Secret
type: smallstep.com/ca-password
metadata:
  name: acme-step-certificates-ca-password
  namespace: ${CA_NAMESPACE}
data:
  password: ${INTERMEDIATE_TLS_PASSWORD_B64}
---
# Source: step-certificates/templates/secrets.yaml
apiVersion: v1
kind: Secret
type: smallstep.com/provisioner-password
metadata:
  name: acme-step-certificates-provisioner-password
  namespace: ${CA_NAMESPACE}
data:
  password: ${JWK_PROVISIONER_PASSWORD_B64}
---

