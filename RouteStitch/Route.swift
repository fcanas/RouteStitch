//
//  Route.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import MapKit

func matchedPointsForSteps(firstStep: MKRouteStep, secondStep: MKRouteStep) -> Int {
    let pl1 = firstStep.polyline
    let pl2 = secondStep.polyline
    
    let points1 = pl1.points()
    let points2 = pl2.points()
    
    var numberOfMatchedPoints = 0
    var firstMatchedPoint: MKMapPoint?
    var lastMatchedPoint: MKMapPoint?
    
    for var endOffset = 0; endOffset < min(pl1.pointCount, pl2.pointCount); endOffset++ {
        let p1 = points1[pl1.pointCount - 1 - endOffset]
        let p2 = points2[endOffset]
        if MKMetersBetweenMapPoints(p1, p2) < 4 {
            if firstMatchedPoint == nil {
                firstMatchedPoint = p1
            }
            numberOfMatchedPoints++
            lastMatchedPoint = p1
        }
    }
    return numberOfMatchedPoints
}

func vectorAtPolylineTail(polyline: MKPolyline) -> CGVector {
    let points = polyline.points()
    let p0 = points[polyline.pointCount - 1]
    let p1 = points[polyline.pointCount - 2]
    
    let dx = p1.x - p0.x
    let dy = p1.y - p0.y
    
    return CGVectorMake( CGFloat(dx), CGFloat(dy) )
}

func vectorAtPolylineHead(polyline: MKPolyline) -> CGVector {
    let points = polyline.points()
    let p0 = points[0]
    let p1 = points[1]
    
    let dx = p1.x - p0.x
    let dy = p1.y - p0.y
    
    return CGVectorMake( CGFloat(dx), CGFloat(dy) )
}

func normalize(v: CGVector) -> CGVector {
    let m = magnitude(v)
    return CGVector(dx: v.dx/m, dy: v.dy/m)
}

func magnitude(v: CGVector) -> CGFloat {
    return sqrt(v.dx * v.dx + v.dy * v.dy)
}

func - (lhs: CGVector , rhs: CGVector) -> CGVector {
    return CGVector(dx:lhs.dx-rhs.dx, dy:lhs.dy-rhs.dy)
}

func + (lhs: CGVector , rhs: CGVector) -> CGVector {
    return CGVector(dx:lhs.dx+rhs.dx, dy:lhs.dy+rhs.dy)
}

func polylinesOverlapOnEnds(p1: MKPolyline, p2: MKPolyline) -> Bool {
    let difference = normalize(vectorAtPolylineTail(p1)) - normalize(vectorAtPolylineHead(p2))
    return magnitude(difference) < 0.1
}

func polylinesAreColinearNonOverlapping(p1: MKPolyline, p2: MKPolyline) -> Bool {
    let sum = normalize(vectorAtPolylineTail(p1)) + normalize(vectorAtPolylineHead(p2))
    return magnitude(sum) < 0.1
}

func joinRouteEnds(steps: [MKRouteStep]) -> [MKRouteStep] {
    
    let numberOfMatchedPoints = matchedPointsForSteps(steps[0], steps[2])
    
    // Do the steps match end-to-end
    if numberOfMatchedPoints >= 1 {
        let silentStep = Step(step: steps[0])
        
        if polylinesOverlapOnEnds(steps[0].polyline, steps[1].polyline) {
            silentStep.setInstructions("Turn around")
            silentStep.isSpur = true
        } else {
            silentStep.setInstructions("")
        }
        
        return [silentStep, steps[2]]
        // TODO - if they are not colinear, we need to generate a maneuver.
    }
    NSLog("cutting : everything... : \(steps)")
    return []
}

func filterRouteSteps(steps: [Step]) -> [Step] {
    var newSteps: [Step] = Array();
    for var idx = 0; idx < steps.count; idx++ {
        let step = steps[idx]
        let stepCoordinate = step.coordinate
        if (idx + 1) < steps.count {
            let nextStep = steps[idx + 1]
            let nextCoordinate = nextStep.coordinate
            let distance = locationFromCoordinate(stepCoordinate).distanceFromLocation(locationFromCoordinate(nextCoordinate))
            
            // Short Spur detection
            if (idx > 1 && step.isSpur && distance < 60 && steps.count > (idx + 2)) {
                let previousStep = steps[idx - 1]
                let nextNextStep = steps[idx + 2]
                if polylinesAreColinearNonOverlapping(previousStep.polyline, nextNextStep.polyline) {
                    newSteps.removeLast()// TODO : re-draw full route ribbon
                    idx++
                    continue
                } else if polylinesOverlapOnEnds(previousStep.polyline, nextNextStep.polyline) {
                    previousStep.setInstructions("Turn around")// TODO : re-draw full route ribbon
                    previousStep.isSpur = true
                    newSteps.removeLast()
                    newSteps.append(previousStep)
                    idx++
                    continue
                }
            }
            
            if distance < 25 { // quick succession of instructions
                step.setInstructions(step.instructions + ", then " + nextStep.instructions)
                nextStep.detectionRadius = 20
            }
        }
        newSteps.append(step)
    }
    return newSteps
}

func locationFromCoordinate(coordinate: CLLocationCoordinate2D) -> CLLocation {
    return CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
}


func join(polylines: [MKPolyline]) -> MKPolyline {
    var accumulatedPoints: [MKMapPoint] = []
    for polyline in polylines {
        let points = polyline.points()
        for i in 0..<polyline.pointCount {
            accumulatedPoints.append(points[i])
        }
    }
    return MKPolyline(points: &accumulatedPoints, count: accumulatedPoints.count)
}

func join(routes: [MKRoute]) -> Route {
    var steps :[MKRouteStep] = []
    var steps_ :[Step] = []
    var distance :CLLocationDistance = 0
    for route in routes {
        // Steps
        var routeSteps = route.steps as [MKRouteStep]
        
        let firstSteps = [routeSteps[0], routeSteps[1] ]
        let lastPriorStep = steps.last
        
        if lastPriorStep != nil {
            routeSteps.removeRange(0...1)
            steps.removeLast()
            steps = steps + joinRouteEnds([lastPriorStep!] + firstSteps )
        }
        
        steps = steps + (routeSteps as [MKRouteStep])
        steps_ = steps.map { (s: MKRouteStep) -> Step in
            return s as? Step ?? Step(step: s)
        }
        // Distance
        distance += route.distance
    }
    steps_ = filterRouteSteps(steps_)
    steps = steps_
    
    let polyline = join(steps_.map({ (step:Step) -> MKPolyline in
        step.polyline
    }))
    
    return Route(polyline: polyline, steps: steps, distance: distance)
}

class Route: NSObject {
    var polyline: MKPolyline
    var steps: [MKRouteStep]
    var distance: CLLocationDistance
    
    init(polyline: MKPolyline, steps:[MKRouteStep], distance: CLLocationDistance) {
        self.polyline = polyline
        self.steps = steps
        self.distance = distance
        super.init()
    }
    
    convenience init(routes: [MKRoute]) {
        let r = join(routes)
        self.init(polyline: r.polyline, steps: r.steps, distance: r.distance)
    }
}
