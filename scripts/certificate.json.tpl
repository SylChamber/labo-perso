{
  "subject": {
    "commonName": "{{ .Subject.CommonName }}",
    "organization": "SylChamber",
    "country": "CA",
    "province": "Quebec"
  },
  "sans": {{ toJson .SANs }}
}