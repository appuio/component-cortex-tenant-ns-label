local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.cortex_tenant_ns_label;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('cortex-tenant-ns-label', params.namespace);

{
  'cortex-tenant-ns-label': app,
}
