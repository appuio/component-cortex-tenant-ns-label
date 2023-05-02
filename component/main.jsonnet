local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local rl = import 'lib/resource-locker.libjsonnet';


local inv = kap.inventory();
local params = inv.parameters.cortex_tenant_ns_label;

local rules = import 'rules.jsonnet';
local capacity = import 'capacity.libsonnet';

{
  cortex_tenant_ns_label: import 'cortex-tenant-ns-label.jsonnet',
}
