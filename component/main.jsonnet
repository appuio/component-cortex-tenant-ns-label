local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local inv = kap.inventory();
local params = inv.parameters.cortex_tenant_ns_label;

local namespace_meta = {
  metadata+: {
    namespace: params.namespace,
  },
};

local namespace = kube.Namespace(params.namespace);

local secret = kube.Secret(params.app_name) + namespace_meta {
  stringData: {
    CONFIG: std.manifestYamlDoc(params.config),
  },
};


local deployment = kube.Deployment('cortex-tenant-ns-label') + namespace_meta {
  spec+: {
    template+: {
      metadata+: {
        labels+: {
          app: 'cortex-tenant-ns-label',
        },
      },
      spec+: {
        containers_:: {
          [params.app_name]: kube.Container(params.app_name) {
            image: '%(registry)s/%(repository)s:%(tag)s' % params.image,
            resources: {
              limits: {
                cpu: params.limits.cpu,
                memory: params.limits.memory,
              },
              requests: {
                cpu: params.requests.cpu,
                memory: params.requests.memory,
              },
            },
            ports_:: {
              http: { containerPort: 8080 },
            },
            livenessProbe: {
              httpGet: {
                path: '/alive',
                port: 8080,
              },
              initialDelaySeconds: 30,
              periodSeconds: 30,
            },
            envFrom: [
              {
                secretRef: {
                  name: secret.metadata.name,
                },
              },
            ],
          },
        },
        serviceAccountName+: params.app_name,
      },
    },
  },
};

local service = kube.Service('cortex-tenant-ns-label') + namespace_meta {
  target_pod:: deployment.spec.template,
  target_container_name:: params.app_name,
};

local service_account = kube.ServiceAccount(params.app_name) + namespace_meta {
};

local cluster_role = kube.ClusterRole(params.app_name + ':namespace-reader') {
  rules: [
    { apiGroups: [ '' ], resources: [ 'namespaces' ], verbs: [ 'get', 'list' ] },
  ],
};

local cluster_role_binding = kube.ClusterRoleBinding(params.app_name + '-namespace-reader') {
  subjects_: [ service_account ],
  roleRef_: cluster_role,
};

local network_policy = kube.NetworkPolicy('allow-from-prometheus') + namespace_meta {
  spec: {
    ingress: [
      {
        from: [
          { podSelector: { matchLabels: { prometheus: 'k8s' } } },
          { namespaceSelector: { matchLabels: { 'kubernetes.io/metadata.name': 'openshift-monitoring' } } },
        ],
        ports: [ { port: 8080, protocol: 'TCP' } ],
      },
      {
        from: [
          { podSelector: { matchLabels: { prometheus: 'user-workload' } } },
          { namespaceSelector: { matchLabels: { 'kubernetes.io/metadata.name': 'openshift-user-workload-monitoring-namespace' } } },
        ],
        ports: [ { port: 8080, protocol: 'TCP' } ],
      },
    ],
    podSelector: {
      matchLabels: {
        name: 'cortex-tenant-ns-label',
      },
    },
    policyTypes: [ 'Ingress' ],
  },
};

[
  cluster_role,
  namespace,
  service_account,
  cluster_role_binding,
  deployment,
  service,
  secret,
  network_policy,
]
