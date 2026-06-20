apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  name: ${USER_NAME}-ingress
  namespace: ${NAMESPACE}
spec:
  ingressClassName: public-nginx
  rules:
  - host: ${INGRESS_HOST}
    http:
      paths:
      - backend:
          service:
            name: ${USER_NAME}-${SERVICE_NAME}
            port:
              number: 8080
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - '${INGRESS_HOST}'
    secretName: ${USER_NAME}-ingress-tls-cert
