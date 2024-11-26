# JustBigThings

Garry's Mod addon that adds some tweaks related to big players

### Convars
- `jbt_biguse_enabled` Whether to enable the big use module (default 1)
- `jbt_biguse_adminonly` Whether big usage is for admins only (default 0)
- `jbt_biguse_mass_enabled` Whether big players can carry heavier props (default 1)
- `jbt_biguse_mass_pow` The power of the amount of mass big players can carry (default 2)
- `jbt_pac_sizelimit_enabled` Whether to enable the pac size limit module (default 1)
- `jbt_pac_sizelimit_adminonly` Whether the modified size limit is for admins only (default 1)
- `jbt_pac_sizelimit_max` How much the pac size max is modified (default 100) (pac3 default 10)
- `jbt_pac_sizelimit_min` How much the pac size min is modified (defalt 0.01) (pac3 default 0.1)
- `jbt_sitanywhere_bigtrace_enabled` Whether to enable the sit anywhere module (default 1)
- `jbt_sitanywhere_bigtrace_adminonly` Whether sitanywhere trace scaling should only be for admins (default 0)
- `jbt_sitanywhere_bigtrace_distance` What the base distance check should be for sitting (default 100)
- `jbt_adminonly_is_superadminonly` Whether 'adminonly' settings should actually be superadmin only (default 0)
- `jbt_cl_bigsit` Whether player size should affect the camera view while sitting (default 1)

### Permissions (SAM exclusive)
- `jbt_pac_sizelimit` Override the adminonly setting of the pac size limit module
- `jbt_sitanywhere_bigtrace` Override the adminonly setting of the sitanywhere big trace module
- `jbt_biguse` Override the adminonly setting of the big use module
