$modelname "riggs9162/rp_black_mesa_north/tramrail_straight_16_0"
$staticprop
$casttextureshadows
$origin 0 0 0 -90
$model mesh "tramrail_straight_16_0.smd"
$surfaceprop "metal"
$cdmaterials "models/riggs9162/rp_black_mesa_north/metal"
$collisionmodel "tramrail_straight_16_0_phys.smd"
{
	$automass
	$concave
	$remove2d
	$maxconvexpieces 1000000
}
$sequence ref "tramrail_straight_16_0.smd"
