# JustBigThings

Garry's Mod addon that adds some tweaks related to big (or small) players

### Client/Personal Convars (0 == off, 1 == let server decide, 2 == on)
- `jbt_cl_bigsit` Whether player size should affect the camera view while sitting (default 1)
- `jbt_cl_bigdelta` Whether your movement animations sync properly with scale (default 1)

### Server Convars
- `jbt_biguse_enabled` Whether to enable the big use module (default 1)
- `jbt_biguse_adminonly` Whether big usage is for admins only (default 0)
- `jbt_biguse_mass` Whether big players can carry heavier props (default 1)
- `jbt_biguse_mass_pow` The mathematical power of the amount of mass big players can carry (default 2)
- `jbt_biguse_small` Whether smaller players get a smaller range / mass limit for pickup (default 0)
- `jbt_pac_biglimit_enabled` Whether to enable the pac size limit module (default 1)
- `jbt_pac_biglimit_adminonly` Whether the modified size limit is for admins only (default 1)
- `jbt_pac_biglimit_max` How much the pac size max is modified (default 100) (pac3 default 10)
- `jbt_pac_biglimit_min` How much the pac size min is modified (defalt 0.01) (pac3 default 0.1)
- `jbt_bigstats_enabled` Whether to enable the big stats module (default 0)
- `jbt_bigstats_adminonly` Whether stats scaling only affects admins (default 0)
- `jbt_bigstats_health` Whether bigger players get more health (default 1)
- `jbt_bigstats_armor` Whether bigger players get more armor (default 0)
- `jbt_bigstats_speed` Whether bigger players get more speed (default 1)
- `jbt_bigstats_small` Whether stats scaling affects small players too (default 1)
- `jbt_bigdelta_enabled` Whether to enable the big delta module (default 1)
- `jbt_bigsit_enabled` Whether to enable the big sit module (default 1)
- `jbt_bigmass_enabled` Whether to enable the big mass module (default 0)
- `jbt_bigmass_pow` The mathematical power for how player mass scales with size (default 2)
- `jbt_sitanywhere_bigtrace_enabled` Whether to enable the sit anywhere module (default 1)
- `jbt_sitanywhere_bigtrace_adminonly` Whether sitanywhere trace scaling should only be for admins (default 0)
- `jbt_sitanywhere_bigtrace_distance` What the base distance check should be for sitting (default 100)
- `jbt_sitanywhere_bigtrace_small` Whether smaller players get a smaller range for sitanywhere (default 0)
- `jbt_adminonly_is_superadminonly` Whether 'adminonly' settings should actually be superadmin only (default 0)

### Netvar Overrides (booleans, will bypass convars)
- `JBT_BigUse` Enables big use module on someone
- `JBT_BigUse_Mass` Enables big use mass mode
- `JBT_BigUse_Small` Enables big use for small players
- `JBT_BigMass` Enables big mass module on someone
- `JBT_BigStats` Enables big stats module on someone
- `JBT_BigStats_Health` Enables health scaling
- `JBT_BigStats_Armor` Enables armor scaling
- `JBT_BigStats_Speed` Enables speed scaling
- `JBT_BigStats_Small` Enables big stats for small players
- `JBT_Pac_BigLimit` Enables the Pac big limit module
- `JBT_SitAnywhere_BigTrace` Enables the sit anywhere big trace module
- `JBT_SitAnywhere_BigTrace_Small` enables big trace for small players

### Permissions (will only bypass adminonly, SAM exclusive)
- `jbt_pac_biglimit` Override the adminonly setting of the pac size limit module
- `jbt_sitanywhere_bigtrace` Override the adminonly setting of the sitanywhere big trace module
- `jbt_biguse` Override the adminonly setting of the big use module
