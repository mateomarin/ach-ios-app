//
//  EnrollmentRequest.swift
//  connect_api
//
//  Created by Mateo Marin on 12/9/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

import Foundation

//enrollment request class
class EnrollmentRequest{
    var application = EnrollmentApp()
    var user = EnrollmentUser()
    var billing_address = Address()
    var additional_info = AdditionalPersonalInfo?.self
    var first:String?
    var last:String?
    func json() -> NSDictionary{
        let user_json:NSDictionary = user.json()
        let app_json:NSDictionary = application.json()
        let address_json:NSDictionary = billing_address.json()
        let dict:NSDictionary = ["first_name": first!, "last_name": last!, "user": user_json, "application": app_json, "billing_address": address_json]
        return dict
    }
}

struct EnrollmentUser{
    var routingNumber: String, accountNumber: String, socialSecurityNumber: String
    init(){
        routingNumber = "311373125"
        accountNumber = "728001010"
        socialSecurityNumber = "098257123"
    }
    
    func json() -> NSDictionary{
        let dict:NSDictionary = ["routing_number": routingNumber, "account_number": accountNumber, "ssn": socialSecurityNumber]
        return dict
    }
}

struct EnrollmentApp{
    var application: String, device:String, imei:String, applicationId:String, deviceId:String, ipAddress:String, trueIpAddress:String, organizationId:String
    init(){
        application = "PayeezyACH"
        device = "DeviceXYZ123"
        imei = "IMEI76856745"
        applicationId = "76ed6b08-224d-4f2e-9771-28cb5c9f26bd"
        deviceId = "DeviceID65657"
        ipAddress = "192.168.1.1"
        trueIpAddress = "192.168.1.1"
        organizationId = "FirtsDataInternalUAID9999"
    }
    func json() -> NSDictionary{
        let dict:NSDictionary = ["application": application, "device": device, "imei": imei, "application_id": applicationId, "device_id": deviceId, "ip_address": ipAddress, "true_ip_address": trueIpAddress, "organizationId": organizationId]
        return dict
    }
}

struct Address{
    var street:String, state:String, city:String, country:String, email:String, phone:NSDictionary, zip:String
    init(){
        street = "7979 Westheimer"
        state = "TX"
        city = "Houston"
        country = "0804"
        email = "jsmith@email.com"
        phone = ["type": "MOBILE", "number": "9999955555"]
        zip = "77063"
    }
    func json() -> NSDictionary{
        let dict:NSDictionary = ["street": street, "state_province": state, "city": city, "country": country, "email": email, "phone": phone, "zip_postal_code": zip]
        return dict
    }
}

struct AdditionalPersonalInfo{
    
}
