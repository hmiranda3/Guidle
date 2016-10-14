//
//  GlobleViewController.swift
//  Guidle
//
//  Created by Habib Miranda on 10/6/16.
//  Copyright © 2016 littleJohn's. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

protocol HandleMapSearch {
    func dropPinInZoom(placemark: MKPlacemark)
}

class GlobeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    // Mock locations Data
    var locationsArray: [CLLocationCoordinate2D] = [CLLocationCoordinate2D(latitude: 40.741895, longitude: -73.989308), CLLocationCoordinate2D(latitude: 40.185994, longitude: -111.61115699999999), CLLocationCoordinate2D(latitude: 40.7729961, longitude: -73.9817342), CLLocationCoordinate2D(latitude: 40.8300168, longitude: -73.85079869999998), CLLocationCoordinate2D(latitude: 37.703026, longitude: -121.759735), CLLocationCoordinate2D(latitude: 40.25011569999999, longitude: -111.64330919999998)]

    var searchController: UISearchController!
    var annotation: MKAnnotation!
    var localSearchRequest: MKLocalSearchRequest!
    var localSearch: MKLocalSearch!
    var localSearchResponse: MKLocalSearchResponse!
    var error: NSError!
    var pointAnnotation: MKPointAnnotation!
    var pinAnnotationView: MKPinAnnotationView!
    
    var resultSearchController: UISearchController? = nil
    var selectedPin: MKPlacemark? = nil


    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMapView()
        setupAnnotationData()
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        locationSearchTable.handleMapSearchDelegate = self
        
        //        This configures the search bar, and embeds it within the navigation bar.
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Add a new Pin!"
        navigationItem.titleView = resultSearchController?.searchBar
        
        
        //        hidesNavigationBarDuringPresentation determines whether the Navigation Bar disappears when the search results are shown. Set this to false, since we want the search bar accessible at all times.
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        
        //        dimsBackgroundDuringPresentation gives the modal overlay a semi-transparent background when the search bar is selected.
        resultSearchController?.dimsBackgroundDuringPresentation = true
        //        Setting definesPresentationContext to true is an important but easily overlooked step. By default, the modal overlay will take up the entire screen, covering the search bar. definesPresentationContext limits the overlap area to just the View Controller’s frame instead of the whole Navigation Controller.
        definesPresentationContext = true
        
        //        This passes along a handle of the mapView from the main View Controller onto the locationSearchTable.
        locationSearchTable.mapView = mapView
        
        
        locationSearchTable.handleMapSearchDelegate = self

        
    }

    override func viewDidAppear(_ animated: Bool) {
        authorizeStatus()
        mapView.showAnnotations(mapView.annotations, animated: true)
    }

    
    let locationManager = CLLocationManager()
    

    //MARK: Map and Locaation Functions:
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    func authorizeStatus() {
        //status is not determined:
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied {
            //If Authorization were denied:
            print("Access not granted")
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("error:: (error) THE ERROR IS HERE")
//    }
    
    func setupAnnotationData() {
        //Check if system can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            //Region Data
            for location in locationsArray {
                //            let title = "Lorenzillo's"
                let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                let regionRadius = 300.0
                
                //Setup Region
                let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: regionRadius, identifier: "")
                locationManager.startMonitoring(for: region)
                
                //setup annotation
                let restaurantAnnotation = MKPointAnnotation()
                restaurantAnnotation.coordinate = coordinate
                restaurantAnnotation.title = "Annotation"
                mapView.addAnnotation(restaurantAnnotation)
                
                //setup circle
                let circle = MKCircle(center: coordinate, radius: regionRadius)
                mapView.add(circle)
            }
        } else {
            print("System can't track regions")
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 0.5
        return circleRenderer
    }
    

    func segueToCities() {
        performSegue(withIdentifier: "toCitiesFromGlobe", sender: UIButton())
    }

    
    func presentAlert() {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Hello!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "You enetered a recommended region", arguments: nil)
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "notify-test"
        
//        _ = UNLocationNotificationTrigger.init(region: CLRegion, repeats: false)
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest.init(identifier: "notify-test", content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request)
    }

    //user enters region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        presentAlert()
        print("enter \(region.identifier)")
    }

}



extension GlobeViewController: HandleMapSearch {
    func dropPinInZoom(placemark: MKPlacemark){
        selectedPin = placemark
//        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        locationsArray.append(annotation.coordinate)
        //setup circle
        let circle = MKCircle(center: annotation.coordinate, radius: 300.0)
        mapView.add(circle)
    }
}

extension GlobeViewController {
    @objc(mapView:viewForAnnotation:) func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0,y :0), size: smallSquare))
        button.setBackgroundImage(UIImage(named: "heart"), for: .normal)
        
        button.addTarget(self, action: #selector(GlobeViewController.segueToCities), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
}



