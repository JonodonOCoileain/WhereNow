
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