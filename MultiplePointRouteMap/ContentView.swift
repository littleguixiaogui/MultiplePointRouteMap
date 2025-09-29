//
//  ContentView.swift
//  MultiplePointRouteMap
//
//  Created by 相 on 28/09/2025.
//

import SwiftUI
import MapKit
import CoreLocation


struct ContentView: View {
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span:MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @State private var latitude:String=" "
    @State private var longitude:String=" "
    @State private var addressList:[String] = [
        "50.1094,8.6638",//Frankfurt train station
        "52.525,13.369",//Berlin train station
    ]
    
    @State private var routePolyLine:MKPolyline?
    
    @State private var selectedTab:Int = 0
    
    var body: some View {
        VStack {
            Map(position: $position){
                Marker("san francisco",coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                
                if selectedTab==1{
                    if let polyLine=routePolyLine{
                        MapPolyline(polyLine)
                            .stroke(Color.blue, lineWidth: 4)
                    }
                }
                
                if selectedTab==2{
                    ForEach(addressList, id:\.self){ address in
                        let spliter=address.split(separator: ",").map{ String($0) }
                        if spliter.count==2,let lat=Double(spliter[0]), let lon=Double(spliter[1]){
                            Marker("random",coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        }
                    }
                }
            }
            .frame(height: 300)
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
                    
                    Button{
                        guard addressList.count >= 2 else {return}
                        let firstAddress = addressList[0].split(separator: ",").map{ String($0) }
                        let secondAddress = addressList[1].split(separator: ",").map{String($0)}
                        
                        guard firstAddress.count==2, secondAddress.count==2,
                              let startLatitude = Double(firstAddress[0]),
                              let startLongitude = Double(firstAddress[1]),
                              let endLatitude = Double(secondAddress[0]),
                              let endLongitude = Double(secondAddress[1])
                        else {return}
                        
                        let startPlacemark=MKMapItem(location: CLLocation(latitude: startLatitude, longitude: startLongitude),address:nil)
                        let endPlacemark=MKMapItem(location: CLLocation(latitude: endLatitude, longitude: endLongitude),address:nil)
                        
                        let request=MKDirections.Request()
                        request.source=startPlacemark
                        request.destination=endPlacemark
                        request.transportType = .automobile
                        
                        let directions=MKDirections(request: request)
                        directions.calculate{response, error in
                            if let route=response?.routes.first{
                                routePolyLine=route.polyline
                                position = .region(MKCoordinateRegion(route.polyline.boundingMapRect))
                            }
                        }
                    }label: {
                        Text("Make Route")
                            .foregroundStyle(Color.white)
                    }
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.gray)
                    )
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "point.forward.to.point.capsulepath")
                    Text("Route")
                }
                .tag(1)
                
                VStack{
                    Text("List")
                    ForEach(addressList, id: \.self){ address in
                        Text(address)
                    }
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(2)
            }
            
        }
        
    }
}

#Preview {
    ContentView()
}
