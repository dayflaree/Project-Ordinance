$modelname "riggs9162/rp_black_mesa_north/tramstation_canopy_full_4bench"
$staticprop
$casttextureshadows
$origin 0 0 0 -90
$model mesh "tramstation_canopy_full_4bench.smd"
$surfaceprop "metal"
$cdmaterials "models/riggs9162/rp_black_mesa_north/lab"
$cdmaterials "models/riggs9162/rp_black_mesa_north/bshift/bs_freightyard"
$cdmaterials "models/riggs9162/rp_black_mesa_north/metal"
$collisionmodel "tramstation_canopy_full_4bench_phys.smd"
{
	$automass
	$concave
	$remove2d
	$maxconvexpieces 1000000
}
$sequence ref "tramstation_canopy_full_4bench.smd"
