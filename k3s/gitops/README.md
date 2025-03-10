# GitOps - gestion des applications avec Argo CD

## Prérequis

- `operator-sdk`
- `Operator Lifecycle Manager` (OLM) installé avec `operator-sdk`
- `Argo CD Operator` installé (et une `Subscription` dans le namespace `operators`)

> À faire: automatiser ici-même l'installation des prérequis avec `go-task`.
> Voir [github.com/SylChamber/tools](https://github.com/SylChamber/tools).
> `operator-sdk olm install`
> `kubectl apply -f argocd-olm-sub.yaml`

Définir un namespace `argocd`:

```shell
kubectl apply -f argocd-ns.yaml
```

Créer un `OperatorGroup` dans le namespace `argocd` pour déclarer les `namespaces` que l'opérateur surveillera pour de nouvelles ressources.

```shell
kubectl apply -f argocd-og.yaml
```

## Installation d'Argo CD en mode _cluster-wide_ (_cluster admin_)

```shell
kubectl apply -f argocd-instance.yaml
```

## Références

- [Argo CD Operator - Operator Lifecycle Manager - Install](https://argocd-operator.readthedocs.io/en/latest/install/olm/)
- [Argo CD Operator - Reference - ArgoCD CRD](https://argocd-operator.readthedocs.io/en/latest/reference/argocd/)
