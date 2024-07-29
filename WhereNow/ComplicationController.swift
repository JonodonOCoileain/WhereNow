//
//  ComplicationController.swift
//  WhereAmI
//
//  Created by Jon on 7/11/24.
//
/*
import ClockKit
import SwiftUI

final class ComplicationController: NSObject, CLKComplicationDataSource {

    let data = LocationDataModel()

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        //
        let location = [CLKComplicationDescriptor(identifier: "whereNow-complication", displayName: "Where Now!", supportedFamilies: [CLKComplicationFamily.circularSmall, CLKComplicationFamily.extraLarge, CLKComplicationFamily.graphicBezel, CLKComplicationFamily.graphicCircular, CLKComplicationFamily.graphicCorner, CLKComplicationFamily.graphicExtraLarge,   CLKComplicationFamily.graphicRectangular, CLKComplicationFamily.modularLarge, CLKComplicationFamily.modularSmall, CLKComplicationFamily.utilitarianLarge, CLKComplicationFamily.utilitarianSmall, CLKComplicationFamily.utilitarianSmallFlat])]
        return handler(location)
    }

    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections
    ) -> Void) {
        handler([.forward, .backward])
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate!
        data.start()
        
        guard let placemark = data.placemarks.first else {
            handler(nil)
            return
        }
        switch complication.family {
        case .circularSmall:
            template = CLKComplicationTemplateCircularSmallStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateCircularSmallStackImage()
            //template = CLKComplicationTemplateCircularSmallSimpleText()
            //template = CLKComplicationTemplateCircularSmallSimpleImage()
            //template = CLKComplicationTemplateCircularSmallRingText()
            //template = CLKComplicationTemplateCircularSmallRingImage()

            break;
        case .extraLarge:
            template = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateExtraLargeStackImage()
            //template = CLKComplicationTemplateExtraLargeSimpleText()
            //template = CLKComplicationTemplateExtraLargeSimpleImage()
            //template = CLKComplicationTemplateExtraLargeRingText()
            //template = CLKComplicationTemplateExtraLargeRingImage()
            //template = CLKComplicationTemplateExtraLargeColumnsText()
            break;
        case .modularSmall:
            template = CLKComplicationTemplateModularSmallStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //emplate = CLKComplicationTemplateModularSmallStackImage()
            //template = CLKComplicationTemplateModularSmallSimpleText()
            //template = CLKComplicationTemplateModularSmallSimpleImage()
            //template = CLKComplicationTemplateModularSmallRingText()
            //template = CLKComplicationTemplateModularSmallRingImage()
            //template = CLKComplicationTemplateModularSmallColumnsText()
            break;
        case .modularLarge:
            template = CLKComplicationTemplateModularLargeTable(headerTextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), row1Column1TextProvider: CLKSimpleTextProvider(text:placemark.localityAndAdministrativeArea()), row1Column2TextProvider: CLKSimpleTextProvider(text:placemark.postalCode ?? ""), row2Column1TextProvider: CLKSimpleTextProvider(text:placemark.country ?? ""), row2Column2TextProvider: CLKSimpleTextProvider(text:data.flag))
            //template = CLKComplicationTemplateModularLargeColumns()
            //template = CLKComplicationTemplateModularLargeTallBody()
            //template = CLKComplicationTemplateModularLargeStandardBody()
            break;
        case .utilitarianSmall:
            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text:placemark.makeAddressString()), imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
            //template = CLKComplicationTemplateUtilitarianSmallSquare()
            //template = CLKComplicationTemplateUtilitarianSmallRingText()
            //emplate = CLKComplicationTemplateUtilitarianSmallRingImage()
            break;
        case .utilitarianSmallFlat:
            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea(), shortText: placemark.locality ?? placemark.thoroughfare ?? placemark.country ?? "") , imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
        case .utilitarianLarge:
            template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider:CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea(), shortText: placemark.locality ?? placemark.thoroughfare ?? placemark.country ?? "") , imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
            break;
        case .graphicCorner:
            //template = CLKComplicationTemplateGraphicCornerCircularImage()
            //template = CLKComplicationTemplateGraphicCornerGaugeText()
            //template = CLKComplicationTemplateGraphicCornerGaugeImage()
            template = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), outerTextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateGraphicCornerTextImage()
            break;
        case .graphicCircular:
            template = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage()))
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeImage()
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            //template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            //template = CLKComplicationTemplateGraphicCircularClosedGaugeImage()
            break;
        case .graphicBezel:
            template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage())), textProvider: CLKSimpleTextProvider(text:placemark.thoroughfaresAndLocality()))
            break;
        case .graphicRectangular:
            template = CLKComplicationTemplateGraphicRectangularLargeImage(textProvider: CLKSimpleTextProvider(text: placemark.makeAddressString(), shortText: placemark.thoroughfaresAndLocality()), imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage()))
            //template = CLKComplicationTemplateGraphicRectangularStandardBody()
            //template = CLKComplicationTemplateGraphicRectangularTextGauge
            break;
        case .graphicExtraLarge:
            //template = CLKComplicationTemplateGraphicExtraLargeCircularImage()
            template = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfaresAndLocality(), shortText: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.codeAndCountry()))
            //template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeImage()
            //template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeRangeText()
        @unknown default:
            break
        }
        handler(template)
    }

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let date = Date()
        var template: CLKComplicationTemplate!
        guard let placemark = data.placemarks.first else { return }
        switch complication.family {
        case .circularSmall:
            template = CLKComplicationTemplateCircularSmallStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateCircularSmallStackImage()
            //template = CLKComplicationTemplateCircularSmallSimpleText()
            //template = CLKComplicationTemplateCircularSmallSimpleImage()
            //template = CLKComplicationTemplateCircularSmallRingText()
            //template = CLKComplicationTemplateCircularSmallRingImage()

            break;
        case .extraLarge:
            template = CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateExtraLargeStackImage()
            //template = CLKComplicationTemplateExtraLargeSimpleText()
            //template = CLKComplicationTemplateExtraLargeSimpleImage()
            //template = CLKComplicationTemplateExtraLargeRingText()
            //template = CLKComplicationTemplateExtraLargeRingImage()
            //template = CLKComplicationTemplateExtraLargeColumnsText()
            break;
        case .modularSmall:
            template = CLKComplicationTemplateModularSmallStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //emplate = CLKComplicationTemplateModularSmallStackImage()
            //template = CLKComplicationTemplateModularSmallSimpleText()
            //template = CLKComplicationTemplateModularSmallSimpleImage()
            //template = CLKComplicationTemplateModularSmallRingText()
            //template = CLKComplicationTemplateModularSmallRingImage()
            //template = CLKComplicationTemplateModularSmallColumnsText()
            break;
        case .modularLarge:
            template = CLKComplicationTemplateModularLargeTable(headerTextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), row1Column1TextProvider: CLKSimpleTextProvider(text:placemark.localityAndAdministrativeArea()), row1Column2TextProvider: CLKSimpleTextProvider(text:placemark.postalCode ?? ""), row2Column1TextProvider: CLKSimpleTextProvider(text:placemark.country ?? ""), row2Column2TextProvider: CLKSimpleTextProvider(text:data.flag))
            //template = CLKComplicationTemplateModularLargeColumns()
            //template = CLKComplicationTemplateModularLargeTallBody()
            //template = CLKComplicationTemplateModularLargeStandardBody()
            break;
        case .utilitarianSmall:
            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text:placemark.makeAddressString()), imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
            //template = CLKComplicationTemplateUtilitarianSmallSquare()
            //template = CLKComplicationTemplateUtilitarianSmallRingText()
            //emplate = CLKComplicationTemplateUtilitarianSmallRingImage()
            break;
        case .utilitarianSmallFlat:
            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea(), shortText: placemark.locality ?? placemark.thoroughfare ?? placemark.country ?? "") , imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
        case .utilitarianLarge:
            template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider:CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea(), shortText: placemark.locality ?? placemark.thoroughfare ?? placemark.country ?? "") , imageProvider: CLKImageProvider(onePieceImage: data.flag.toImage()))
            break;
        case .graphicCorner:
            //template = CLKComplicationTemplateGraphicCornerCircularImage()
            //template = CLKComplicationTemplateGraphicCornerGaugeText()
            //template = CLKComplicationTemplateGraphicCornerGaugeImage()
            template = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: CLKSimpleTextProvider(text: placemark.thoroughfares()), outerTextProvider: CLKSimpleTextProvider(text: placemark.localityAndAdministrativeArea() + (placemark.country ?? ""), shortText: placemark.localityAndAdministrativeArea()))
            //template = CLKComplicationTemplateGraphicCornerTextImage()
            break;
        case .graphicCircular:
            template = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage()))
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeImage()
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()
            //template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            //template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            //template = CLKComplicationTemplateGraphicCircularClosedGaugeImage()
            break;
        case .graphicBezel:
            template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage())), textProvider: CLKSimpleTextProvider(text:placemark.thoroughfaresAndLocality()))
            break;
        case .graphicRectangular:
            template = CLKComplicationTemplateGraphicRectangularLargeImage(textProvider: CLKSimpleTextProvider(text: placemark.makeAddressString(), shortText: placemark.thoroughfaresAndLocality()), imageProvider: CLKFullColorImageProvider(fullColorImage: data.flag.toImage()))
            //template = CLKComplicationTemplateGraphicRectangularStandardBody()
            //template = CLKComplicationTemplateGraphicRectangularTextGauge
            break;
        case .graphicExtraLarge:
            //template = CLKComplicationTemplateGraphicExtraLargeCircularImage()
            template = CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: CLKSimpleTextProvider(text: placemark.thoroughfaresAndLocality(), shortText: placemark.thoroughfares()), line2TextProvider: CLKSimpleTextProvider(text: placemark.codeAndCountry()))
            //template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeImage()
            //template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeRangeText()
        @unknown default:
            break
        }
        let entry = CLKComplicationTimelineEntry(
            date: date,
            complicationTemplate: template
        )
        handler(entry)
    }
    
    func scheduleNextReload() {
        let refreshTime = Date().advanced(by: 1)
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshTime,
            userInfo: nil,
            scheduledCompletion: { _ in }
        )
    }
    
    func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()

        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Private Method
    
    func getComplicationTemplate(for complication: CLKComplication, using date: Date) -> CLKComplicationTemplate? {
        switch complication.family {
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularFullView(ContentView())
        default:
            return nil
        }
    }
}

struct ComplicationController_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(CLKComplicationTemplate.PreviewFaceColor.allColors) { color in
            CLKComplicationTemplateGraphicRectangularFullView(ContentView()).previewContext(faceColor: color)
        }
    }
}


*/
