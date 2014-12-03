//
//  Route.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import MapKit

func joinRouteSteps(steps: [MKRouteStep]) -> [MKRouteStep] {
    let pl1 = steps[0].polyline
    let pl2 = steps[2].polyline
    
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

    // Do the steps match end-to-end and not overlap?
    if numberOfMatchedPoints == 1 {
        return [steps[2]]
        // TODO - if they are not colinear, we need to generate a maneuver.
    }
    
    // Are they overlapping?
    
    // Short? -  Trimming needs to be done recursively because back-tracking may span many maneuvers.
    
//    if MKMetersBetweenMapPoints(firstMatchedPoint!, lastMatchedPoint!) < 50 {
//        return []
//    }
    // Long?
    
    NSLog("cutting : \(steps[0].instructions) :: \(steps[1].instructions)")
    return [Step(instructions: "Turn around", polyline: steps.first!.polyline, distance: steps.first!.distance), steps[2]]
}

class Route: NSObject {
    var polyline: MKPolyline
    var steps: [MKRouteStep]
    var distance: CLLocationDistance

    init(routes: [MKRoute?]) {
        var newPoints: [MKMapPoint] = []
        steps = Array()
        distance = 0
        for route in (routes as [MKRoute!]) {
            // Coordinates
            let points = route.polyline.points()
            for i in 0..<route.polyline.pointCount {
                newPoints.append(points[i])
            }
            
            // Steps
            var routeSteps = route.steps as [MKRouteStep]
            
            let firstSteps = [routeSteps[0], routeSteps[1] ]
            let lastPriorStep = steps.last
            
            if lastPriorStep != nil {
                routeSteps.removeRange(0...1)
                steps.removeLast()
                steps = steps + joinRouteSteps([lastPriorStep!] + firstSteps )
            }
            
            steps = steps + (routeSteps as [MKRouteStep])
            
            steps = steps.map { (s: MKRouteStep) -> Step in
                return s as? Step ?? Step(step: s)
            }
            
            // Distance
            distance += route.distance
        }
        
        polyline = MKPolyline(points: &newPoints, count: newPoints.count)
    }
}
