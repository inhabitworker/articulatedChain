// Create an articulated print-in-place spine, with connections allowing rotational movement.

/* [Dimensions] */

// Length of chain.
Length = 60;
// Segment resolution.
Segments = 4;
// Width at start of chain.
WidthStart = 30;
// Width at end of chain.
WidthEnd = 20;
// Depth override, leave at 0 to control by layering for low-profile (flat) design.
UserDepth = 0;
// Extra depth above the mechanical structure
ExtraDepth = 0;
// Taper top for chamfer.
Chamfer = true;
// Cap the start with circle that otherwise would ingress a prior segment for connection.
StartCap = false;
// Union a final circle rather than incut.
EndCap = true;
// Interpolation method.
Interpolation = "Linear"; // [ "Linear", "Quadratic", "Concave", "Convex" ]
// Influence the strength and shape of interpolation.
InterpolationStrength = 1.0; // [-1.00 : 0.00 : 1.00]


/* [Mechanism] */ 

// Angle for arc cavity, determine rotation capacity in either dimension. Double this for cavity, unless full circle.
ArcAngle = 30; // [0 : 30 : 90]
// Angle cost of inter-segment bridge, limits movement vs arc by as much.  
BridgeAngle = 10; // []
// Thickness of the arc and cavity as ratio from center of rotation to band. 
ArcThicknessRatio = 0.2; // [0.00 : 0.01 : 0.60] 
// Thickness of the band, or distance between segment start to arc cavity. 
BandThickness = 2;
// Design layer height (n * Print.LayerHeight).
LayersPerLevel = 3; // [1 : 1 : 10] 

/* [Print] */ 

// Slicer layer height, for calculating depths.
LayerHeight = 0.2; // [0.01 : 0.05 : 0.6]
// Standard clearance for print-in-place gaps.
Clearance = 0.2; 
// Clearance for bridging, greater to avoid sag fusing.
ClearanceBridge = 0.4;
// Clearance related to the bed, which can be trickier. Adjust as you would for elephant foot compensation.
ClearanceBed = 0.2;

/* [Hidden] */
$fs = 1;
$fn = 150;
Overlap = 0.01;
// $vpd = 300;
// $vpt = [0,0,0];
// $vpr = [0,0, 0];
    
// Computed 
Level = UserDepth != 0 ? (UserDepth - 2*ClearanceBridge)/3 : LayerHeight * LayersPerLevel;
Depth = UserDepth != 0 ? UserDepth : 3 * Level + 2 * ClearanceBridge;
Widths = interpolate(WidthStart, WidthEnd, Segments);
travelAngle = ArcAngle - BridgeAngle;
function interpolate(startWidth, endWidth, Segments) = [for (i = [0 : Segments+1]) startWidth + (endWidth - startWidth) * widthShaping(i / (Segments))];
function widthShaping(c) = Interpolation == "Linear" ? c : 3*pow(c, 2) - 2*pow(c, 3);

// Debug visual
module Guide() {
    for(i = [0 : 1 : Segments-1]) {
        Length = Length/Segments - ClearanceBed + ClearanceBed/Segments;
        translate([i*(Length + ClearanceBed), 0, Depth + 1])
        linear_extrude(Depth)
        polygon(points = [[0, Widths[i]/2], [Length, Widths[i+1]/2], [Length, -Widths[i+1]/2], [0, -Widths[i]/2]]);
    }
       
    translate([0, -WidthStart/2, 0])
    #cube([Length, WidthStart, Depth*3]);        
}
Guide();

// Individual segment for a spine
module Segment(R1=15, R2=12, Length=20, Start=false, End=false) {
    
    startWidth = R1*2;
    endWidth = R2*2;

    Layer1 = Level + ClearanceBridge;
    Layer2 = 2 * Layer1;
    Layer3 = Layer2 + Level + ExtraDepth;
    
    
    // Checks
        // FullStart = startWidth < 10;
        // FullEnd = endWidth < 10;   
        // LengthReq = FullStart ? startWidth : Band*3;    
        // assert(LengthReq, "Error: segment not long enough for building connection. Reduce segments or increase length or width.");
        
    
    
