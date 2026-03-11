$modelname "riggs9162/rp_black_mesa_north/tramstation_shelter_8seat"
$staticprop
$casttextureshadows
$origin 0 0 0 -90
$model mesh "tramstation_shelter_8seat.smd"
$surfaceprop "metal"
$cdmaterials "models/riggs9162/rp_black_mesa_north/lab"
$cdmaterials "models/riggs9162/rp_black_mesa_north/metal"
$collisionmodel "tramstation_shelter_8seat_phys.smd"
{
	$automass
	$concave
	$remove2d
	$maxconvexpieces 1000000
}
$sequence ref "tramstation_shelter_8seat.smd"
