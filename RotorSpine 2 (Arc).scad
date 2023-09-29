// Create an articulated print-in-place spine, with connections allowing rotational movement.


/* [Dimensions] */
// Length of chain.
Length = 60;
// Segment resolution.
Segments = 3;
// Width at start of chain.
WidthStart = 30;
// Width at end of chain.
WidthEnd = 30;
// Interpolation method.
Interpolation = "Linear"; // [ "Linear", "Quadratic", "Concave", "Convex" ]
// Influence the strength and shape of interpolation.
InterpolationStrength = 1.0; // [-1.00 : 0.00 : 1.00]


// Depth override, leave at 0 to control by layering for low-profile (flat) design.
UserDepth = 0;
// Extra depth above the mechanical structure
ExtraDepth = 0.4;
// Design layer height (n * LayerHeight).
LayersPerLevel = 3; // [1 : 1 : 10] 
// Segment length extension. Distance between terminals.
Extension = 5; 


/* [Mechanism] */ 
// Angle encompassed within given width, determine rotation in either dimension.
Angle = 15;
// Ratio of radius to cut window for connection, enlarges/restricts range of motion.
Window = 1.3; // [0.51 : 0.01 : 2.00]
// Ratio of radius for bridge thickness, trading strength for extra sweeping through window.
Connection = 0.6; // [0.2 : 0.01 : 0.5]
// Thickness of each band/arc within sliding mechanism. 
Band = 2;


/* [Print] */ 
// Slicer layer height, for calculating depths.
LayerHeight = 0.2; // [0.01 : 0.05 : 0.6]
// Standard clearance for print-in-place gaps.
Clearance = 0.2; 
// Clearance for bridging, greater to avoid sag fusing.
ClearanceBridge = 0.4;
// Clearance related to the bed, which can be trickier. Adjust as you would for elephant foot compensation.
ClearanceBed = 0.35;


/* [Hidden] */
$fs = 1;
$fn = 50;
Overlap = 0.01;

    
// Computed 
Level = UserDepth != 0 ? (UserDepth - 2*ClearanceBridge)/3 : LayerHeight * LayersPerLevel;
Depth = UserDepth != 0 ? UserDepth : 3 * Level + 2 * ClearanceBridge;

// Segments of chain have a start and end width, following input values for whole chain through function.

Widths = interpolate(WidthStart, WidthEnd, Segments);

// incorporate the distance between (bedclearance)?
function interpolate(startWidth, endWidth, Segments) = [for (i = [0 : Segments+1]) startWidth + (endWidth - startWidth) * widthShaping(i / (Segments))];
function widthShaping(c) = Interpolation == "Linear" ? c : 3*pow(c, 2) - 2*pow(c, 3);

module Guide() {
    for(i = [0 : 1 : Segments-1]) {
        Length = Length/Segments - ClearanceBed + ClearanceBed/Segments;
        translate([i*(Length + ClearanceBed), 0, Depth + 1])
        linear_extrude(Depth)
        polygon(points = [[0, Widths[i]/2], [Length, Widths[i+1]/2], [Length, -Widths[i+1]/2], [0, -Widths[i]/2]]);
    }
       
    translate([0, -WidthStart/2, Depth*2 + 2])
    #cube([Length, WidthStart, Depth]);        
}
//Guide();

module Connector() {
    union() {
        intersection() {
            translate([0,0,-Overlap/2])
            linear_extrude(Depth+Overlap)
            polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
        
            translate([R1PosX, 0, -Overlap/2])
            difference() {
                cylinder(Level + Overlap, R1-Band, R1-Band);
                translate([0,0,-Overlap])
                cylinder(Level + Overlap*2, R1-2*Band, R1-2*Band);
            }           
        }
        
        intersection() {
            translate([0,0,-Overlap/2])
            linear_extrude(Depth+Overlap)
            polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
        
            translate([R1PosX, 0, -Overlap/2])
            difference() {
                cylinder(Level + Overlap, R1-3*Band, R1-3*Band);
                translate([0,0,-Overlap])
                cylinder(Level + Overlap*2, R1-4*Band, R1-4*Band);
            }         
        }
        
