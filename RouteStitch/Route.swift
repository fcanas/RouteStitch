//
//  Route.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import MapKit

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
            steps = steps + (route.steps as [MKRouteStep])
            
            // Distance
            distance += route.distance
        }
        
        polyline = MKPolyline(points: &newPoints, count: newPoints.count)
    }
}
