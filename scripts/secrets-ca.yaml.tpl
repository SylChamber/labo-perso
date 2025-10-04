# Gabarit de secrets pour la gestion de certificats avec step-ca
---
# Source: step-certificates/templates/secrets.yaml
# Mot de passe du CA intermédiaire
apiVersion: v1
kind: Secret
type: smallstep.com/ca-password
metadata:
  name: ${CA_CHART_FULLNAME}-ca-password
  namespace: ${CA_NAMESPACE}
data:
  password: ${INTERMEDIATE_TLS_PASSWORD_B64}
---
# Source: step-certificates/templates/secrets.yaml
apiVersion: v1
kind: Secret
type: smallstep.com/provisioner-password
metadata:
  name: ${CA_CHART_FULLNAME}-provisioner-password
  namespace: ${CA_NAMESPACE}
data:
  password: ${JWK_PROVISIONER_PASSWORD_B64}
---
# Source: step-certificates/templates/secrets.yaml
apiVersion: v1
kind: Secret
type: smallstep.com/private-keys
metadata:
  name: ${CA_CHART_FULLNAME}-secrets
  namespace: ${CA_NAMESPACE}
stringData:
  intermediate_ca_key: |-
${INTERMEDIATE_CA_KEY}

  root_ca_key: |-
${ROOT_CA_KEY}
---
# Source: step-certificates/templates/configmaps.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CA_CHART_FULLNAME}-certs
  namespace: ${CA_NAMESPACE}
data:
  intermediate_ca.crt: |-
${INTERMEDIATE_CA_CRT}

  root_ca.crt: |-
${ROOT_CA_CRT}
---
# Source: step-certificates/templates/configmaps.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CA_CHART_FULLNAME}-config
  namespace: ${CA_NAMESPACE}
data:
  ca.json: |
    {
      "address": ":9100",
      "authority": {
        "claims": {
          "defaultHostSSHCertDuration": "720h",
          "defaultTLSCertDuration": "2160h",
          "defaultUserSSHCertDuration": "24h",
          "disableRenewal": false,
          "maxHostSSHCertDuration": "1680h",
          "maxTLSCertDuration": "2160h",
          "maxUserSSHCertDuration": "24h",
          "minHostSSHCertDuration": "5m",
          "minTLSCertDuration": "5m",
          "minUserSSHCertDuration": "5m"
        },
        "enableAdmin": false,
        "provisioners": [
          {
            "encryptedKey": "${JWK_PROVISIONER_ENCRYPTED_KEY}",
            "key":
${JWK_PROVISIONER_KEY},
            "name": "admin",
            "options": {
              "ssh": {},
              "x509": {}
            },
            "type": "JWK"
          },
          {
            "name": "acme",
            "type": "ACME"
          }
        ]
      },
      "crt": "/home/step/certs/intermediate_ca.crt",
      "db": {
        "dataSource": "/home/step/db",
        "type": "badgerv2"
      },
      "dnsNames": ${CA_DNS_NAMES},
      "federateRoots": [],
      "key": "/home/step/secrets/intermediate_ca_key",
      "logger": {
        "format": "json"
      },
      "root": "/home/step/certs/root_ca.crt",
      "tls": {
        "cipherSuites": [
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ],
        "maxVersion": 1.3,
        "minVersion": 1.2,
        "renegotiation": false
      }
    }
  defaults.json: |
    {
      "ca-config": "/home/step/config/ca.json",
      "ca-url": "${CA_URL}",
      "fingerprint": "${ROOT_CA_FINGERPRINT}",
      "root": "/home/step/certs/root_ca.crt"
    }
  ssh.tpl: |
    {
      "type": {{ toJson .Type }},
      "keyId": {{ toJson .KeyID }},
      "principals": {{ toJson .Principals }},
      "extensions": {{ toJson .Extensions }},
      "criticalOptions": {{ toJson .CriticalOptions }}
    }
    
  x509_leaf.tpl: |
    {
      "subject": {{ toJson .Subject }},
      "sans": {{ toJson .SANs }},
    {{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
      "keyUsage": ["keyEncipherment", "digitalSignature"],
    {{- else }}
      "keyUsage": ["digitalSignature"],
    {{- end }}
      "extKeyUsage": ["serverAuth", "clientAuth"]
    }