        intersection() {
            translate([0,0,-Overlap/2])
            linear_extrude(Depth+Overlap)
            polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
        
            translate([R1PosX, 0, Level])
            difference() {
                cylinder(Level + 2*ClearanceBed + Overlap, R1+Overlap, R1+Overlap);
                translate([0,0,-Overlap])
                cylinder(Level + 2*ClearanceBed + Overlap*2, R1-4*Band, R1-4*Band);
            }         
        }
    }
}

module Segment(startWidth = 15 , endWidth = 12, Length = 10) {
    R1 = (startWidth/2) / sin(Angle);
    R1PosX = (startWidth/2) / tan(Angle);
    
    R2 = (endWidth/2) / sin(Angle);
    R2PosX = (endWidth/2) / tan(Angle); // R1PosX - Length;

    union() {
        difference() {
            intersection() {
                linear_extrude(Depth)
                polygon(points = [[-R1+R1PosX, startWidth/2], [0, startWidth/2], [Length, endWidth/2], [Length, -endWidth/2], [0, -startWidth/2], [-R1 + R1PosX, -startWidth/2]]);
            
                translate([R1PosX, 0,0])
                cylinder(Depth, R1, R1);
            }
            
            translate([R2PosX+Length, 0, -Overlap/2])
            cylinder(Depth + Overlap, R2, R2);
            
            intersection() {
                translate([0,0,-Overlap/2])
                linear_extrude(Depth+Overlap)
                polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
            
                translate([R1PosX, 0, -Overlap/2])
                difference() {
                    cylinder(Level + Overlap, R1-Band, R1-Band);
                    translate([0,0,-Overlap])
                    cylinder(Level + Overlap*2, R1-2*Band, R1-2*Band);
                }           
            }
            
            intersection() {
                translate([0,0,-Overlap/2])
                linear_extrude(Depth+Overlap)
                polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
            
                translate([R1PosX, 0, -Overlap/2])
                difference() {
                    cylinder(Level + Overlap, R1-3*Band, R1-3*Band);
                    translate([0,0,-Overlap])
                    cylinder(Level + Overlap*2, R1-4*Band, R1-4*Band);
                }         
            }
            
            intersection() {
                translate([0,0,-Overlap/2])
                linear_extrude(Depth+Overlap)
                polygon(points = [[-R1+R1PosX, startWidth/2] , [0, startWidth/2 - Band], [Length, endWidth/2 - Band], [Length, -endWidth/2 + Band], [0, -startWidth/2 + Band], [-R1 + R1PosX, -startWidth/2 + Band]]);
            
                translate([R1PosX, 0, Level])
                difference() {
                    cylinder(Level + 2*ClearanceBridge + Overlap, R1+Overlap, R1+Overlap);
                    translate([0,0,-Overlap])
                    cylinder(Level + 2*ClearanceBridge + Overlap*2, R1-4*Band, R1-4*Band);
                }         
            }
            
            translate([-2.4, -startWidth/2, Level*2 + ClearanceBridge*2])
            cube([2, startWidth, Level + Overlap]);
        }

