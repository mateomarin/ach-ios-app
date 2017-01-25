//
//  FirstApiClient.swift
//  connect_api
//
//  Created by Mateo Marin on 12/7/16.
//  Copyright © 2016 Mateo Marin. All rights reserved.
//

import Foundation
import PayWithMyBank

public class FirstApiClient {
    var apiKey: String!
    var token: String!
    var apiUrl: String!
    var apiSecret: String!
    private var dataDict = [String: String]()
    private let payWithMyBankPanel:PayWithMyBankPanel = PayWithMyBankPanel()
    private let parentViewController:UIViewController!
    private var currentViewController:UIViewController?
    private var regularEnrollmentId:String?
    private var alertObj:UIAlertController?
    
    private let crypto = Crypto()
    private let baseURL = "https://api-cert.payeezy.com/v1/"

    //initialization
    required public init(apiKey: String, token: String, apiUrl: String, apiSecret: String, controller: UIViewController){
        self.apiKey = apiKey
        self.token = token
        self.apiUrl = apiUrl
        self.apiSecret = apiSecret
        self.dataDict = ["apiKey": apiKey, "token": token, "apiUrl": apiUrl, "apiSecret": apiSecret]
        self.parentViewController = controller
    }
    
    public func regularEnrollment(onCompletion: @escaping (_ enrollmentId: String)->Void){
        let regularEnrollmentForm:RegularEnrollmentForm = RegularEnrollmentForm()
        let regularEnrollmentController = UIViewController()
        currentViewController = regularEnrollmentController
        regularEnrollmentController.view = regularEnrollmentForm
        
        regularEnrollmentForm.cancel = {()->Void in
            self.currentViewController?.dismiss(animated: true, completion: nil)
        }
        regularEnrollmentForm.enroll = {(data, error)->Void in
            if error != nil {
                self.generateAlert(message: error!, action: true, title: nil)
            } else {
                self.enrollRegular(enrollmentRequest: data!, onCompletion: {(json, error)->Void in
                    if error != nil {
                        if error?.code == 123 {
                            self.generateAlert(message: "Please insert a valid number", action: true, title: nil)
                        } else {
                            self.generateAlert(message: "Problem with BAA Request", action: true, title: nil)
                        }
                    } else {
                        onCompletion(json?["token"] as! String)
                    }
                })
            }
        }
        DispatchQueue.main.async {
            self.parentViewController.present(self.currentViewController!, animated: true, completion: nil)
        }
    }
    
