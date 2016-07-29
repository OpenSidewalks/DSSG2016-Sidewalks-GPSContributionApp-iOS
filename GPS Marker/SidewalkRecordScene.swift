//
//  SidewalkRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 6/29/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class SidewalkRecordScene: RecordScene {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Recorded start and end point for sidewalk
    var sidewalkStart: CLLocation?
    var sidewalkStartDroppedPin : MKPointAnnotation?
    var sidewalkEnd: CLLocation?
    var sidewalkEndDroppedPin : MKPointAnnotation?
    
    // Drop down text fields
    @IBOutlet weak var dropDownView: UIView!
    
    // File System
    let sidewalkFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/sidewalk-collection.json"
    var sidewalkJSONLibrary: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sidewalk"
        
        // Map delegate configuration
        mapView.delegate = self
        
        // Location manager configuration
        super.locationManager.delegate = self
        super.locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load GeoJSON file
        self.sidewalkJSONLibrary = loadData(sidewalkFilePath)
        
        dropDown.anchorView = self.dropDownView
    }
    
    // MARK: -Action
    
    @IBAction func callDropDown(sender: UIButton) {
        var senderTitle = "Unknown"
        
        switch (sender.tag) {
        case 50:
            senderTitle = "Access"
        case 51:
            senderTitle = "Surface"
            break
        default:
            break
        }
        
        displayDropDown(senderTitle, sender: sender)
    }
    
    
    /**
     Start recording when user clicked "sidewalk start" button
     */
    @IBAction func sidewalkRecordStart() {
        // Get current location
        self.sidewalkStart = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = self.sidewalkStart {
            print("Long: \(validLocation.coordinate.longitude)")
            print("Lat: \(validLocation.coordinate.latitude)")
            print("Horizontal: \(validLocation.horizontalAccuracy) meters")
            print("Vertical: \(validLocation.verticalAccuracy) meters")
        } else {
            print("Unable to get location information!")
            return
        }
        
        // Set mapView annotation
        // The span value is made relative small, so a big portion of London is visible. The MKCoordinateRegion method defines the visible region, it is set with the setRegion method.
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: self.sidewalkStart!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if sidewalkStartDroppedPin != nil {
            mapView.removeAnnotation(sidewalkStartDroppedPin!)
            sidewalkStartDroppedPin = nil
        }
        
        sidewalkStartDroppedPin = MKPointAnnotation()
        sidewalkStartDroppedPin!.coordinate = self.sidewalkStart!.coordinate
        sidewalkStartDroppedPin!.title = "Sidewalk Start"
        mapView.addAnnotation(sidewalkStartDroppedPin!)
        
        // Adjust button visiblities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = true
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.enabled = false
    }
    
    /**
     End recording when user clicked "sidewalk end" button
     */
    @IBAction func sidewalkRecordEnd() {
        // Get current location
        self.sidewalkEnd = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = self.sidewalkEnd {
            print("Long: \(validLocation.coordinate.longitude)")
            print("Lat: \(validLocation.coordinate.latitude)")
            print("Horizontal: \(validLocation.horizontalAccuracy) meters")
            print("Vertical: \(validLocation.verticalAccuracy) meters")
        } else {
            print("Unable to get location information!")
            return
        }
        
        // Stop map user tracking mode
        mapView.userTrackingMode = .None
        mapView.showsUserLocation = false
        
        // Set mapView annotation
        // The span value is made relative small, so a big portion of London is visible. The MKCoordinateRegion method defines the visible region, it is set with the setRegion method.
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: self.sidewalkEnd!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if sidewalkEndDroppedPin != nil {
            mapView.removeAnnotation(sidewalkEndDroppedPin!)
            sidewalkEndDroppedPin = nil
        }
        
        sidewalkEndDroppedPin = MKPointAnnotation()
        sidewalkEndDroppedPin!.coordinate = self.sidewalkEnd!.coordinate
        sidewalkEndDroppedPin!.title = "Sidewalk End"
        mapView.addAnnotation(sidewalkEndDroppedPin!)
        
        if sidewalkStart == nil || sidewalkEnd == nil {
            NSLog("nil value found for sidewalk recording scene")
            NSLog("Sidewalk Start: \(sidewalkStart)")
            NSLog("Sidewalk End: \(sidewalkEnd)")
            return
        }
        
        // Draw a line between start and end coordinate
        var points = [self.sidewalkStart!.coordinate, self.sidewalkEnd!.coordinate]
        let geodesic = MKGeodesicPolyline(coordinates: &points[0], count:2 )
        self.mapView.addOverlay(geodesic)
        
        // Adjust button visibilities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = false
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.enabled = true
    }
    
    /**
     Cancel recording when user clicked "cancel" button
     */
    @IBAction func cancelRecording() {
        resetAll()
    }
    
    /**
     Save recording when user clicked "save" button
     */
    override func saveRecording() {
        super.saveRecording()
        
        // a variable indicating whether recording is saved
        var saveSuccess = true
        
        if self.sidewalkStart == nil {
            print("Start is nil")
            return
        }
        
        if self.sidewalkEnd == nil {
            print("End is nil")
            return
        }
        
        // Save File
        if sidewalkJSONLibrary != nil {
            let startCoordinate = self.sidewalkStart!.coordinate
            let endCoordinate = self.sidewalkEnd!.coordinate
            
            // Construct new entry using recorded information
            let newEntry = [["type": "Feature",
                "geometry": ["type": "LineString",
                    "coordinates": [[startCoordinate.latitude, startCoordinate.longitude],
                        [endCoordinate.latitude, endCoordinate.longitude]]]]]
            
            // Concatenate the new entry with old entries
            sidewalkJSONLibrary!["features"] = JSON(sidewalkJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
            
            // Debug: Show saved file
            print("Recorded GeoJSON: \(sidewalkJSONLibrary)")
            
            
            do {
                try sidewalkJSONLibrary?.rawData().writeToFile(sidewalkFilePath, atomically: true)
            } catch {
                saveSuccess = false
            }
        } else {
            saveSuccess = false
        }
        
        // Show alert to user
        showSaveSuccessAlert(saveSuccess)
        
        resetAll()
    }
    
    /**
     Reset all scene attributes and visible items to their initial state
     */
    override func resetAll() {
        super.resetAll()
        resetMap(mapView)
        
        // reset button visibility
        startButton.hidden = false
        startButton.enabled = true
        
        endButton.hidden = true
        endButton.enabled = false
        
        cancelButton.hidden = true
        cancelButton.enabled = false
        
        // reset all recording variables
        sidewalkStart = nil
        sidewalkStartDroppedPin = nil
        sidewalkEnd = nil
        sidewalkEnd = nil
    }
    
    
    //MARK:- CLLocationManagerDelegate methods
    
    override func locationServiceDisabled(manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.enabled = false
        endButton.enabled = false
        mapView.userTrackingMode = .None
    }
    
    override func locationServiceNotDetermined(manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.enabled = false
        endButton.enabled = false
        mapView.userTrackingMode = .None
    }
    
}