        translate([Length + ClearanceBed + ClearanceBed/Segments,0,0])
        intersection() {
            linear_extrude(Level*2 + ClearanceBridge)
            polygon(points = [[-R1+R1PosX-ClearanceBed, startWidth/4 - Band] , [0, startWidth/4 - Band], [Length, endWidth/4 - Band], [Length, -endWidth/4 + Band], [0, -startWidth/4 + Band], [-R1 + R1PosX - ClearanceBed, -startWidth/4 + Band]]);

            union() {
                translate([R1PosX, 0, 0])
                difference() {
                    cylinder(Level*2 + ClearanceBridge, R1-Band-ClearanceBed, R1-Band-ClearanceBed);
                    translate([0,0,-Overlap/2])
                    cylinder(Level*2 + ClearanceBridge + Overlap, R1-2*Band + ClearanceBed, R1-2*Band + ClearanceBed);
                }           
            
                translate([R1PosX, 0, -Overlap/2])
                difference() {
                    cylinder(Level*2 + ClearanceBridge, R1-3*Band - ClearanceBed, R1-3*Band - ClearanceBed);
                    translate([0,0,-Overlap/2])
                    cylinder(Level*2 + ClearanceBridge + Overlap, R1-4*Band + ClearanceBed, R1-4*Band + ClearanceBed);
                }         
   
                translate([R1PosX, 0, Level+ClearanceBed])
                difference() {
                    translate([-ClearanceBed,0,0])
                    cylinder(Level + 2*ClearanceBridge, R1+ClearanceBed, R1+ClearanceBed);
                    translate([0,0,-Overlap/2])
                    cylinder(Level + 2*ClearanceBridge + Overlap, R1-4*Band + ClearanceBed, R1-4*Band + ClearanceBed);
                }         
            }
        }
    }
}

module Spine() {
    for(i = [0 : 1 : Segments-1]) {
        
        WidthStartSeg = Widths[i];
        WidthEndSeg = Widths[i+1];
        Length = Length/Segments - ClearanceBed + ClearanceBed/Segments;
        
        translate([i*Length + i*ClearanceBed, 0, 0])
        //translate([(i == 0 ? 0 : ClearanceBed/2), -Widths[i]/2, 0])
        Segment(WidthStartSeg, WidthEndSeg, Length);
        
    }
}

Spine();



/* check radius/width and length etc.

module Arc(
    Width = 10,
    Angle = 15,
    Length = 10,
    Depth = 3
) {
    
    Radius = (Width/2) / sin(Angle);
    R1PosX = (Width/2) / tan(Angle);
    
    intersection() {
        translate([R1PosX, 0, 0])
        cylinder(Depth, Radius, Radius);
        
        difference() {
            
            translate([-Radius+R1PosX, -Width/2 ,0 ])
            cube([2*(Radius-R1PosX) + Length, Width, Depth*2]);
            
            translate([-R1PosX + Radius + R1PosX + Length, 0, -Overlap])
            cylinder(Depth + Overlap*2, Radius, Radius);
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
    

    difference() {
        Arc(15, 15, MechanismSpace + Extension, Depth + ExtraDepth);
        
        intersection() {
            translate([MechanismSpace/4, 0 , -Overlap])
            Arc(Width, Angle, MechanismSpace/2, Level*2+ClearanceBridge*2+Overlap);
            
            cube([Width*10, Width*0.9, Depth*2], center=true);
        }
        
        translate([-Width/3,-Width*0.45,Level])
        cube([Width/2, Width*0.9, Level+2*ClearanceBridge]);
        
        translate([-10,-Width*0.45,2*Level+ClearanceBridge*2 - Overlap])
        cube([10,Width*0.9,Level+ExtraDepth + 2*Overlap]);
    }
    
    union() {
        intersection() {
            
            translate([MechanismSpace/4 + Clearance,0,0])
            Arc(15,15,MechanismSpace/2 - 2*Clearance, Level*2 + ClearanceBridge);
            
            translate([-Width/8,-Width*0.25,0])
            cube([Width/2, Width*0.5, Level*2+ClearanceBridge]);
        }
        
        translate([-1.8,-Width/4,Level+ClearanceBridge])
        cube([2.5,Width/2,Level]);
    }

}

module Spine (
    n = 3, 
    R1 = 10, 
    R2 = 0) {
    // Form spine of segments, checking radius differentials etc and creating endcaps.

    for(i = [0 : 1 : n-1]) {
        translate([i * (MechanismSpace + Extension + 1 + Clearance)  ,0,0])
        Segment(
            r1 = R1, 
            r2 = R2 == 0 ? R1 : R2, 
            start = (i == 0),
            end = (i == n-1)
        );
    }
}

//Segment();
Spine();

//Spine(n = 3, R1 = Radius);

*/