    //first step of regular enrollment
    private func enrollRegular(enrollmentRequest: NSDictionary, onCompletion: @escaping ([String: Any]?, NSError?) -> Void){
        let route = baseURL + "ach/consumer/enrollment"
        if(regularEnrollmentId == nil){
            generateAlert(message: "Please wait...", action: false, title: "Processing Enrollment")
            post(path_url: route, body: enrollmentRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
                self.dismissAlert()
                if error != nil {
                    onCompletion(nil, error!)
                } else {
                    self.regularEnrollmentId = json["token"] as! String?
                    self.microValidate(callback: onCompletion)
                }
            })
        } else {
            self.microValidate(callback: onCompletion)
        }
    }
    //intermediate microvalidation user input prompt
    private func microValidate(callback: @escaping ([String: Any]?, NSError?)->Void){
        callInputAlert(callback: {(authAnswer) -> Void in
            self.dismissAlert()
            let testInt = Int(authAnswer)
            if(authAnswer != "" && testInt != nil){
                self.generateAlert(message: "Micro validation in progress...", action: false, title: "BAA Request")
                let baaRequest: NSDictionary = ["token": self.regularEnrollmentId as AnyObject, "authentication_answer": authAnswer as AnyObject]
                self.callMicroValidate(baaRequest: baaRequest, onCompletion: {(json, error) -> Void in
                    self.dismissAlert()
                    if error != nil {
                        print(error!)
                        callback(nil, error)
                    } else {
                        if json["status_code"] as! String == "100" {
                            self.generateAlert(message: json["status_description"] as! String, action: true, title: nil)
                        } else {
                            self.generateAlert(message: "Successfully Enrolled!", action: true, title: "Enrollment Process Concluded")
                        }
                        callback(json, nil)
                    }
                })
            } else {
                callback(nil, NSError(domain: "Please insert a valid number", code: 123, userInfo: [:]))
            }
        })
    }
    //second step of regular enrollment
    private func callMicroValidate(baaRequest: NSDictionary, onCompletion: @escaping ([String:Any], NSError?) -> Void){
        let route = baseURL + "ach/consumer/enrollment/baa"
        print("micro validating...")
        self.post(path_url: route, body: baaRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            onCompletion(json, error)
            print("successfully micro validated enrollment")
        })
    }
    //perform transaction
    public func performTransaction(enrollmentId: String?, amount: String?, onCompletion: @escaping (_ transactionId: String?, _ refundId: String?, _ error: NSError?)->Void){
        currentViewController = parentViewController
        if enrollmentId != nil && amount != nil {
            self.generateAlert(message: "Processing transaction...", action: false, title: "Payment Validation")
            let transactionRequest:NSDictionary = ["transaction_type": "authorize", "method": "ach", "amount": amount!, "currency_code": "USD", "ach": ["token": enrollmentId]]
            self.createPrimaryTransaction(transactionRequest: transactionRequest, onCompletion: {(json, error)->Void in
                self.dismissAlert()
                if error != nil {
                    self.generateAlert(message: "Transaction did not go through...", action: true, title: nil)
                    onCompletion(nil, nil, error)
                } else {
                    if json["gateway_resp_code"] as! String == "24" {
                        self.generateAlert(message: "Please microvalidate first...", action: true, title: "Transaction Failed")
                    } else {
                        self.refundProcess(transactionId: json["transaction_id"] as! String, transactionRequest: transactionRequest, callback: onCompletion)
                    }
                }
            })

        } else {
            //error processing
            if(enrollmentId == nil){
                self.generateAlert(message: "You need to enroll first...", action: true, title: nil)
            } else {
                self.generateAlert(message: "Enter an amount...", action: true, title: nil)
            }
        }
    }
    //refund
    private func refundProcess(transactionId: String, transactionRequest: NSDictionary, callback: @escaping(_ transactionId: String?, _ refundId: String?, _ error: NSError?)->Void){
        self.refundPrompt(transactionRequest: transactionRequest, onRefund: {()->Void in
            self.generateAlert(message: "Processing refund...", action: false, title: "Refund")
            self.createSecondaryTransaction(transactionId: transactionId, transactionRequest: transactionRequest, onCompletion: {(json, error)->Void in
                self.dismissAlert()
                if error != nil{
                    self.generateAlert(message: "Refund Failed", action: true, title: "Error")
                    callback(transactionId, nil, error)
                } else {
                    callback(transactionId, json["transaction_id"] as! String?, nil)
                    self.generateAlert(message: "Refund of USD\(transactionRequest["amount"]!) processed successfully!", action: true, title: "Refund")
                }
            })
        })
    }
    //payment
    private func createPrimaryTransaction(transactionRequest: NSDictionary, onCompletion: @escaping ([String: Any], NSError?) -> Void){
        let route = baseURL + "transactions"
        post(path_url: route, body: transactionRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            onCompletion(json, error)
        })
    }
    //refund
    private func createSecondaryTransaction(transactionId: String, transactionRequest: NSDictionary, onCompletion: @escaping ([String: Any], NSError?) -> Void){
        let route = baseURL + "transactions/"+transactionId
        post(path_url: route, body: transactionRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            onCompletion(json, error)
        })
    }
    //enroll with PWMB
    public func performEnrollmentWithPayWithMyBank(onSuccess: @escaping (String?, NSError?) -> Void){
        self.currentViewController = parentViewController
        self.generateAlert(message: "Connecting with PWMB...", action: false, title: "Pay With My Bank")
        establish(onCompletion: {(json, error)->Void in
            self.dismissAlert()
            if error != nil {
                onSuccess(nil, error)
                self.generateAlert(message: "An occured error while establishing request...", action: true, title: nil)
            } else {
                let establishData = self.populateEstablishData(json: json as NSDictionary)
                self.payWithMyBankPanel.establish(establishData, onReturn: {(payBankView, returnParameters) -> Void in
                    let validateRequest = self.populateValidationRequest(establishResponse: returnParameters as! [String:String] as NSDictionary)
                    self.validate(validateRequest: validateRequest as NSDictionary, callback: onSuccess)
                    self.parentViewController.dismiss(animated: true, completion: nil)
                }, onCancel: {(payBankView, returnParameters) -> Void in
                    self.parentViewController.dismiss(animated: true, completion: nil)
                })
                let bankController = UIViewController()
                bankController.view = self.payWithMyBankPanel
                self.parentViewController.present(bankController, animated: true, completion: nil)
            }
        })
    }
    //call Alert
    private func presentAlert(){
        DispatchQueue.main.async {
            self.currentViewController?.present(self.alertObj!, animated: true, completion: nil)
        }
    }
    //dismiss alert
    func dismissAlert(){
        DispatchQueue.main.async {
            self.alertObj?.dismiss(animated: true, completion: nil)
        }
    }
    //establish
    private func establish(onCompletion: @escaping ([String:Any], NSError?) -> Void){
        let route = baseURL + "ach/establish"
        let establishRequest:NSDictionary = ["callType":"pwmb.getAll", "returnUrl":"msg://return"]
        post(path_url: route, body: establishRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            if error != nil {
                onCompletion([:], error)
            } else {
                onCompletion(json, error)
            }
        })
    }
    //validate
    private func validate(validateRequest: NSDictionary, callback: @escaping (String?, NSError?) -> Void){
        let route = baseURL + "ach/validate"
        generateAlert(message: "Validation in process...", action: false, title: "Enrollment Validation")
        post(path_url: route, body: validateRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            self.dismissAlert()
            if error != nil {
                callback(nil, error)
                self.generateAlert(message: "An occured error while validating...", action: true, title: nil)
            } else {
                let enrollmentRequest = self.populateEnrollmentRequest(json: json as NSDictionary)
                self.enrollPayWithMyBank(enrollmentRequest: enrollmentRequest, callback: callback)
            }
        })
    }
    //api call to enroll with PWMB
    private func enrollPayWithMyBank(enrollmentRequest: NSDictionary, callback: @escaping (String?, NSError?) -> Void){
        let route = baseURL + "ach/consumer/enrollment/pwmb"
        generateAlert(message: "Processing enrollment request...", action: false, title: "Enrollment Request")
        post(path_url: route, body: enrollmentRequest as! [String : AnyObject], onCompletion: {(json: [String: Any], error: NSError?) in
            self.dismissAlert()
            if error != nil {
                callback(nil, error)
                self.generateAlert(message: "An occured error while enrolling...", action: true, title: nil)
            } else {
                self.generateAlert(message: "Successfully Enrolled!", action: true, title: "Enrollment Process Concluded")
                callback(json["token"] as? String, error)
            }
        })
    }
    private func post(path_url: String, body: [String:AnyObject], onCompletion: @escaping ([String:Any], NSError?) -> Void){
        var request = URLRequest(url: URL(string: path_url)!)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        request = createHMAC(request: request, payload: body as NSDictionary)
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error)->Void in
            
            guard error == nil else {
                // got an error in getting the data, need to handle it
                print(error!)
                onCompletion([:], error as NSError?)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            onCompletion(json as! [String : Any], error as NSError?)
            
        })
        task.resume()
    }
    //populate validation request
    private func populateValidationRequest(establishResponse:NSDictionary)->NSDictionary{
        let validateRequest:Dictionary = ["transactionId": establishResponse["transactionId"],
                                          "callType": "pwmb.getAll",
                                          "requestSignature": establishResponse["requestSignature"],
                                          "transactionType": establishResponse["transactionType"],
                                          "merchantReference": establishResponse["merchantReference"],
                                          "status": establishResponse["status"],
                                          "returnUrl": "msg://return",
                                          "panel": establishResponse["panel"],
                                          "payment.paymentType": establishResponse["payment.paymentType"],
                                          "payment.paymentProvider.type": establishResponse["payment.paymentProvider.type"],
                                          "payment.account.verified": establishResponse["payment.account.verified"]]
        return validateRequest as NSDictionary
    }
    //populate establish data
    private func populateEstablishData(json:NSDictionary) -> [String:String]{
        let establishData:[String:String] = ["accessId": json["accessId"] as! String,
                                             "requestSignature": json["requestSignature"] as! String,
                                             "merchantId" : json["merchantId"] as! String,
                                             "description": json["description"] as! String,
                                             "currency" : json["currency"] as! String,
                                             "amount" : json["amount"] as! String,
                                             "merchantReference" : json["merchantReference"] as! String,
                                             "paymentType" : json["paymentType"] as! String,
                                             "version" : "2",
                                             "env": "sandbox"]
        return establishData
    }
    private func populateEnrollmentRequest(json: NSDictionary) -> NSDictionary{
        let dict = json["TCKObj"] as! [String:String]
        let nameArray = dict["name"]!.components(separatedBy: " ")
        let enrollmentRequest:NSDictionary = ["transaction_id": dict["transactionId"]!,
                                              "first_name": nameArray[0],
                                              "last_name": nameArray[1],
                                              "billing_address": [
                                                "street": dict["address1"]!,
                                                "state_province": dict["state"]!,
                                                "city": dict["city"]!,
                                                "country": "0840",
                                                "email": dict["email"]!,
                                                "phone": [
                                                    "type": "MOBILE",
                                                    "number": dict["phone"]!
                                                    ],
                                                "zip_postal_code": dict["zip"]!
                                                ]
                                             ]
        return enrollmentRequest
    }
    //hmac used by post method
    private func createHMAC( request:URLRequest, payload:NSDictionary)->URLRequest{
        var mod_request = request
        let timestamp = crypto.getEpochTimeStamp()!
        let nonce = crypto.secureRandomNumber()!
        let hmac = crypto.generateHMACforpayload(payload as? [AnyHashable: Any] ?? [:], timeStamp: timestamp, nonce: nonce, apiKey: self.apiKey, merchantToken: self.token, apiSecret: self.apiSecret)!
        mod_request.setValue("application/json", forHTTPHeaderField: "Content-type")
        mod_request.setValue(hmac, forHTTPHeaderField: "Authorization")
        mod_request.setValue(self.apiKey, forHTTPHeaderField: "apikey")
        mod_request.setValue(self.token, forHTTPHeaderField: "token")
        return mod_request
    }
    //normal alert prompt for UI communication
    private func generateAlert(message: String, action: Bool, title: String?){
        let alertTitle = title ?? "Error"
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.alert)
        if action {
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                alert.dismiss(animated: true, completion: nil)
                if title != nil {
                    self.currentViewController?.dismiss(animated: true, completion: nil)
                }
            }
            alert.addAction(okAction)
        }
        self.alertObj = alert
        presentAlert()
    }
    //input alert with callback that allows to use authAnswer input
    private func callInputAlert(callback: @escaping (String) -> Void){
        let alert = UIAlertController(title: "BAA Request", message: "Enter AuthAnswer", preferredStyle: .alert)
        alert.addTextField { (textField) in
            //default ACH sandbox authAnswer
            textField.text = "7777"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if((textField?.hasText)!){
                callback((textField?.text)!)
            } else {
                callback("")
            }
        }))
        self.alertObj = alert
        presentAlert()
    }
    //refund alert with yes/no actions
    private func refundPrompt(transactionRequest: NSDictionary, onRefund: @escaping ()->Void){
        
        let alert = UIAlertController(title: "Refund", message: "Payment of USD\(transactionRequest["amount"]!) processed successfully! Would you like a refund?", preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
            onRefund()
        }
        alert.addAction(okAction)
        
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(noAction)
        
        self.alertObj = alert
        presentAlert()
    }

}