    // Plan for main workpiece/body of the object
    module Plan () {
        
        // outer tangential line 
        
            // approximate
            outerAngleZ = atan2((R1-R2), Length);
            tXz = R1*sin(outerAngleZ);
            tYz = R1*cos(outerAngleZ);              
            mz = -((R1-R2)/Length);
            cz = tYz - mz*tXz;
        
            // refined 
            outerAngle = atan2((tYz-R2), Length-tXz);
            m = -((tYz-R2)/(Length-tXz)); 

            // start point
            tX = R1*sin(outerAngle);
            tY = R1*cos(outerAngle); 
                // translate([tX, tY, 0])
                // #circle(r=0.02);
        
            // y-intersect
            c = tY - m*tX;
                // translate([0, c, 0])
                // #circle(r=0.02);  
        
            // guide 
                // translate([0, c, 0])
                // rotate([0,0,-outerAngle])
                // translate([0,-0.01])
                // #square([100,0.02]);
        
        
        // known point, linear trim x on incut circle
            // requirement for movement angle, user augmented?
            trim = R2*sin(travelAngle);

            // co-ords
            xP = Length-trim;
            yP = R2*cos(travelAngle); 
                // translate([xP, yP, 0])
                // #circle(r=0.02);  
            
            // angles related to chord with T 
            fullChordAngle = 180 - abs(outerAngle) - abs(travelAngle);
            chordAcuteAngle = abs(outerAngle - travelAngle)/2;
            chordAngle = - 90 + (chordAcuteAngle - outerAngle); // about y-axis for point slope
                
                // translate([xP, yP, 0])
                // rotate([0,0,chordAngle])
                // translate([-100,-0.01])
                // #square([200,0.02]);
           
            
        // chord line
            mPT = tan(chordAngle);
            cPT = yP - mPT*xP;
            
            // coord T via simplified line eqns.
            yT = (mPT*c - m*cPT) / (mPT - m);
            xT = (yT - cPT) / mPT;
            
                // translate([xT, yT, 0])
                // #circle(r=0.025); 
            
        // circle center by way of chord & midpoint
            // chord distance
            d = sqrt((xT - xP)^2 + (yT - yP)^2);
            
            // radius by bisector
            R3 = (d/2) / cos(chordAcuteAngle);
            
            // known midpoint of TP
            xM = (xT + xP)/2;
            yM = (yT + yP)/2;
                // translate([xM, yM, 0])
                // #circle(0.02);
                
            // line TP
            dMC = R3 * sin(chordAcuteAngle);
            mMC = -1/mPT;
                
                // translate([xM, yM, 0])
                // rotate([0,0,180+abs(chordAcuteAngle - outerAngle)])
                // translate([0,-0.01,0])
                // #square([dMC,0.02]);
            
            // acute angle for CM 
            mAngle = abs(chordAcuteAngle - outerAngle);
            
            // difference component from M to C
            yCdM = sin(mAngle)*dMC;
            xCdM = cos(mAngle)*dMC;
            
            // circle center
            xC = xM - xCdM;
            yC = yM - yCdM;
            
                // translate([xC, yC, 0])
                // #circle(R3);
        
        // Main body polygon does not seem to properly meet point P, or point P is off the circle?
        pBodyXComp = 0.1;
        
        difference() {
            union() {                      
                // Head curve
                circle(r = R1);
                
                // Body 
                    // approximation - > polygon(points = [[tX, tY], [Length, R2], [Length, -R2], [tX, -tY]]);
                    // trimed approx, lacks y calc - >polygon(points = [[tX, tY], [Length-trim, R2], [Length-trim, -R2], [tX, -tY]]);
                
                if(!End) { 
                    polygon(points = [[tX, tY], [xT, yT], [xP + pBodyXComp, yP], [xP + pBodyXComp, -yP], [xT, -yT], [tX, -tY]]);
                    
                    // endcap circles
                    translate([xC, yC, 0])
                    circle(R3);
                    
                    translate([xC, -yC, 0])
                    circle(R3);
                }
            }
                                        
            // Tail incut
            if(!End) {
                translate([Length, 0, 0])
                circle(r = R2);
            } else {
                if(!EndCap) {
                    //translate([0, -startWidth/2, 0])
                    //square(startWidth);
                }
            } 
            
            if(Start && !StartCap) {
                translate([-startWidth, -startWidth/2, 0])
                square(startWidth);
            }
        }
    }
    
