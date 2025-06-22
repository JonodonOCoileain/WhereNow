//
//  CarPlaySceneDelegate.swift
//  WhereNow
//
//  Created by Jonathan Lavallee Collins on 3/23/25.
//


#if os(iOS)
import CarPlay
import Foundation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    
    // CarPlay connected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        
        //setInformationTemplate()
        
        let listTemplate: CPListTemplate = CarPlayHelloWorld().template
        interfaceController.setRootTemplate(listTemplate, animated: true)
    }

    // CarPlay disconnected
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
    
}


class CarPlayHelloWorld {
    let locationData = LocationDataModel()
    let birdData = BirdSightingService()
    
    init() {
        locationData.start()
        if let currentLocation = locationData.currentLocation {
            birdData.cacheNotableSightings(using: currentLocation.coordinate, and: true)
        }
    }
    
    var template: CPListTemplate {
        return CPListTemplate(title: "Where Now", sections: [self.section])
    }
    
    var items: [CPListItem] {
        let cpListItems: [CPListItem] = birdData.notableSightings.map({CPListItem(text: $0.comName, detailText: $0.locId)})
        
        /*for item in cpListItems {
            if let item = birdData.speciesMedia.first(where: { $0.comName == item.text }) {
                
            }
        }*/
        
        return cpListItems
    }
    
    private var section: CPListSection {
        return CPListSection(items: items)
    }
}
#endif
