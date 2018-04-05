//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    
    // MARK: - Properties
    var  currentElement : String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager()
    var poiAnnotations: [MKPointAnnotation] = []
    
    
    // MARK: - Super Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        //Le o XML
        //loadXML()
        showAddress("MASP")
        
        
        requestUserLocationAuthorization()
        
    }
    
    func showAddress(_ address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            if error == nil {
                guard let placemarks = placemarks else {return}
                guard let placemark = placemarks.first else {return}
                guard let coordinate = placemark.location?.coordinate else {return}
                
                
                
                let annotation = MKPointAnnotation()
                annotation.title = placemark.postalCode ?? "---"
                annotation.coordinate = coordinate
                
                self.mapView.addAnnotation(annotation)
                
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400)
                self.mapView.setRegion(region, animated: true)
            
            }
        }
        
    }
    
    // MARK: - Method
    
    //Recuepra a rota entre a localização do usuário e o destino escolhido
    func getRoute(destination: CLLocationCoordinate2D){
        let request = MKDirectionsRequest()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                guard let response = response else {return}
               
                let routes = response.routes.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})
                
                guard let route = response.routes.first else {return}
                
                print("Nome da rota:",route.name)
                print("Distância:",route.distance)
                print("Duração:",route.expectedTravelTime)
                print("Tipo de transporte", route.transportType)
                
                for step in route.steps {
                    print("Em \(step.distance) metros, \(step.instructions)")
                }
                //Limpa rotas ja existentes
                self.mapView.removeOverlays(self.mapView.overlays)
                //adicionando rota abaixo do nome das ruas
                self.mapView.add(route.polyline, level: .aboveRoads)
                
                self.mapView.showAnnotations(self.mapView.annotations, animated: true)
            }
        }
    }
    
    
    func loadXML () {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser =
            XMLParser(contentsOf: xml) else {return}
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.url)
            
            mapView.addAnnotation(annotation)
        
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
          locationManager.delegate = self
          locationManager.desiredAccuracy = kCLLocationAccuracyBest
          //locationManager.allowsBackgroundLocationUpdates = true
            
          locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                print("Usuário já autorizou o uso da localização")
            case .denied:
                print("Usuário negou a autorização")
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Device restrito não tem o que o usuário fazer...")
            default:
                break
            }
        }
    }
    
}

// MARK:  implementando o Delegate do XMLParser
extension TheatersMapViewController: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
     currentElement = elementName
     
        if elementName == "Theater" {
            theater = Theater()
            
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print(string)
        // limpando o espaços e enters da string
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty{
            switch currentElement {
            case "name":
                theater.name = content
            case "address":
                theater.address = content
            case "latitude":
                theater.latitude = Double(content)!
            case "longitude":
                theater.longitude = Double(content)!
            case "url":
                theater.url = content
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "Theater" {
          theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
    
    
}

// MARK: - MKMapViewDelegate
extension TheatersMapViewController: MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let camera = MKMapCamera()
        camera.pitch = 80
        camera.altitude = 100
        camera.centerCoordinate = view.annotation!.coordinate
        mapView.setCamera(camera, animated: true)
    }
    
    
    // fazendo o desenho da rota no mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
           let renderer = MKPolylineRenderer(overlay: overlay)
           renderer.strokeColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
           renderer.lineWidth = 7.0
            return renderer
            
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView!
        
        
        if annotation is TheaterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
                //Criando o botão esquerdo dentro do balão dos nomes dos cinemas
                let btLeft = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                btLeft.setImage(UIImage(named: "car"), for: .normal)
                
                //Colocando o botão dentro da view
                annotationView.leftCalloutAccessoryView = btLeft
                
                //Criando o botão direito dentro do balão dos nomes dos cinemas
                let btRight = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = btRight
                
            } else {
                annotationView.annotation = annotation
            }
            
        } else if annotation is MKPointAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "POI")
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "POI")
                (annotationView as! MKPinAnnotationView).pinTintColor = .blue
                (annotationView as! MKPinAnnotationView).animatesDrop = true
                annotationView.canShowCallout = true
            } else {
                annotationView.annotation = annotation
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            //Tocamos no botão esquerdo
            
            getRoute(destination: view.annotation!.coordinate)
            
        } else {
            //Tocammos no botão direito
            
            if let vc = storyboard?.instantiateViewController(withIdentifier: "WebViewController" ) as?
                WebViewController {
                vc.url = view.annotation!.subtitle!
                //apresentando modalmente a View controller (por cima de tudo)
                present(vc, animated: true, completion: nil)
            }
            
        }
        
    }
    
}


extension TheatersMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Velocidade do usuário: \(userLocation.location?.speed ?? 0)")
        
        
        //acompanha o andar do usuário como o waze
        //let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)

        //mapView.setRegion(region, animated: true)
    }
    
}


extension TheatersMapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                guard let response = response else {return}
                self.mapView.removeAnnotations(self.poiAnnotations)
                self.poiAnnotations.removeAll()
                for item in response.mapItems {
                    let place = MKPointAnnotation()
                        place.coordinate = item.placemark.coordinate
                        place.title = item.placemark.name
                        place.subtitle = item.phoneNumber
                        self.poiAnnotations.append(place)
                }
                self.mapView.addAnnotations(self.poiAnnotations)
                
            }
        }
    }
}






