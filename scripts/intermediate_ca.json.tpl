{
  "subject": {
    "commonName": "${INTERMEDIATE_CA_NAME}",
    "organization": "${ORGANISATION}",
    "country": "${COUNTRY}",
    "province": "${PROVINCE}"
  },
  "keyUsage": [ "certSign", "crlSign" ],
  "basicConstraints": {
    "isCA": true,
    "maxPathLen": 1
  }
}