$modelname "riggs9162/rp_black_mesa_north/tramrail_curve_45_0"
$staticprop
$casttextureshadows
$origin 0 0 0 -90
$model mesh "tramrail_curve_45_0.smd"
$surfaceprop "metal"
$cdmaterials "models/riggs9162/rp_black_mesa_north/metal"
$collisionmodel "tramrail_curve_45_0_phys.smd"
{
	$automass
	$remove2d
	$maxconvexpieces 1000000
}
$sequence ref "tramrail_curve_45_0.smd"
