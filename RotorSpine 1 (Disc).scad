// Create an articulated print-in-place spine, with connections allowing rotational movement.

/* [Dimensions] */
// Depth override, leave at 0 to control by layering for low-profile (flat) design.
UserDepth = 0;
// Extra depth above the mechanical structure
ExtraDepth = 0.4;
// Design layer height (n * LayerHeight).
LayersPerLevel = 3; // [1 : 1 : 10] 
// Outer radius of terminal, determines width. Uniform.
Radius = 15;
// Segment length extension. Distance between terminals.
Extension = 30; 


/* [Joint] */
// Ratio of radius to cut window for connection, enlarges/restricts range of motion.
Window = 1.3; // [0.51 : 0.01 : 2.00]
// Ratio of radius for bridge thickness, trading strength for extra sweeping through window.
Connection = 0.6; // [0.2 : 0.01 : 0.5] 


/* [Technical] */ 
// Standard clearance for print-in-place gaps.
Clearance = 0.2; 
// Clearance for bridging, greater to avoid sag fusing.
ClearanceBridge = 0.4;
// Clearance related to the bed, which can be trickier.
ClearanceBed = 0.35;
// Slicer layer height, for calculating depths.
LayerHeight = 0.2; // [0.01 : 0.05 : 0.6]

 
/* [Hidden] */
$fs = 0.5;
$fn = 40;
Overlap = 0.01;
    
    
// Computed 
Level = UserDepth != 0 ? (UserDepth - 2*ClearanceBridge)/3 : LayerHeight * LayersPerLevel;
Depth = UserDepth != 0 ? UserDepth : 3 * Level + 2 * ClearanceBridge;

// check radius/width and length etc.


// Enterprise esque shape that forms linkage, greater volume by clearace for "cut"
module Enterprise(
    Cut = true,
    Radius = 10,
    
) {
        h1 = Cut ? Level : Level + ClearanceBridge;
        h2 = Cut ? 2*Level + 2*ClearanceBridge : 2*Level + ClearanceBridge;
    
        r1 = Cut ? Radius*0.6 : Radius*0.6 - ClearanceBed;
        r2 = Cut ? 3*Radius/4 : 3*Radius/4 - ClearanceBed; 
    
        // Bridgewidth really determined by freedom of rotate
        BirdgeWidth = Radius/2;
        union() {
            translate([0,0,-Overlap])
            cylinder(h1, r1, r2);
                translate([0, 0, h1-2*Overlap])
                union() {
                    cylinder(h2-h1, r2, r2);
                    
                    w = Cut ? Radius * Window : Radius * Connection;
                    translate([-Radius*1.2, - w/2, 0])
                    cube([Radius, w, h2-h1]);
                }
        }
}


module Segment(
    r1 = 10,
    r2 = 8,  
    start = false,
    end = false,
    guide = false
){
       
    module Hull() {
        hull() {
            cylinder(Depth + ExtraDepth, r1, r1);
            
            translate([end ? r1 : Extension, 0, -Overlap/2])
            cylinder(Depth + ExtraDepth + Overlap, r2, r2);
        }
    }
  
    union() {
        difference() {
            Hull();

            // INCUT
            if (!end) {
                translate([Extension, 0, -2*Overlap/2])
                cylinder(Depth + ExtraDepth + 2*Overlap, r2 + Clearance, r2 + Clearance);
            }
            
            // CONNECTOR SLOT
            if(!start) {
                Enterprise(Radius = r1);

                // BRIDGE-POSSIBLE
                dCut = sqrt(pow(r1, 2) - pow(Radius * Window / 2, 2));
                hCut = Depth - Level;
                translate([-r1 - dCut, -Radius*Window/2, hCut - 3*Overlap - ExtraDepth])
                cube([r1, Radius * Window, hCut + Overlap + ExtraDepth]);
            }
            
            // INCUT
            if (!end) {
                translate([Extension, 0, -2*Overlap/2])
                cylinder(Depth + 2*Overlap, r2 + Clearance, r2 + Clearance);
                
                mirror([0,1,0])
                rotate([0,0,10])
                translate([Extension*1.05, Radius, 0])
                cube([10,Radius,10], center=true);
            
                rotate([0,0,10])
                translate([Extension*1.05, Radius, 0])
                cube([10,Radius,10], center=true);
            }
        }
        
        if(!end) { 
            translate([Extension, 0, 0])
            Enterprise(Cut = false, Radius = r2);
        }
    }
    
    module Guide() {
        color("Purple")
        difference() {   
            Hull();        
            
            translate([0,0,-2*Overlap])
            cylinder(Depth + 4*Overlap, r1+Overlap, r1+Overlap);
 
            translate([Extension, 0, -Overlap])
            cylinder(Depth + 2*Overlap, r2 + Overlap, r2 + Overlap);
        }
        
        color("Green")
        cylinder(Depth, r1, r1);
        
        color("Blue")
        translate([Extension, 0, -Overlap/2])
        cylinder(Depth + Overlap, r2, r2);
    }
    
    if(guide == true) {
        translate([0,0,Depth*4])
        #Hull();
        
        translate([0,0,Depth*2])
        Guide();
        
        translate([0, -0.5,Depth*3.5])
        cube([Extension, 1,Overlap]);
    }
}

module Spine (
    n = 3, 
    R1 = 10, 
    R2 = 0) {
    // Form spine of segments, checking radius differentials etc and creating endcaps.

    for(i = [0 : 1 : n-1]) {
        translate([i * Extension,0,0])
        Segment(
            r1 = R1, 
            r2 = R2 == 0 ? R1 : R2, 
            start = (i == 0),
            end = (i == n-1)
        );
    }
}

Spine(n = 3, R1 = Radius);