    // Connection (union and subtract/cavity)
    module Connection(R, Cavity = false) {   
        Arc = Cavity ? ArcAngle * 2 + travelAngle*2 : ArcAngle * 2.05;
        ToPrevious = R - R * cos(BridgeAngle);
        Band = BandThickness;
        ArcThickness = (R - BandThickness) * ArcThicknessRatio;

        
        function ifCavity(Value, Augment) = (Cavity ? Value + Augment : Value);
        function ifNotCavity(Value, Augment) = (Cavity ? Value : Value + Augment); 
        
        union() {
            // Bridge connection
            rotate([0,0, Cavity ? -ArcAngle : -BridgeAngle])
            rotate_extrude(angle = (Cavity ? ArcAngle*2 : BridgeAngle*2))
            translate([-R,0,0])
            polygon([
                [Band + ClearanceBed + Overlap, ifNotCavity(Layer2, -ClearanceBridge)],
                [-ClearanceBed - ToPrevious, ifNotCavity(Layer2, -ClearanceBridge)],
                [-ClearanceBed - ToPrevious, ifNotCavity(Level, ClearanceBridge)],
                [Band + ClearanceBed + Overlap, ifNotCavity(Level, ClearanceBridge)]
            ]);
            
            // Cavity/Arc
            rotate([0,0,-Arc/2])
            rotate_extrude(angle = Arc)
            translate([-R,0,0])
            polygon([
                [ifNotCavity(Band, ClearanceBed), ifNotCavity(Layer2, -ClearanceBridge)],
                [ifNotCavity(Band+ArcThickness+Layer2, -ClearanceBed -ClearanceBridge), ifNotCavity(Layer2, -ClearanceBridge)],
                [ifNotCavity(Band + ArcThickness, - ClearanceBed), ifCavity(0, -Overlap)],
                [ifNotCavity(Band, ClearanceBed), ifCavity(0, -Overlap)],
            ]); 
        }
    }
   
    
    
    
    
    // Composition
    difference() {
        // Main Body extrusion, with top level taper and lip
        union() {
            baseH = Layer2 + Overlap;
            topH = Level + ExtraDepth;
            
            linear_extrude(baseH)
            Plan();
            translate([0,0,baseH])
            linear_extrude(topH, scale=(Chamfer ? 1-topH/10 : 1))
            Plan();
            
            // Connector
            if(!End)
            translate([Length+ClearanceBed,0,0])
            Connection(R = R2);
        }
        
        if(!Start) {
            //Cavity
            Connection(R = R1, Cavity = true);
            
            // Top/Window cut
            ingress = R1-R1*cos(ArcAngle);
            translate([-2*R1 + ingress, -startWidth/2, Layer2-Overlap])
            cube([R1, startWidth, Level+Overlap*3]);
        }
    }
}

// Sequence of segments.
module Spine(rotateBy = travelAngle) {
    // Segment length compensating for gaps in segments.
    Length = Length/Segments - ClearanceBed + ClearanceBed/Segments;
    TrueLength = Length + ClearanceBed;
    
    function offsetX(i) = (i == 0 ? 0 : TrueLength*cos(rotateBy*i) + offsetX(i-1));
    function offsetY(i) = (i == 0 ? 0 : TrueLength*sin(rotateBy*i) + offsetY(i-1));

    translate([Length,0,0])
    for(i = [0 : 1 : Segments-1]) { 
        R1 = Widths[i]/2;
        R2 = (Widths[i+1] + ClearanceBed)/2;
        
        // debug link if(i==1)
        translate([offsetX(i), offsetY(i), 0])
        rotate([0,0,i*rotateBy])
        translate([-TrueLength, 0 ,0])
        Segment(R1, R2, Length, i==0, i==(Segments-1));
    }
}

Spine(0);

