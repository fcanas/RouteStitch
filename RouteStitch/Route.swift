//
//  Route.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import MapKit

func joinRouteSteps(steps: [MKRouteStep]) -> [MKRouteStep] {
    return steps.map {(step: MKRouteStep) -> MKRouteStep in
        return Step(instructions: step.instructions, polyline: step.polyline, distance: step.distance)
    }
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
            
            let firstStep = routeSteps.first
            let lastPriorStep = steps.last
            
            if firstStep != nil && lastPriorStep != nil {
                routeSteps.removeAtIndex(0)
                steps.removeLast()
                steps = steps + joinRouteSteps([lastPriorStep!, firstStep!])
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
