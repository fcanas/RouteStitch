//
//  ViewController.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import Cocoa
import MapKit

class TouchPoint: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String {
        get {
            return "(\(coordinate.latitude), \(coordinate.longitude))"
        }
    }
    init (coordinate: CLLocationCoordinate2D){
        self.coordinate = coordinate
    }
}

class ViewController: NSViewController, MKMapViewDelegate  {

    @IBOutlet weak var mapView: MKMapView!
    
    var touchPoints :[TouchPoint] = Array()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let providenceCoord = CLLocationCoordinate2DMake(41.82526, -71.41117)
        let smallSpan = MKCoordinateSpanMake(0.003, 0.003)
        let providenceRegion = MKCoordinateRegionMake(providenceCoord, smallSpan)
        mapView.region = providenceRegion
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func didPressOnMap(sender: NSPressGestureRecognizer) {
        if sender.state != NSGestureRecognizerState.Began {
            return
        }
        let touchCoord = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
        
        if touchPoints.count >= 3 {
            return
        }
        let touchPoint = TouchPoint(coordinate: touchCoord)
        touchPoints.append(touchPoint)
        
        mapView.addAnnotation(touchPoint)
        
        if touchPoints.count == 3 {
            buildRouteOnMap()
        }
    }
    
    func buildRouteOnMap() {
        routeFromCoordinate(touchPoints[0].coordinate, destinationCoordinate: touchPoints[1].coordinate)
        routeFromCoordinate(touchPoints[1].coordinate, destinationCoordinate: touchPoints[2].coordinate)
    }
    
    func routeFromCoordinate(source: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.transportType = MKDirectionsTransportType.Walking
        request.setSource(mapItemWithCoordinate(source))
        request.setDestination(mapItemWithCoordinate(destinationCoordinate))
        
        MKDirections(request: request).calculateDirectionsWithCompletionHandler { (response: MKDirectionsResponse!, error: NSError!) -> Void in
            let route = response.routes.first as MKRoute!
            self.mapView.addOverlay(route.polyline)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let render = MKPolylineRenderer(polyline: overlay as MKPolyline?)
        render.strokeColor = NSColor.magentaColor().colorWithAlphaComponent(0.5)
        render.lineWidth = 5
        return render
    }
    
    func mapItemWithCoordinate(coordinate: CLLocationCoordinate2D) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        for v: MKPinAnnotationView in views as [MKPinAnnotationView] {
            v.animatesDrop = true
        }
    }

}

