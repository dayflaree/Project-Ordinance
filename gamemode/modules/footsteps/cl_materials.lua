--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Materials = {
    cardboard = {
        step = {
            "riggs9162/bms/footsteps/static/cardboard_step1.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step2.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step3.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step4.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step5.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step6.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step7.ogg",
            "riggs9162/bms/footsteps/static/cardboard_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/cardboard_jump1.ogg",
            "riggs9162/bms/footsteps/static/cardboard_jump2.ogg",
            "riggs9162/bms/footsteps/static/cardboard_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/cardboard_land1.ogg",
            "riggs9162/bms/footsteps/static/cardboard_land2.ogg",
            "riggs9162/bms/footsteps/static/cardboard_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbwood-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-09.ogg"
        }
    },

    carpet = {
        step = {
            "riggs9162/bms/footsteps/static/carpet_step1.ogg",
            "riggs9162/bms/footsteps/static/carpet_step2.ogg",
            "riggs9162/bms/footsteps/static/carpet_step3.ogg",
            "riggs9162/bms/footsteps/static/carpet_step4.ogg",
            "riggs9162/bms/footsteps/static/carpet_step5.ogg",
            "riggs9162/bms/footsteps/static/carpet_step6.ogg",
            "riggs9162/bms/footsteps/static/carpet_step7.ogg",
            "riggs9162/bms/footsteps/static/carpet_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/carpet_jump1.ogg",
            "riggs9162/bms/footsteps/static/carpet_jump2.ogg",
            "riggs9162/bms/footsteps/static/carpet_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/carpet_land1.ogg",
            "riggs9162/bms/footsteps/static/carpet_land2.ogg",
            "riggs9162/bms/footsteps/static/carpet_land3.ogg"
        }
        -- No reverb for carpet (soft materials)
    },

    concrete = {
        -- Combined concrete + concrete_grit for variety
        step = {
            "riggs9162/bms/footsteps/static/concrete_step1.ogg",
            "riggs9162/bms/footsteps/static/concrete_step2.ogg",
            "riggs9162/bms/footsteps/static/concrete_step3.ogg",
            "riggs9162/bms/footsteps/static/concrete_step4.ogg",
            "riggs9162/bms/footsteps/static/concrete_step5.ogg",
            "riggs9162/bms/footsteps/static/concrete_step6.ogg",
            "riggs9162/bms/footsteps/static/concrete_step7.ogg",
            "riggs9162/bms/footsteps/static/concrete_step8.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step1.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step2.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step3.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step4.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step5.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step6.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step7.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/concrete_jump1.ogg",
            "riggs9162/bms/footsteps/static/concrete_jump2.ogg",
            "riggs9162/bms/footsteps/static/concrete_jump3.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_jump1.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_jump2.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/concrete_land1.ogg",
            "riggs9162/bms/footsteps/static/concrete_land2.ogg",
            "riggs9162/bms/footsteps/static/concrete_land3.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_land1.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_land2.ogg",
            "riggs9162/bms/footsteps/static/concrete_grit_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverb-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-09.ogg"
        }
    },

    dirt = {
        -- Using rock sounds for earth materials (dirt → rock)
        step = {
            "riggs9162/bms/footsteps/static/earth_step1.ogg",
            "riggs9162/bms/footsteps/static/earth_step2.ogg",
            "riggs9162/bms/footsteps/static/earth_step3.ogg",
            "riggs9162/bms/footsteps/static/earth_step4.ogg",
            "riggs9162/bms/footsteps/static/earth_step5.ogg",
            "riggs9162/bms/footsteps/static/earth_step6.ogg",
            "riggs9162/bms/footsteps/static/earth_step7.ogg",
            "riggs9162/bms/footsteps/static/earth_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/earth_jump1.ogg",
            "riggs9162/bms/footsteps/static/earth_jump2.ogg",
            "riggs9162/bms/footsteps/static/earth_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/earth_land1.ogg",
            "riggs9162/bms/footsteps/static/earth_land2.ogg",
            "riggs9162/bms/footsteps/static/earth_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    flesh = {
        step = {
            "riggs9162/bms/footsteps/static/flesh_step1.ogg",
            "riggs9162/bms/footsteps/static/flesh_step2.ogg",
            "riggs9162/bms/footsteps/static/flesh_step3.ogg",
            "riggs9162/bms/footsteps/static/flesh_step4.ogg",
            "riggs9162/bms/footsteps/static/flesh_step5.ogg",
            "riggs9162/bms/footsteps/static/flesh_step6.ogg",
            "riggs9162/bms/footsteps/static/flesh_step7.ogg",
            "riggs9162/bms/footsteps/static/flesh_step8.ogg",
            "riggs9162/bms/footsteps/static/flesh_step9.ogg",
            "riggs9162/bms/footsteps/static/flesh_step10.ogg",
            "riggs9162/bms/footsteps/static/flesh_step11.ogg",
            "riggs9162/bms/footsteps/static/flesh_step12.ogg",
            "riggs9162/bms/footsteps/static/flesh_step13.ogg",
            "riggs9162/bms/footsteps/static/flesh_step14.ogg",
            "riggs9162/bms/footsteps/static/flesh_step15.ogg",
            "riggs9162/bms/footsteps/static/flesh_step16.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/flesh_jump1.ogg",
            "riggs9162/bms/footsteps/static/flesh_jump2.ogg",
            "riggs9162/bms/footsteps/static/flesh_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/flesh_land1.ogg",
            "riggs9162/bms/footsteps/static/flesh_land2.ogg",
            "riggs9162/bms/footsteps/static/flesh_land3.ogg"
        }
        -- No reverb for flesh (organic materials)
    },

    glass = {
        step = {
            "riggs9162/bms/footsteps/static/glasssolid_step1.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step2.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step3.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step4.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step5.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step6.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step7.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/glasssolid_jump1.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_jump2.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/glasssolid_land1.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_land2.ogg",
            "riggs9162/bms/footsteps/static/glasssolid_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbtile-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-08.ogg"
        }
    },

    gravel = {
        -- Using rock sounds for earth materials (gravel → rock)
        step = {
            "riggs9162/bms/footsteps/static/gravel_step1.ogg",
            "riggs9162/bms/footsteps/static/gravel_step2.ogg",
            "riggs9162/bms/footsteps/static/gravel_step3.ogg",
            "riggs9162/bms/footsteps/static/gravel_step4.ogg",
            "riggs9162/bms/footsteps/static/gravel_step5.ogg",
            "riggs9162/bms/footsteps/static/gravel_step6.ogg",
            "riggs9162/bms/footsteps/static/gravel_step7.ogg",
            "riggs9162/bms/footsteps/static/gravel_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/gravel_jump1.ogg",
            "riggs9162/bms/footsteps/static/gravel_jump2.ogg",
            "riggs9162/bms/footsteps/static/gravel_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/gravel_land1.ogg",
            "riggs9162/bms/footsteps/static/gravel_land2.ogg",
            "riggs9162/bms/footsteps/static/gravel_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    ladder = {
        step = {
            "riggs9162/bms/footsteps/static/ladder_step1.ogg",
            "riggs9162/bms/footsteps/static/ladder_step2.ogg",
            "riggs9162/bms/footsteps/static/ladder_step3.ogg",
            "riggs9162/bms/footsteps/static/ladder_step4.ogg",
            "riggs9162/bms/footsteps/static/ladder_step5.ogg",
            "riggs9162/bms/footsteps/static/ladder_step6.ogg",
            "riggs9162/bms/footsteps/static/ladder_step7.ogg",
            "riggs9162/bms/footsteps/static/ladder_step8.ogg",
            "riggs9162/bms/footsteps/static/ladder_step9.ogg"
        },
        jump = nil,
        land = nil,
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    grass = {
        -- Combined leaves + leaves2 into grass for variety
        step = {
            "riggs9162/bms/footsteps/static/leaves_step1.ogg",
            "riggs9162/bms/footsteps/static/leaves_step2.ogg",
            "riggs9162/bms/footsteps/static/leaves_step3.ogg",
            "riggs9162/bms/footsteps/static/leaves_step4.ogg",
            "riggs9162/bms/footsteps/static/leaves_step5.ogg",
            "riggs9162/bms/footsteps/static/leaves_step6.ogg",
            "riggs9162/bms/footsteps/static/leaves_step7.ogg",
            "riggs9162/bms/footsteps/static/leaves_step8.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step1.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step2.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step3.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step4.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step5.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step6.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step7.ogg",
            "riggs9162/bms/footsteps/static/leaves2_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/leaves_jump1.ogg",
            "riggs9162/bms/footsteps/static/leaves_jump2.ogg",
            "riggs9162/bms/footsteps/static/leaves_jump3.ogg",
            "riggs9162/bms/footsteps/static/leaves2_jump1.ogg",
            "riggs9162/bms/footsteps/static/leaves2_jump2.ogg",
            "riggs9162/bms/footsteps/static/leaves2_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/leaves_land1.ogg",
            "riggs9162/bms/footsteps/static/leaves_land2.ogg",
            "riggs9162/bms/footsteps/static/leaves_land3.ogg",
            "riggs9162/bms/footsteps/static/leaves2_land1.ogg",
            "riggs9162/bms/footsteps/static/leaves2_land2.ogg",
            "riggs9162/bms/footsteps/static/leaves2_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbgrass-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbgrass-08.ogg"
        }
    },

    tile = {
        step = {
            "riggs9162/bms/footsteps/static/marble_step1.ogg",
            "riggs9162/bms/footsteps/static/marble_step2.ogg",
            "riggs9162/bms/footsteps/static/marble_step3.ogg",
            "riggs9162/bms/footsteps/static/marble_step4.ogg",
            "riggs9162/bms/footsteps/static/marble_step5.ogg",
            "riggs9162/bms/footsteps/static/marble_step6.ogg",
            "riggs9162/bms/footsteps/static/marble_step7.ogg",
            "riggs9162/bms/footsteps/static/marble_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/marble_jump1.ogg",
            "riggs9162/bms/footsteps/static/marble_jump2.ogg",
            "riggs9162/bms/footsteps/static/marble_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/marble_land1.ogg",
            "riggs9162/bms/footsteps/static/marble_land2.ogg",
            "riggs9162/bms/footsteps/static/marble_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbtile-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-08.ogg"
        }
    },

    metal = {
        -- Using metalsolid as primary metal sound
        step = {
            "riggs9162/bms/footsteps/static/metalsolid_step1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step3.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step4.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step5.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step6.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step7.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/metalsolid_jump1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_jump2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/metalsolid_land1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_land2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    metalgrate = {
        step = {
            "riggs9162/bms/footsteps/static/metalgrate_step1.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step2.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step3.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step4.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step5.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step6.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step7.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/metalgrate_jump1.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_jump2.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/metalgrate_land1.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_land2.ogg",
            "riggs9162/bms/footsteps/static/metalgrate_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    metalsolid = {
        step = {
            "riggs9162/bms/footsteps/static/metalsolid_step1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step3.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step4.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step5.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step6.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step7.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/metalsolid_jump1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_jump2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/metalsolid_land1.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_land2.ogg",
            "riggs9162/bms/footsteps/static/metalsolid_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    metalthin = {
        step = {
            "riggs9162/bms/footsteps/static/metalthin_step1.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step2.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step3.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step4.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step5.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step6.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step7.ogg",
            "riggs9162/bms/footsteps/static/metalthin_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/metalthin_jump1.ogg",
            "riggs9162/bms/footsteps/static/metalthin_jump2.ogg",
            "riggs9162/bms/footsteps/static/metalthin_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/metalthin_land1.ogg",
            "riggs9162/bms/footsteps/static/metalthin_land2.ogg",
            "riggs9162/bms/footsteps/static/metalthin_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    panel = {
        step = {
            "riggs9162/bms/footsteps/static/panel_step1.ogg",
            "riggs9162/bms/footsteps/static/panel_step2.ogg",
            "riggs9162/bms/footsteps/static/panel_step3.ogg",
            "riggs9162/bms/footsteps/static/panel_step4.ogg",
            "riggs9162/bms/footsteps/static/panel_step5.ogg",
            "riggs9162/bms/footsteps/static/panel_step6.ogg",
            "riggs9162/bms/footsteps/static/panel_step7.ogg",
            "riggs9162/bms/footsteps/static/panel_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/panel_jump1.ogg",
            "riggs9162/bms/footsteps/static/panel_jump2.ogg",
            "riggs9162/bms/footsteps/static/panel_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/panel_land1.ogg",
            "riggs9162/bms/footsteps/static/panel_land2.ogg",
            "riggs9162/bms/footsteps/static/panel_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbtile-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-08.ogg"
        }
    },

    plaster = {
        step = {
            "riggs9162/bms/footsteps/static/plaster_step1.ogg",
            "riggs9162/bms/footsteps/static/plaster_step2.ogg",
            "riggs9162/bms/footsteps/static/plaster_step3.ogg",
            "riggs9162/bms/footsteps/static/plaster_step4.ogg",
            "riggs9162/bms/footsteps/static/plaster_step5.ogg",
            "riggs9162/bms/footsteps/static/plaster_step6.ogg",
            "riggs9162/bms/footsteps/static/plaster_step7.ogg",
            "riggs9162/bms/footsteps/static/plaster_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/plaster_jump1.ogg",
            "riggs9162/bms/footsteps/static/plaster_jump2.ogg",
            "riggs9162/bms/footsteps/static/plaster_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/plaster_land1.ogg",
            "riggs9162/bms/footsteps/static/plaster_land2.ogg",
            "riggs9162/bms/footsteps/static/plaster_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverb-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-09.ogg"
        }
    },

    plastersolid = {
        step = {
            "riggs9162/bms/footsteps/static/plastersolid_step1.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step2.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step3.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step4.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step5.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step6.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step7.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/plastersolid_jump1.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_jump2.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/plastersolid_land1.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_land2.ogg",
            "riggs9162/bms/footsteps/static/plastersolid_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverb-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverb-09.ogg"
        }
    },

    rock = {
        step = {
            "riggs9162/bms/footsteps/static/earth_step1.ogg",
            "riggs9162/bms/footsteps/static/earth_step2.ogg",
            "riggs9162/bms/footsteps/static/earth_step3.ogg",
            "riggs9162/bms/footsteps/static/earth_step4.ogg",
            "riggs9162/bms/footsteps/static/earth_step5.ogg",
            "riggs9162/bms/footsteps/static/earth_step6.ogg",
            "riggs9162/bms/footsteps/static/earth_step7.ogg",
            "riggs9162/bms/footsteps/static/earth_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/earth_jump1.ogg",
            "riggs9162/bms/footsteps/static/earth_jump2.ogg",
            "riggs9162/bms/footsteps/static/earth_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/earth_land1.ogg",
            "riggs9162/bms/footsteps/static/earth_land2.ogg",
            "riggs9162/bms/footsteps/static/earth_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    rubber = {
        step = {
            "riggs9162/bms/footsteps/static/rubber_step1.ogg",
            "riggs9162/bms/footsteps/static/rubber_step2.ogg",
            "riggs9162/bms/footsteps/static/rubber_step3.ogg",
            "riggs9162/bms/footsteps/static/rubber_step4.ogg",
            "riggs9162/bms/footsteps/static/rubber_step5.ogg",
            "riggs9162/bms/footsteps/static/rubber_step6.ogg",
            "riggs9162/bms/footsteps/static/rubber_step7.ogg",
            "riggs9162/bms/footsteps/static/rubber_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/rubber_jump1.ogg",
            "riggs9162/bms/footsteps/static/rubber_jump2.ogg",
            "riggs9162/bms/footsteps/static/rubber_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/rubber_land1.ogg",
            "riggs9162/bms/footsteps/static/rubber_land2.ogg",
            "riggs9162/bms/footsteps/static/rubber_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    sand = {
        -- Using rock sounds for earth materials (sand → rock)
        step = {
            "riggs9162/bms/footsteps/static/earth_step1.ogg",
            "riggs9162/bms/footsteps/static/earth_step2.ogg",
            "riggs9162/bms/footsteps/static/earth_step3.ogg",
            "riggs9162/bms/footsteps/static/earth_step4.ogg",
            "riggs9162/bms/footsteps/static/earth_step5.ogg",
            "riggs9162/bms/footsteps/static/earth_step6.ogg",
            "riggs9162/bms/footsteps/static/earth_step7.ogg",
            "riggs9162/bms/footsteps/static/earth_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/earth_jump1.ogg",
            "riggs9162/bms/footsteps/static/earth_jump2.ogg",
            "riggs9162/bms/footsteps/static/earth_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/earth_land1.ogg",
            "riggs9162/bms/footsteps/static/earth_land2.ogg",
            "riggs9162/bms/footsteps/static/earth_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    squish = {
        step = {
            "riggs9162/bms/footsteps/static/squish_step1.ogg",
            "riggs9162/bms/footsteps/static/squish_step2.ogg",
            "riggs9162/bms/footsteps/static/squish_step3.ogg",
            "riggs9162/bms/footsteps/static/squish_step4.ogg",
            "riggs9162/bms/footsteps/static/squish_step5.ogg",
            "riggs9162/bms/footsteps/static/squish_step6.ogg",
            "riggs9162/bms/footsteps/static/squish_step7.ogg",
            "riggs9162/bms/footsteps/static/squish_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/squish_jump1.ogg",
            "riggs9162/bms/footsteps/static/squish_jump2.ogg",
            "riggs9162/bms/footsteps/static/squish_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/squish_land1.ogg",
            "riggs9162/bms/footsteps/static/squish_land2.ogg",
            "riggs9162/bms/footsteps/static/squish_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    },

    vent = {
        step = {
            "riggs9162/bms/footsteps/static/vent_step1.ogg",
            "riggs9162/bms/footsteps/static/vent_step2.ogg",
            "riggs9162/bms/footsteps/static/vent_step3.ogg",
            "riggs9162/bms/footsteps/static/vent_step4.ogg",
            "riggs9162/bms/footsteps/static/vent_step5.ogg",
            "riggs9162/bms/footsteps/static/vent_step6.ogg",
            "riggs9162/bms/footsteps/static/vent_step7.ogg",
            "riggs9162/bms/footsteps/static/vent_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/vent_jump1.ogg",
            "riggs9162/bms/footsteps/static/vent_jump2.ogg",
            "riggs9162/bms/footsteps/static/vent_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/vent_land1.ogg",
            "riggs9162/bms/footsteps/static/vent_land2.ogg",
            "riggs9162/bms/footsteps/static/vent_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbmetal-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbmetal-09.ogg"
        }
    },

    water = {
        step = {
            "riggs9162/bms/footsteps/static/water_step1.ogg",
            "riggs9162/bms/footsteps/static/water_step2.ogg",
            "riggs9162/bms/footsteps/static/water_step3.ogg",
            "riggs9162/bms/footsteps/static/water_step4.ogg",
            "riggs9162/bms/footsteps/static/water_step5.ogg",
            "riggs9162/bms/footsteps/static/water_step6.ogg",
            "riggs9162/bms/footsteps/static/water_step7.ogg",
            "riggs9162/bms/footsteps/static/water_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/water_jump1.ogg",
            "riggs9162/bms/footsteps/static/water_jump2.ogg",
            "riggs9162/bms/footsteps/static/water_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/water_land1.ogg",
            "riggs9162/bms/footsteps/static/water_land2.ogg",
            "riggs9162/bms/footsteps/static/water_land3.ogg"
        }
        -- No reverb for water (liquid materials)
    },

    wood = {
        step = {
            "riggs9162/bms/footsteps/static/wood_step1.ogg",
            "riggs9162/bms/footsteps/static/wood_step2.ogg",
            "riggs9162/bms/footsteps/static/wood_step3.ogg",
            "riggs9162/bms/footsteps/static/wood_step4.ogg",
            "riggs9162/bms/footsteps/static/wood_step5.ogg",
            "riggs9162/bms/footsteps/static/wood_step6.ogg",
            "riggs9162/bms/footsteps/static/wood_step7.ogg",
            "riggs9162/bms/footsteps/static/wood_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/wood_jump1.ogg",
            "riggs9162/bms/footsteps/static/wood_jump2.ogg",
            "riggs9162/bms/footsteps/static/wood_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/wood_land1.ogg",
            "riggs9162/bms/footsteps/static/wood_land2.ogg",
            "riggs9162/bms/footsteps/static/wood_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbwood-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-09.ogg"
        }
    },

    woodcrate = {
        step = {
            "riggs9162/bms/footsteps/static/woodcrate_step1.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step2.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step3.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step4.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step5.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step6.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step7.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/woodcrate_jump1.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_jump2.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/woodcrate_land1.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_land2.ogg",
            "riggs9162/bms/footsteps/static/woodcrate_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbwood-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-08.ogg",
            "riggs9162/bms/footsteps/reverb/reverbwood-09.ogg"
        }
    },

    plastic = {
        step = {
            "riggs9162/bms/footsteps/static/plastic_step1.ogg",
            "riggs9162/bms/footsteps/static/plastic_step2.ogg",
            "riggs9162/bms/footsteps/static/plastic_step3.ogg",
            "riggs9162/bms/footsteps/static/plastic_step4.ogg",
            "riggs9162/bms/footsteps/static/plastic_step5.ogg",
            "riggs9162/bms/footsteps/static/plastic_step6.ogg",
            "riggs9162/bms/footsteps/static/plastic_step7.ogg",
            "riggs9162/bms/footsteps/static/plastic_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/plastic_jump1.ogg",
            "riggs9162/bms/footsteps/static/plastic_jump2.ogg",
            "riggs9162/bms/footsteps/static/plastic_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/plastic_land1.ogg",
            "riggs9162/bms/footsteps/static/plastic_land2.ogg",
            "riggs9162/bms/footsteps/static/plastic_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbtile-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-08.ogg"
        }
    },

    plasticsolid = {
        step = {
            "riggs9162/bms/footsteps/static/plasticsolid_step1.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step2.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step3.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step4.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step5.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step6.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step7.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/plasticsolid_jump1.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_jump2.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/plasticsolid_land1.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_land2.ogg",
            "riggs9162/bms/footsteps/static/plasticsolid_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbtile-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-06.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-07.ogg",
            "riggs9162/bms/footsteps/reverb/reverbtile-08.ogg"
        }
    },

    rock_alt = {
        -- Using actual rock sounds from the pack
        step = {
            "riggs9162/bms/footsteps/static/rock_step1.ogg",
            "riggs9162/bms/footsteps/static/rock_step2.ogg",
            "riggs9162/bms/footsteps/static/rock_step3.ogg",
            "riggs9162/bms/footsteps/static/rock_step4.ogg",
            "riggs9162/bms/footsteps/static/rock_step5.ogg",
            "riggs9162/bms/footsteps/static/rock_step6.ogg",
            "riggs9162/bms/footsteps/static/rock_step7.ogg",
            "riggs9162/bms/footsteps/static/rock_step8.ogg"
        },
        jump = {
            "riggs9162/bms/footsteps/static/rock_jump1.ogg",
            "riggs9162/bms/footsteps/static/rock_jump2.ogg",
            "riggs9162/bms/footsteps/static/rock_jump3.ogg"
        },
        land = {
            "riggs9162/bms/footsteps/static/rock_land1.ogg",
            "riggs9162/bms/footsteps/static/rock_land2.ogg",
            "riggs9162/bms/footsteps/static/rock_land3.ogg"
        },
        reverb = {
            "riggs9162/bms/footsteps/reverb/reverbdirt-01.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-02.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-03.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-04.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-05.ogg",
            "riggs9162/bms/footsteps/reverb/reverbdirt-06.ogg"
        }
    }
}

MODULE.SurfaceMapping = {
    -- Concrete surfaces
    concrete = "concrete",

    -- Tile surfaces
    tile = "tile",
    marble_cobble = "tile",
    marble_gravel = "tile",
    marble = "tile",

    -- Wood surfaces
    wood = "wood",
    wood_floor = "wood",
    wood_panel = "wood",
    wood_plank = "wood",
    wood_solid = "wood",
    wood_box = "woodcrate",

    -- Metal surfaces
    metal = "metal",
    metal_box = "metal",
    metal_sheet = "metal",
    metalgrid = "metalgrate",
    metalvent = "vent",

    -- Gravel and dirt (earth materials)
    gravel = "gravel",
    dirt = "dirt",
    mud = "dirt",

    -- Grass and foliage
    grass = "grass",
    grass_long = "grass",
    foliage = "grass",
    leaves = "grass",

    -- Sand (earth materials)
    sand = "sand",

    -- Rock and stone
    rock = "rock",
    stone = "rock",

    -- Glass
    glass = "glass",
    glass_breakable = "glass",

    -- Carpet and fabric
    carpet = "carpet",
    fabric = "carpet",
    cloth = "carpet",

    -- Plaster
    plaster = "plaster",
    plaster_rough = "plaster",
    plaster_smooth = "plastersolid",

    -- Flesh
    flesh = "flesh",

    -- Water
    water = "water",
    wade = "water",

    -- Ladder
    ladder = "ladder",

    -- Rubber and plastic
    rubber = "rubber",
    plastic = "plastic",
    plasticsolid = "plasticsolid",

    -- Ventilation
    vent = "vent",

    -- Squish (slime, blood, etc.)
    slime = "squish",
    blood = "squish",

    -- Panel surfaces
    panel = "panel",
    metal_panel = "panel",

    -- Default fallback for unmapped surfaces
    ["default"] = "concrete"
}

-- Expose data and helper functions globally for other files to access
ax.footsteps = ax.footsteps or {}
ax.footsteps.materials = MODULE.Materials
ax.footsteps.surfaceMapping = MODULE.SurfaceMapping

-- Store helper functions globally so they persist after MODULE is set to nil
function ax.footsteps:GetMaterialForSurface(surfaceName)
    if (!surfaceName) then
        return self.materials[self.surfaceMapping["default"]]
    end

    local materialKey = self.surfaceMapping[string.lower(surfaceName)]
    if (!materialKey) then
        materialKey = self.surfaceMapping["default"]
    end

    return self.materials[materialKey]
end

function ax.footsteps:GetStepSound(surfaceName)
    local material = self:GetMaterialForSurface(surfaceName)
    if (!material or !material.step) then
        return nil
    end

    local steps = material.step
    if (istable(steps)) then
        return steps[math.random(#steps)]
    end

    return steps
end

function ax.footsteps:GetJumpSound(surfaceName)
    local material = self:GetMaterialForSurface(surfaceName)
    return material and material.jump or nil
end

function ax.footsteps:GetLandSound(surfaceName)
    local material = self:GetMaterialForSurface(surfaceName)
    return material and material.land or nil
end

function ax.footsteps:GetReverbSound(surfaceName)
    local material = self:GetMaterialForSurface(surfaceName)
    if (!material or !material.reverb) then
        return nil
    end

    local reverbs = material.reverb
    if (istable(reverbs)) then
        return reverbs[math.random(#reverbs)]
    end

    return reverbs
end
