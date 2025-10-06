//
//  ContentView.swift
//  MultiplePointRouteMap
//
//  Created by 相 on 28/09/2025.
//

// just push for discord-github webhook test

import SwiftUI
import MapKit
import CoreLocation


struct ContentView: View {
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.334886, longitude: -122.008988),
            span:MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    @State private var latitude:String=" "
    @State private var longitude:String=" "
    @State private var addressList:[String] = [
        //"50.1094,8.6638",//Frankfurt train station
        //"52.525,13.369",//Berlin train station
        //"48.10344,11.58762",//Muenchen train station
        //"48.690320,9.195363",//Stuttgart air port?
        //"49.494416,11.077907",//Nuernberg air port
        //28 random choose coordination in Germany to test out limit, cause Apple map has limit on 15.
        "47.557545,10.749682",//Neuschwanstein Castle
        "50.941319,6.958210",//Cologne Cathedral
        "51.831158,6.281709",//the Black Forest, germany
        "53.543749,9.988919",//Miniatur WunderlandK
        "51.333656,14.965674",//laus Neubert Mosterei
        "50.767655,6.076737",//Luisenhospital
        "50.938392,6.943642",
        "51.358177,7.474298",
        "51.543580,7.219928",
        "51.676518,7.125219",
        "51.763013,7.892970",
        "50.974115,11.033793",
        "53.629159,11.412945",
        "53.790687,12.177482",
        "54.088823,12.129883",
        "54.099618,12.074064",
        "54.134106,12.071304",
        "53.075945,8.837631",
        "52.268049,8.038520",
        "52.265255,8.050522",
        "52.258373,8.056927",
        "52.259703,8.089687",
        "52.208584,8.343320",
        "52.192618,8.354035",
        "52.189911,8.356418",
        "51.313731,9.467728",
        "51.316368,9.455279",
        "51.326512,9.444396",
        "51.304685,9.573564",
        
    ]
    
    @State private var routePolyLine:MKPolyline?
    
    @State private var selectedTab:Int = 0
    
    var body: some View {
        VStack {
            Map(position: $position){
                //Marker("san francisco",coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                
                if selectedTab==1{
                    ForEach(addressList, id:\.self){ address in
                        let spliter=address.split(separator: ",").map{ String($0) }
                        if spliter.count==2,let lat=Double(spliter[0]), let lon=Double(spliter[1]){
                            Marker("name_address",coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        }
                    }
                    if let polyLine = routePolyLine {
                        MapPolyline(polyLine)
                            .stroke(Color.blue, lineWidth: 4)
                    }
                }
            }
            .frame(height: 500)
            .padding(.bottom)
            
            TabView(selection: $selectedTab){
                VStack{
                    TextField("Enter Latitude",text: $latitude)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Enter Longitude",text: $longitude)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack{
                        Button{
                            
                        }label: {
                            Text("Present on map")
                                .foregroundStyle(Color.white)
                        }
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray)
                        )
                        
                        Button{
                            
                        }label: {
                            Text("Mark and store location")
                                .foregroundStyle(Color.white)
                        }
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray)
                        )
                    }
                    Spacer()
                }
                
                
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .tabItem {
                    Image(systemName: "globe.desk")
                    Text("Location")
                }
                .tag(0)
                
                
                VStack{
                    ForEach(addressList, id: \.self){ address in
                        Text(address)
                    }
                    Spacer()
                }
                .onAppear {
                    // Parse coordinates from addressList
                    let coords: [CLLocationCoordinate2D] = addressList.compactMap { address in
                        let parts = address.split(separator: ",").map { String($0) }
                        guard parts.count == 2,
                              let lat = Double(parts[0]),
                              let lon = Double(parts[1]) else { return nil }
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    guard coords.count >= 2 else {
                        routePolyLine = nil
                        return
                    }

                    // Build path using a greedy nearest-neighbor heuristic starting from the first point
                    var path: [CLLocationCoordinate2D] = [coords[0]]
                    var remaining = Array(coords.dropFirst())
                    var current = coords[0]

                    while !remaining.isEmpty {
                        let currentLoc = CLLocation(latitude: current.latitude, longitude: current.longitude)
                        var nearestIndex = 0
                        var nearestDistance = currentLoc.distance(from: CLLocation(latitude: remaining[0].latitude, longitude: remaining[0].longitude))
                        if remaining.count > 1 {
                            for i in 1..<remaining.count {
                                let d = currentLoc.distance(from: CLLocation(latitude: remaining[i].latitude, longitude: remaining[i].longitude))
                                if d < nearestDistance {
                                    nearestDistance = d
                                    nearestIndex = i
                                }
                            }
                        }
                        let next = remaining.remove(at: nearestIndex)
                        path.append(next)
                        current = next
                    }

                    // Helpers to build a driving polyline across the ordered coordinates
                    func routeBetween(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) async -> MKRoute? {
                        let source = MKMapItem(location: CLLocation(latitude: a.latitude, longitude: a.longitude), address: nil)
                        let dest = MKMapItem(location: CLLocation(latitude: b.latitude, longitude: b.longitude), address: nil)
                        let request = MKDirections.Request()
                        request.source = source
                        request.destination = dest
                        request.transportType = .automobile
                        let directions = MKDirections(request: request)
                        do {
                            let response = try await directions.calculate()
                            return response.routes.first
                        } catch {
                            return nil
                        }
                    }

                    func buildDrivingPolyline(for path: [CLLocationCoordinate2D]) async -> MKPolyline? {
                        guard path.count >= 2 else { return nil }
                        var allCoords: [CLLocationCoordinate2D] = []
                        for i in 0..<(path.count - 1) {
                            if let route = await routeBetween(path[i], path[i+1]) {
                                let poly = route.polyline
                                let count = poly.pointCount
                                var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: count)
                                poly.getCoordinates(&coords, range: NSRange(location: 0, length: count))
                                if !allCoords.isEmpty && !coords.isEmpty {
                                    coords.removeFirst() // avoid duplicate point at the join
                                }
                                allCoords.append(contentsOf: coords)
                            } else {
                                // Fallback: straight segment if a leg fails
                                var segment = [path[i], path[i+1]]
                                if !allCoords.isEmpty {
                                    segment.removeFirst()
                                }
                                allCoords.append(contentsOf: segment)
                            }
                        }
                        guard !allCoords.isEmpty else { return nil }
                        return MKPolyline(coordinates: allCoords, count: allCoords.count)
                    }

                    // Build and display the driving route
                    Task {
                        if let polyline = await buildDrivingPolyline(for: path) {
                            await MainActor.run {
                                routePolyLine = polyline
                                position = .region(MKCoordinateRegion(polyline.boundingMapRect))
                            }
                        } else {
                            let fallback = MKPolyline(coordinates: path, count: path.count)
                            await MainActor.run {
                                routePolyLine = fallback
                                position = .region(MKCoordinateRegion(fallback.boundingMapRect))
                            }
                        }
                    }
                }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(1)
            }
            
        }
        
    }
}

#Preview {
    ContentView()
}

